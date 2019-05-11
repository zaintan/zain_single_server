-------------------------------------------------------------
---! @file  GameService.lua
---! @brief 调试当前节点，获取运行信息
--------------------------------------------------------------

local skynet    = require "skynet"
require "skynet.manager"

local queue  = require "skynet.queue"
local cs  = queue()


local handler = require("game_logic.GameServerLogic")

local LOGTAG = "GS"
-------------------------------------------------------------------
local CMD = {}

function CMD.offline(source, uid)
    return handler:offline(uid)
end

function CMD.queryTableId(source, uid)
    return handler:queryTableId(uid)
end 

function CMD.releaseTable(source,tid,create_uid,uids)
    return handler:releaseTable(source,tid,create_uid,uids)
end 

function CMD.leaveTable(source, uid, tableId )
    return handler:releaseTable(uid, tableId)
end

local function _handlerCreateReq(source, uid, data)
    return handler:handlerCreateReq(uid, data)
end

local function _handlerJoinReq(source, uid, data)
    return handler:handlerJoinReq(source, uid, data)
end

local ComandFuncMap = {
    [msg.NameToId.CreateRoomRequest]      = _handlerCreateReq;
    [msg.NameToId.JoinRoomRequest]        = _handlerJoinReq;
}

function CMD.on_req(source, uid, msg_id, data)
    Log.d(LOGTAG,"on_req uid = %d, msg_id=%d", uid, msg_id)
    
    local func = ComandFuncMap[msg_id]
    if func then 
        return cs(function()
            return func(source, uid, data)
        end)
        --return func(source, uid, data)
    end 
    --------------
    --skynet.ignoreret()
    handler:handlerClientReq(source,uid,msg_id,data)
    return 
end

---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
    skynet.register(".GameService")
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        Log.d(LOGTAG,"recv cmd:",cmd)
        if f then
            local ret,data = f(source, ...)
            if ret then
                skynet.ret(skynet.pack(ret,data))
            else
                skynet.ret(skynet.pack(false))
            end
        else
            Log.e(LOGTAG,"unknown command:%s", cmd)
        end
    end)
    
    handler:init()

    skynet.info_func(function ()
        return handler:info()
    end)
end)