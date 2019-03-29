------------------------------------------------------
---! @file
---! @brief server_agent 的启动文件
------------------------------------------------------

---! 依赖库
local skynet       = require "skynet"


---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

    local packetHelper = require "PacketHelper"
    local cfg          = packetHelper.load_config("./config/nodes.cfg")
    local serverKind   = skynet.getenv("ServerKind")
    local debugPort    = cfg[serverKind].debugPort

    ---! 启动debug_console服务
    assert(debugPort > 0)
    Log.i("Main","debug port is:%d", debugPort)
    --print("debug port is", port)
    skynet.newservice("debug_console", debugPort)
    ---! 启动
    skynet.uniqueservice("NodeStat")
    ---! 启动AgentWatch
    skynet.uniqueservice("WatchDog")
    ---! 启动Login
    skynet.newservice("LoginService")
    ---! 启动Game
    skynet.newservice("GameService")
    ---! 启动好了，没事做就退出
    skynet.exit()
end)