---! 依赖库
local skynet    = require "skynet"
local socket    = require "skynet.socket"
---! 帮助库
local packetHelper  = (require "PacketHelper").create("protos/common.pb")
local LOGTAG = "Agent"

local ClusterHelper = require "ClusterHelper"

local class = {mt = {}}
class.mt.__index = class

--[[ info = {
    watchdog;
    gate;
    client_fd;
    address;
    agent;
}]]--
function class.create(info)
	local self = {}
	setmetatable(self, class.mt)

	for k,v in pairs(info or {}) do
        self[k] = v
    end

    self.agentSign   = os.time()
    self:_active()

    Log.i(LOGTAG,"CMD start called on fd %d",self.client_fd)
    skynet.call(self.gate, "lua", "forward", self.client_fd)

    skynet.fork(function ()
        while true do 
            -- 1 seconds 检查一次
            -- 120 seconds 都没有收到过包  就认为掉线直接踢掉
            if self:_timeoutCheck(120*100) then 
                self:_kickMe()
                return 
            end 
            skynet.sleep(1 * 100)
        end 
    end)

    return self
end

function class:_timeoutCheck(timeout )
    if skynet.time() - self.last_update >= timeout then 
        return true
    end 
end

function class:_active()
	self.last_update = skynet.time()
end

function class:_kickMe()
    Log.d(LOGTAG,"heartbeat timeout! kick me!")
    pcall(skynet.send, self.watchdog, "lua", "closeAgent", self.client_fd)
end

function class:quit()
    Log.i(LOGTAG,"玩家uid=%s下线!",tostring(self.FUserID))

    local cur_index = skynet.getenv("ServerIndex")--cfgHelper.getCluserName()
    local selfAddr  = skynet.self()
    if self.FUserID ~= nil then 
        --通知登录服  对应服务器清空的时候 要对地址做校验
        ClusterHelper.callIndex(skynet.getenv("server_login"), ".LoginService", "logout",self.FUserID, cur_index, selfAddr)
        
        --通知游戏服
        if self.gameSvr and self.tableAddr then 
            ClusterHelper.callIndex(self.gameSvr, self.tableAddr, "logout",cur_index, selfAddr,self.FUserID)       
        end 
    end 

    if self.client_fd then 
        socket.close(self.client_fd)
    end 
    skynet.exit()    
end

function class:_sendPacket( packet )
    local data = string.pack(">s2", packet)
    socket.write(self.client_fd, data)
end

function class:sendMsg(msg_id, data)
    if msg_id ~= msg.NameToId.HeartResponse then
        Log.d(LOGTAG,"sendClientMsg msg_id=%d",msg_id)
        Log.dump(LOGTAG,data)
    end 

    local protoName = msg.IdToName[msg_id] 
    local body      = packetHelper:encodeMsg("Base."..protoName, data)
    local packet    = packetHelper:makeProtoData(msg_id , body)
    self:_sendPacket(packet)
    return true
end

function class:_handlerHeartReq()--(data)
    self:sendMsg(msg.NameToId.HeartResponse,{})
end

function class:_handlerLoginReq(data)

    local ok,ret = ClusterHelper.callIndex(skynet.getenv("server_login"), 
                                                         ".LoginService", 
                                                                 "login", 
                                                                    data, 
                                            skynet.getenv("ServerIndex"), 
                                                            skynet.self())
    if not ok then 
        Log.e(LOGTAG,"链接登录服失败!")
        self:sendMsg(msg.NameToId.LoginResponse, {status = -1002;})
        self.FUserID  = nil
        self.userInfo = nil
        return
    end

    if not ret or type(ret) ~= "table" then 
        Log.e(LOGTAG,"登录服返回参数失败!")
        self:sendMsg(msg.NameToId.LoginResponse, {status = -1003;})
        self.FUserID  = nil
        self.userInfo = nil
        return
    end 

    if ret.status >= 0 then--login success 
        self.FUserID  = ret.user_info.user_id
        self.userInfo = ret.user_info 
        ----------------------------------------------    
        local callSucc,tid = ClusterHelper.callIndex(skynet.getenv("server_alloc"), ".AllocService", "queryTableId", self.FUserID)
        if not callSucc then 
            Log.e(LOGTAG,"链接分配服失败!无法查询该玩家是否在房间!")
            self:sendMsg(msg.NameToId.LoginResponse, {status = -1005;})
            return
        end

        if tid and tid ~= -1 then 
            ret.room_id       = tid
            Log.d(LOGTAG,"查询到该玩家已经进入房间:%d",tid)   
        end    
    else 
        self.FUserID  = nil
        self.userInfo = nil     
    end 
    self:sendMsg(msg.NameToId.LoginResponse, ret)
