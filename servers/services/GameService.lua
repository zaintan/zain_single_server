-------------------------------------------------------------
---! @file  GameService.lua
---! @brief 调试当前节点，获取运行信息
--------------------------------------------------------------

local skynet    = require "skynet"
require "skynet.manager"

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

local function _handlerCreateReq(source, uid, data)
    return handler:handlerCreateReq(uid, data)
end

local function _handlerJoinReq(source, uid, data)
    return handler:handlerJoinReq(source, uid, data)
end

local ComandFuncMap = {
    [const.MsgId.CreateRoomReq]      = _handlerCreateReq;
    [const.MsgId.JoinRoomReq]        = _handlerJoinReq;
}

function CMD.on_req(source, uid, msg_id, data)
    Log.d(LOGTAG,"on_req uid = %d, msg_id=%d", uid, msg_id)
    
    local func = ComandFuncMap[msg_id]
    if func then 
        return func(source, uid, data)
    end 
    --------------
    skynet.ignoreret()
    handler:handlerClientReq(uid,msg_id,data)
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
            local ret = f(source, ...)
            if ret then
                skynet.ret(skynet.pack(ret))
            end
        else
            Log.e(LOGTAG,"unknown command:%s", cmd)
        end
    end)
    
    handler:init()
end)