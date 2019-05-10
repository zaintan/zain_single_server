-------------------------------------------------------------
---! @file  NodeInfo.lua
---! @brief 调试当前节点，获取运行信息
--------------------------------------------------------------
local skynet    = require "skynet"
require "skynet.manager"

local cluster   = require "skynet.cluster"

local cfgHelper = require "ConfigHelper"
local tblHelper = require "TableHelper"

local LOGTAG = "NodeInfo"

local Config = {}

local function info()
	return tblHelper.encode(Config) or ""
end 

--------------------------------------------------------------
local CMD = {}

function CMD.reloadCluster()
	local ServerIndex = skynet.getenv("ServerIndex")
    Config = cfgHelper.loadCluser(ServerIndex) or {}
    ----
    Log.i(LOGTAG,"reload config:")
    Log.dump(LOGTAG,Config)    
    ---! 集群处理
    local list = Config.clusterList or {}
    list["__nowaiting"] = true
    cluster.reload(list)	
	return true
end

function CMD.initNode()
	local ServerIndex = skynet.getenv("ServerIndex")
    Config = cfgHelper.loadCluser(ServerIndex) or {}
    --skynet.getenv("ServerIndex")  cfgHelper.getCluserName()
    assert(Config.server_alloc and #Config.server_alloc == 1)
    skynet.setenv("server_alloc",Config.server_alloc[1])
    
    assert(Config.server_login and #Config.server_login == 1)
    skynet.setenv("server_login",Config.server_login[1])
    ----
    Log.i(LOGTAG,"init config:")
    Log.dump(LOGTAG,Config)
    ---! 集群处理
    local list = Config.clusterList or {}
    list["__nowaiting"] = true
    cluster.reload(list)
    cluster.open(Config.nodeInfo.clusterName)
	return true
end

function CMD.getConfig(...)
	local args = table.pack(...)
	
	local ret  = Config or {}
	for _,key in ipairs(args) do
		if ret[key] then 
			ret = ret[key]
		else 
			return ""
		end 
	end
	ret = ret or ""
	return ret
end

--------------------------------------------------------------

local function start()
	skynet.register(".NodeInfo")
	
	skynet.dispatch("lua", function ( _,_,cmd, ...)
		local f = CMD[cmd]
		if f then 
			local ret = f(...)
			if ret then 
				skynet.ret(skynet.pack(ret))
			end 
		else
			Log.e("LOGTAG","unknown cmd :", cmd)
		end 
	end)
	skynet.info_func(info)	
end

skynet.start(start)