end


function class:_handlerCreateReq(data)
    local ok,ret = ClusterHelper.callIndex(skynet.getenv("server_alloc") , ".AllocService", "create",data,self.userInfo)
    if not ok then 
        Log.e(LOGTAG,"链接分配服失败!reason:%s",tostring(ret))
        self:sendMsg(msg.NameToId.CreateRoomResponse, {status = -1202;})
        return
    end
    self:sendMsg(msg.NameToId.CreateRoomResponse, ret)
end


function class:_handlerJoinReq(data)
    
    local ok,ret = ClusterHelper.callIndex(skynet.getenv("server_alloc"), 
                                                       ".AllocService",
                                                              "join",
                                                                data, 
                                       skynet.getenv("ServerIndex"), 
                                                       skynet.self(),
                                                       self.userInfo)
    if not ok then 
        Log.e(LOGTAG,"链接分配服失败!reason:%s",tostring(ret))
        self:sendMsg(msg.NameToId.JoinRoomResponse, {status = -1204;})
        return
    end

    Log.i(LOGTAG,"AllocServer ret:")
    Log.dump(LOGTAG,ret)
    --成功转发到分配服后  由分配服回消息
    if ret and ret.gameSvr and ret.tableAddr then 
        self.gameSvr   = ret.gameSvr
        self.tableAddr = ret.tableAddr
    end 
end

function class:_handlerRoomReq(msg_id, data)
    if not self.gameSvr or not self.tableAddr then 
        Log.e(LOGTAG,"无逻辑服地址!无法转发到逻辑服!")
        self:sendMsg(msg_id + msg.ResponseBase, {status = -1401;})
        return 
    end 

    local ok = ClusterHelper.callIndex(self.gameSvr, self.tableAddr, "on_req", self.FUserID, msg_id, data)
    if not ok then 
        Log.e(LOGTAG,"uid:%s转发msgid=%d到逻辑服失败!toindex=%d, toAddr=%d",tostring(self.FUserID), msg_id,self.gameSvr, self.tableAddr)
        self:sendMsg(msg_id + msg.ResponseBase, {status = -1402;})

        self.gameSvr   = nil
        self.tableAddr = nil
        return 
    end 
    --成功转发到逻辑服后  由逻辑服回消息
end

local ComandFuncMap = {
    [msg.NameToId.HeartRequest]      = class._handlerHeartReq;
    [msg.NameToId.LoginRequest]      = class._handlerLoginReq;
    [msg.NameToId.CreateRoomRequest] = class._handlerCreateReq;
    [msg.NameToId.JoinRoomRequest]   = class._handlerJoinReq;
}

function class:command_handler(cmsg, recvTime)
    --Log.d(LOGTAG,"command_handler cmsg len:%d accessTime:%s",#cmsg,tostring(skynet.time()))
    self:_active()
    --解析包头 转发处理消息 做对应转发
    local args    = packetHelper:decodeMsg("Base.ProtoInfo",cmsg)
    local msgName = msg.IdToName[args.msg_id]
    if not msgName then 
        Log.e(LOGTAG,"recv unknown msg_id:%d",args.msg_id)
        return 
    end 

    local data,err = packetHelper:decodeMsg("Base."..msgName, args.msg_body)
    if not data or err ~= nil then 
        Log.e(LOGTAG,"proto decode error: msgid=%d name=%s !", args.msg_id, msgName )
        return
    end 

    if args.msg_id ~= msg.NameToId.HeartRequest then
        Log.dump(LOGTAG,data)

        if args.msg_id ~= msg.NameToId.LoginRequest and not self:_hadLogin() then 
            Log.e(LOGTAG,"非法用户请求msgid=%d,请先登录!",args.msg_id)
            self:sendMsg(args.msg_id + msg.ResponseBase, {status = -999;})
            return 
        end  
    end 

    local f = ComandFuncMap[args.msg_id]
    if f then 
        f(self, data)
    else--房间请求
        self:_handlerRoomReq(args.msg_id, data)
    end 
end

function class:_hadLogin()
    return self.FUserID ~= nil
end

return class
