-------------------------------------------------------------
---! @file  NodeStat.lua
---! @brief 调试当前节点，获取运行信息
--------------------------------------------------------------

local skynet    = require "skynet"
local strHelper = require "StringHelper"

local function info()
	local watchdog = skynet.uniqueservice("WatchDog")

	local stat = skynet.call(watchdog, "lua", "getStat")
	local arr  = {nodeInfo.appName}
	table.insert(arr, string.format("Tcp: %d", stat.tcp))
	table.insert(arr, string.format("总人数: %d", stat.sum))	
    return strHelper.join(arr, "\t")
end

skynet.start(function()
    skynet.info_func(info)
end)