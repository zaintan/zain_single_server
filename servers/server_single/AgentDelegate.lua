---! 依赖库
local skynet    = require "skynet"
local socket    = require "skynet.socket"
---! 帮助库
local packetHelper  = (require "PacketHelper").create("protos/ZainCommon.pb")
local ProtoHelper   = (require "ProtoHelper").init()

local LOGTAG = "Agent"

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
            -- 2 seconds 检查一次
            -- 10 seconds 都没有收到过包  就认为掉线直接踢掉
            if self:_timeoutCheck(5*100) then 
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
    Log.d(LOGTAG,"玩家下线!")
    --下线通知 中心服 和 游戏服
    pcall(skynet.call, ".LoginService","lua","logout",  self.FUserID)
    pcall(skynet.call, ".GameService", "lua","offline", self.FUserID)

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
    if msg_id ~= const.MsgId.HeartRsp then
        Log.d(LOGTAG,"sendClientMsg msg_id=%d",msg_id)
        Log.dump(LOGTAG,data)
    end 

    local protoName = ProtoHelper.IdToName[msg_id] 
    local body      = packetHelper:encodeMsg("Zain."..protoName, data)
    local packet    = packetHelper:makeProtoData(0, 0,msg_id , body)
    self:_sendPacket(packet)
    return true
end

function class:_handlerHeartReq(data)
    self:sendMsg(const.MsgId.HeartRsp,{})
end

function class:_handlerLoginReq(data)
    local ok,data = pcall(skynet.call, ".LoginService", "lua", "on_login", data)
    if not ok then 
        Log.e(LOGTAG,"call LoginService failed!")
    else
        if data.user_info then 
            self.FUserID = data.user_info.user_id
        end 
        self:sendMsg(const.MsgId.LoginRsp, data)
        ----------------------------------------------
        local ok,tableId = pcall(skynet.call, ".GameService", "lua", "queryTableId", self.FUserID)
        Log.d(LOGTAG,"queryTableId return status=%s,tableId=%s",tostring(ok),tostring(tableId))
        if ok and tableId and tableId ~= -1 then 
            self:_handlerRoomReq(const.MsgId.JoinRoomReq,{room_id = tableId;});
        end 
    end 
end

function class:_handlerRoomReq(msg_id, data)
    Log.e(LOGTAG,"_handlerRoomReq msg_id=%d", msg_id)
    local status,retid,retData = pcall(skynet.call, ".GameService","lua","on_req", self.FUserID,msg_id, data)
    Log.e(LOGTAG,"status=%s,retid=%s,retData=%s", tostring(status),tostring(retid),tostring(retData))
    if status then 
        if retid and retData then 
            self:sendMsg(retid, retData)
        end 
    end 
end

local ComandFuncMap = {
    [const.MsgId.HeartReq]      = class._handlerHeartReq;
    [const.MsgId.LoginReq]      = class._handlerLoginReq;
}

function class:command_handler(msg, recvTime)
    Log.d(LOGTAG,"command_handler msg len:%d accessTime:%s",#msg,tostring(skynet.time()))
    self:_active()
    --解析包头 转发处理消息 做对应转发
    local args    = packetHelper:decodeMsg("Zain.ProtoInfo",msg)
    local msgName = ProtoHelper.IdToName[args.msg_id]
    if not msgName then 
        Log.e(LOGTAG,"unknown msg_id: ",args.msg_id)
        return 
    end 

    local data,err = packetHelper:decodeMsg("Zain."..msgName, args.msg_body)
    if not data or err ~= nil then 
        Log.e(LOGTAG,"parse msg err: ",args.msg_id, msgName )
        return
    end 

    Log.dump(LOGTAG,data)

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