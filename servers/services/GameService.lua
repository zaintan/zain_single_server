-------------------------------------------------------------
---! @file  GameService.lua
---! @brief 调试当前节点，获取运行信息
--------------------------------------------------------------

local skynet    = require "skynet"
require "skynet.manager"
local CMD = {}

function CMD.offline(source)
    return true
end

function CMD.on_req(source, msg_id)
    skynet.ignoreret()
    
end

---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
    skynet.register(".GameService")
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        Log.d("GameService","recv cmd:",cmd)
        if f then
            local ret = f(source, ...)
            if ret then
                skynet.ret(skynet.pack(ret))
            end
        else
            Log.e(LOGTAG,"unknown command:%s", cmd)
        end
    end)
    
end)