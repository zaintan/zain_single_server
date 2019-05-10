-------------------------------------------------------------
---! @file  GameService.lua
---! @brief 
--------------------------------------------------------------
local skynet    = require "skynet"
require "skynet.manager"

local queue         = require "skynet.queue"
local cs            = queue()

local LOGTAG  = "GameService"

local CMD = {}
--创建房间
function CMD.create(tid,userInfo,data)--
    return cs(function()
        local tableSvr = skynet.newservice("TableService")
        local ok,ret = pcall(skynet.call, tableSvr, "lua", "init", tid, userInfo, data)
        if ok and ret then 
            return {tableAddr = tableSvr;}
        else 
            skynet.kill(tableSvr)
            return {err = tostring(ret);}
        end
    end)
end
-------------------------------------------------------------------
---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
    skynet.register(".GameService")
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function (session, source, cmd, ...)
        local f = CMD[cmd]
        if not f then 
            Log.e(LOGTAG,"unknown command:%s", cmd)
            return 
        end
        skynet.ret(skynet.pack(f(...)))
    end)
end)