------------------------------------------------------
---! @file
---! @brief server_agent 的启动文件
---! @unique
------------------------------------------------------

---! 依赖库
local skynet       = require "skynet"
---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

    ---! 启动NodeInfo
    local nodeInfo = skynet.uniqueservice("NodeInfo")
    skynet.call(nodeInfo, "lua", "initNode")
    
    ---! 启动debug_console服务
    local debugPort = skynet.call(nodeInfo, "lua", "getConfig", "nodeInfo", "debugPort")
    assert(type(debugPort) == "number" and debugPort > 0)
    skynet.newservice("debug_console", debugPort)
    
    ---! 启动 info :d 节点状态信息 服务
    skynet.uniqueservice("NodeState")     
    
    ---! 启动AgentWatch
    skynet.uniqueservice("WatchDog")
    
    ---! 启动好了，没事做就退出
    skynet.exit()
end)