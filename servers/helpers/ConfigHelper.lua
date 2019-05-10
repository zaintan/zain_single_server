---------------------------------------------------
---! @file
---! @brief 配置解析
---------------------------------------------------
local M = {}

--load (chunk [, chunkname [, mode [, env]]])
---! @brief 加载配置文件, 文件名为从 servers目录计算的路径
local function _load_file(filename )
    local f = assert(io.open(filename))
    local source = f:read "*a"
    f:close()
    local tmp = {}
    assert(load(source, "@"..filename, "t", tmp))()
    return tmp
end

local function _getCluserDescName(node_name, server_kind, server_index)
	return node_name.."_"..server_kind.."_"..server_index
end

local function _getCluserName(server_index)
	return "server_"..server_index
end
M.getCluserName = _getCluserName

local function _getCluserAddr(ip, port)
	return ip..":"..port
end

local function _readServer(cfg , server_index)
	
	local server  = nil
	local servers = cfg.servers
	for i,v in ipairs(servers) do
		if v.index == server_index then 
			server = v
		end 
	end
	assert(server ~= nil)
 
	local node = cfg.MySite[server.node]
	local ret     = {}
	ret.index     = server.index
	ret.kind      = server.kind
	ret.nodePort  = server.nodePort
	ret.debugPort = server.debugPort
	ret.tcpPort   = server.tcpPort
	ret.clusterName = _getCluserName(server.index)		
	ret.publicAddr  = node[2]
	ret.privateAddr = node[1]
	return ret
end

local function _readClusterList(cfg)
	local server_list  = {}
	local cluser_list  = {}
	
	local servers = cfg.servers
	for i,v in ipairs(servers) do
		if server_list[v.kind] == nil then 
			server_list[v.kind] = {}
		end 
		local node = cfg.MySite[server.node]
		local cluser_name = _getCluserName(v.index)
		local cluser_addr = _getCluserAddr(node[1], v.nodePort)
		table.insert( server_list[v.kind], v.index)
		cluser_list[cluser_name] = cluser_addr
	end
	return cluser_list, server_list
end


local function loadCluser(server_index, filename)
	local cfg = _load_file(filename or "./config/nodes.cfg")
	assert(cfg ~= nil)

	local ret = {}
	local nodeInfo   = _readServer(cfg, server_index)
	local cluser_list, server_list  = _readClusterList(cfg)
	ret.nodeInfo   = nodeInfo
	ret.cluserList = cluser_list
	ret.serverList = server_list

	if nodeInfo.kind == "server_alloc" then 
		local cfg = _load_file("./config/alloc.cfg")
		ret.games = cfg.games
	end 
	return ret
end

M.loadCluser = loadCluser



local function loadDB(server_index, filename)
	local cfg = _load_file(filename or "./config/db.cfg")
	assert(cfg ~= nil)
	return cfg
end

M.loadDB = loadDB

return M

--[[
loadCluser ret = {
	serverList = {
		["server_agent"]={
			[1]=101,
			[2]=102
		},
		["server_alloc"]={
			[1]=301
		},
		["server_game"]={
			[1]=401
		},
	},
	["clusterList"]={
		["server_101"]     = "127.0.0.1:8051",
		["server_102"]     = "127.0.0.1:8250",
		["server_301"]     = "127.0.0.1:8050",
		["server_401"]      = "127.0.0.1:8550",

	},
	["nodeInfo"]={
		["debugPort"]	= 8000,
		["serverKind"]  = "server_agent",
		["nodeName"]    = "node1",
		["tcpPort"]     = 8100,
		["privateAddr"] = "127.0.0.1",
		["nodePort"]    = 8050,
		["publicAddr"]  = "111.230.152.22",
		["serverIndex"] = 0,
		["clusterName"] = "server_101"
	},
};
]]--
