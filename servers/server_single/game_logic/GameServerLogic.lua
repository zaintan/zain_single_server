------------------------------------------------------
---! @file
---! @brief GameServerLogic, 管理GameServer 创建桌子 加入桌子 透传房间消息
------------------------------------------------------
local skynet    = require "skynet"
require "skynet.manager"

local GameServerLogic = {}

local LOGTAG = "GSLogic"
---! 辅助依赖
local NumSet       = require "NumSet"
local strHelper    = require "StringHelper"
--local tblHelper    = require "TableHelper"

local GameUserInfo = require "game_logic.data.GameUserInfo"

function GameServerLogic:info()

	local tableInfo  = {}
	self.m_tables:forEach(function (obj, key)
		-- k = table_id; v = tableAddr;
		tableInfo[key] = { addr = obj; users = {}; }
	end)

	self.m_users:forEach(function (user,  user_id)
		local tid = user:getTableId() or 0
		local tbl = tableInfo[tid]
		if tbl then 
			table.insert(tbl.users, user_id)
		end 
	end)

	local arr  = {}
	table.insert(arr, string.format("总桌数: %d", self.m_tables:getCount()))	
	for table_id,info in pairs(tableInfo) do
		table.insert(arr, string.format("桌子id: %d,桌子地址:%x,userids:%s,%s,%s,%s",
			table_id,
			info.addr,
			tostring(info.users[1]),
			tostring(info.users[2]),
			tostring(info.users[3]),
			tostring(info.users[4]) ))
	end
    return strHelper.join(arr, "\n")
end

function GameServerLogic:queryTableId(uid)
	local user = self.m_users:getObject(uid)
	if user then 
		local table_id  = user:getTableId()
		if table_id then 
			return table_id
		end 
	end	
	return -1
end

function GameServerLogic:offline(uid)
	return true
end

function GameServerLogic:init()
	---! all tables:  k = table_id; v = table;
	self.m_tables = NumSet.create()
	---! all users:  k = user_id; v = table_id;
	self.m_users  = NumSet.create()

	local TableIdPool = require("game_logic.TableIdPool")
	self.m_idPool = new(TableIdPool)
	self.m_idPool:init()
end

local function _onMsgFaild(id, err_tip)
	return id,{status = -1;status_tip = err_tip;}
end

function GameServerLogic:handlerCreateReq(uid, data)
	Log.d(LOGTAG,"GameServerLogic:handlerCreateReq")
	
	local user = self.m_users:getObject(uid)
	if user and not user:canCreateTable() then 
		return _onMsgFaild(msg.NameToId.CreateRoomResponse,"开房数量已达上限!")
	end	  

	local table_id = self.m_idPool:allocId()
	--没使用 要记得回收房间号
	if not table_id then 
		return _onMsgFaild(msg.NameToId.CreateRoomResponse,"分配房间号失败!")
	end 

	local tableSvr = skynet.newservice("GameTableService")
	if pcall(skynet.call, tableSvr, "lua", "init", skynet.self(), table_id, uid, data) then 
		if not user then 
			user = new(GameUserInfo)
			user:init(uid)
			self.m_users:addObject(user, uid)
		end 
		user:addCreatedTable(table_id)
		self.m_tables:addObject(tableSvr, table_id)
		return msg.NameToId.CreateRoomResponse,{status = 1;room_id = table_id;}
	else 
		skynet.kill(tableSvr)
		self.m_idPool:recoverId(table_id)
		return _onMsgFaild(msg.NameToId.CreateRoomResponse,"房间初始化失败!")
	end 
end

function GameServerLogic:handlerJoinReq(agent, uid, data)
	--判断房间号存不存在
	local tableAddr = self.m_tables:getObject(data.room_id)
	if not tableAddr then 
		return _onMsgFaild(msg.NameToId.JoinRoomResponse,"房间号不存在!")
	end 

	--判断用户是否已经加入过房间了  
	local user = self.m_users:getObject(uid)
	--Log.d(LOGTAG,"handlerJoinReq uid=%d ",uid)
	if user and not user:canJoinTable() then 
		--已经在房间里面了 返回重连消息
		local table_id = user:getTableId()
		local tableAddr = self.m_tables:getObject(table_id)
		Log.d(LOGTAG,"reconnect uid=%d,table_id=%d,add=%x",uid,table_id,tableAddr)
		local retData  = skynet.call(tableAddr,"lua","reconnect",agent, uid)
		return msg.NameToId.JoinRoomResponse,retData
	end	

	--
	local succ,retData = skynet.call(tableAddr, "lua", "join", agent, uid)
	if succ then 
		if not user then 
			user = new(GameUserInfo)
			user:init(uid)
			self.m_users:addObject(user, uid)
		end 	
		user:joinTable(data.room_id)
		Log.d(LOGTAG,"uid = %d success join table_id=%d",uid,data.room_id)
		return msg.NameToId.JoinRoomResponse,retData		
	else 
		Log.d(LOGTAG,"uid = %d failed join table_id=%d, reason=%s",uid,data.room_id,tostring(retData))
		return _onMsgFaild(msg.NameToId.JoinRoomResponse, retData)
	end 
end



function GameServerLogic:handlerClientReq(uid, msgId, data)
	local user = self.m_users:getObject(uid)
	if user then 
		local table_id  = user:getTableId()
		local tableAddr = self.m_tables:getObject(table_id)

		return skynet.call(tableAddr, "lua", "on_req", uid, msgId, data)
	end		
	Log.e(LOGTAG,"Not In Table,can not access unkonwn msgId = ",msgId)
end


function GameServerLogic:_cleanUserJoined(uid)
	local user = self.m_users:getObject(uid)
	if user then 
		user:joinTable(nil)
	else
		Log.e(LOGTAG,"may be error! not found uid=%d in self.m_users",uid)
	end
end
function GameServerLogic:_cleanUserCreated(uid,tid)
	local user = self.m_users:getObject(uid)
	if user then 
		if not user:removeCreatedTable(tid) then 
			Log.e(LOGTAG,"may be error! not found tid:%d in uid:%d creaters!",tid,uid)
		end 
	else
		Log.e(LOGTAG,"may be error! not found uid=%d in self.m_users",uid)
	end
end

function GameServerLogic:_cleanTable(taddr,tableId)
	self.m_idPool:recoverId(tableId)

	local tableAddr = self.m_tables:getObject(tableId)
	if tableAddr then 
		if tableAddr ~= tableSvr then 
			Log.e(LOGTAG,"may be error! table address not equal!")
		end 
		self.m_tables:removeObject(nil,tableId)
	else
		Log.e(LOGTAG,"may be error! not found tableId=%d in self.m_tables!",tableId)
	end 
end

function GameServerLogic:releaseTable(tableSvr, tableId, create_uid,uids)
	--清空加入关联
	for _,uid in ipairs(uids) do
		self:_cleanUserJoined(uid)
	end
	--清空创建者关联
	self:_cleanUserCreated(create_uid, tableId)
	--清空桌子
	self:_cleanTable(tableSvr, tableId)
end

function GameServerLogic:leaveTable(uid, tableId)
	self:_cleanUserJoined(uid)
end

return GameServerLogic