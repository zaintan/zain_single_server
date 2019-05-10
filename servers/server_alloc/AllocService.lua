-------------------------------------------------------------
---! @file  AllocService.lua
---! @brief 
--------------------------------------------------------------

local skynet    = require "skynet"
require "skynet.manager"

local handler = require "AllocLogic"
local LOGTAG  = "AllocService"
-------------------------------------------------------------------
---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
    skynet.register(".AllocService")
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function (session, source, cmd, ...)
        local f = handler[cmd]
        if not f then 
            Log.e(LOGTAG,"unknown command:%s", cmd)
            return 
        end
        skynet.ret(skynet.pack(f(handler,...)))
    end)
    ---! 初始化
    handler:init()
end)