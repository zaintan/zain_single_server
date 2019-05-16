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
		if tonumber(v.index) == tonumber(server_index) then 
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
		local node = cfg.MySite[v.node]
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
    cluserList = {
        server_101 = "127.0.0.1:9051",
        server_201 = "127.0.0.1:9053",
        server_402 = "127.0.0.1:9056",
        server_301 = "127.0.0.1:9054",
        server_401 = "127.0.0.1:9055",
        server_102 = "127.0.0.1:9052",
    }
    nodeInfo = {
        debugPort = 9001,
        tcpPort = 8100,
        index = 101,
        publicAddr = "111.230.152.22",
        nodePort = 9051,
        kind = "server_agent",
        clusterName = "server_101",
        privateAddr = "127.0.0.1",
    }
    serverList = {
        server_game = {
            1 = 401,
            2 = 402,
        }
        server_agent = {
            1 = 101,
            2 = 102,
        }
        server_alloc = {
            1 = 301,
        }
        server_login = {
            1 = 201,
        }
    }
}

]]--
