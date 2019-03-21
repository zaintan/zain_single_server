--------------------------------------------------------------
---! @file
---! @brief tcp socket的客户连接
--------------------------------------------------------------

---! 依赖库
local skynet        = require "skynet"
local queue         = require "skynet.queue"

local agentDelegate = require "AgentDelegate"

---!
local agent     = nil

local CMD       = {}
---! 顺序序列
local critical  = nil

---! @brief start service
function CMD.start( info )
    if not agent then 
        agent = agentDelegate.create(info)
    else
        Log.e("Agent","can not repeat start agent!")
    end 
    return 0
end

---! @brief 通知agent主动结束
function CMD.disconnect()
    agent:quit()
end

function CMD.sendMsg(...)
    return agent:sendMsg(...)
end

---! handle socket data
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return skynet.tostring(msg,sz)
	end,
	dispatch = function (session, address, text)
        skynet.ignoreret()
        
        local recvTime = skynet.time()
        Log.i("TcpAgent","recv client msg len:%d recvTime:%s",#text,tostring(recvTime))

        local worker = function ()
            agent:command_handler(text,recvTime)
        end

        xpcall( function()
            critical(worker)
        end,
        function(err)
            skynet.error(err)
            skynet.error(debug.traceback())
        end)
	end
}


skynet.start(function ()
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = CMD[cmd]
        if f then
            local ret = f(...)
            if ret then
                skynet.ret(skynet.pack(ret))
            end
        else
            Log.e("unknown command :%d", cmd)
        end
    end)	

    critical            = queue()
end)