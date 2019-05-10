-------------------------------------------------------------
---! @file
---! @brief watchdog, 监控游戏连接
--------------------------------------------------------------
---! 系统依赖
local skynet       = require "skynet"
---! 辅助依赖
local NumSet       = require "NumSet"


---! gateserver's gate service
local gate        = nil
---! all agents
local tcpAgents   = NumSet.create()

---! @brief close agent on socket fd
local function close_agent( fd )
    local info = tcpAgents:getObject(fd)
    if info then 
        tcpAgents:removeObject(fd)
        --通知agent断开
        pcall(skynet.send, info.agent, "lua", "disconnect")
    end 
end

---!  socket handlings, SOCKET.error, SOCKET.warning, SOCKET.data
---!         may not called after we transfer it to agent
local SOCKET = {}

---! @brief new client from gate, start an agent and trasfer fd to agent
function SOCKET.open( fd, addr )
    local info = tcpAgents:getObject(fd)
    if info then 
        Log.w("WatchDog","repeat fd:%d, close old",fd)
        close_agent(fd)--重复fd
    end 

    Log.i("WatchDog","tcp agent start fd:%d, addr:%s",fd, addr)
    local agent = skynet.newservice("TcpAgent")

    local obj = {}
    obj.watchdog   = skynet.self()
    obj.gate       = gate
    obj.client_fd  = fd
    obj.address    = string.gsub(addr, ":%d+", "")
    obj.agent      = agent
    tcpAgents:addObject(obj, fd)

    skynet.call(agent, "lua", "start", obj)
    return 0
end

---! @brief close fd, is this called after we transfer it to agent ?
function SOCKET.close( fd )
    Log.i("WatchDog","socket close:%d", fd)
    --0.01s * 10 = 0.1s
    skynet.timeout(10, function ()
        close_agent(fd)
    end)

    return ""
end

---! @brief error on socket, is this called after we transfer it to agent ?
function SOCKET.error( fd, msg)
    Log.e("WatchDog","socket error fd:%d, err:%s", fd, msg or "")

    skynet.timeout(10, function ()
        close_agent(fd)
    end)
end

---! @brief warnings on socket, is this called after we transfer it to agent ?
function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    Log.w("WatchDog","socket warning fd:%d, size:%d", fd, size)
end

---! @brief packets on socket, is this called after we transfer it to agent ?
function SOCKET.data(fd, msg)
end

---! skynet service handlings
local CMD = {}
---! @brief this function may not be called after we transfer fd to agent
function CMD.closeAgent(fd)
    skynet.timeout(10, function()
        close_agent(fd)
    end)
    return 0
end

function CMD.getStat ()
    local stat = {}
    stat.tcp = tcpAgents:getCount()
    stat.sum = stat.tcp
    return stat
end


---! 注册LoginWatchDog的处理函数，一种是skynet服务，一种是socket
local function registerDispatch()
    skynet.dispatch("lua", function ( session, source, cmd, subcmd, ... )
        if cmd == "socket" then 
            local f = SOCKET[subcmd]
            if f then 
                f(...)
            else
                Log.e("WatchDog","unknown sub command:%d for cmd:%d ",subcmd,cmd)
            end 
            --socket api don't need return
        else 
            local f = CMD[cmd]
            if f then 
                local ret = f(subcmd, ...)
                if ret then 
                    skynet.ret(skynet.pack(ret))
                end 
            else 
                Log.e("WatchDog","unknown command:%s",cmd)
            end
        end
    end)
end

---! 开启 watchdog 功能, tcp/web
local function startWatch ()
    
    local packetHelper = require "PacketHelper"
    local cfg          = packetHelper.load_config("./config/nodes.cfg")
    local serverKind   = skynet.getenv("ServerKind")
    local tcpPort      = cfg[serverKind].tcpPort

    ---! 启动gate
    local publicAddr = "0.0.0.0"
    gate = skynet.newservice("gate")
    skynet.call(gate, "lua", "open", {
        address   = publicAddr,
        port      = tcpPort,  ---! 监听端口
        maxclient = 2048,            ---! 最多允许 2048 个外部连接同时建立  注意本数值，当客户端很多时，避免阻塞
        nodelay   = true,            ---! 给外部连接设置  TCP_NODELAY 属性
    })

end

---! 启动函数
skynet.start(function()
    registerDispatch()
    startWatch()
    --skynet.fork(loopReport)
end)
