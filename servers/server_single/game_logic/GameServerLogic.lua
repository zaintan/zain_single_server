------------------------------------------------------
---! @file
---! @brief GameServerLogic, 管理GameServer 创建桌子 加入桌子 透传房间消息
------------------------------------------------------
local skynet    = require "skynet"
require "skynet.manager"

local GameServerLogic = {}

---! 辅助依赖
local NumSet       = require "NumSet"

local GameUserInfo = require "game_logic.data.GameUserInfo"

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
	-- body
end

function GameServerLogic:init()
	---! all tables:  k = table_id; v = table;
	self.m_tables = NumSet.create()
	---! all users:  k = user_id; v = table_id;
	self.m_users  = NumSet.create()

	local TableIdPool = require("game_logic.TableIdPool")
	self.m_idPool = new(TableIdPool)
end

local function _onMsgFaild(id, err_tip)
	return id,{status = -1;status_tip = err_tip;}
end

function GameServerLogic:handlerCreateReq(uid, data)
	local user = self.m_users:getObject(uid)
	if user and not user:canCreateTable() then 
		return _onMsgFaild(const.MsgId.CreateRoomRsp,"开房数量已达上限!")
	end	  

	local table_id = self.m_idPool:allocId()
	--没使用 要记得回收房间号
	if not table_id then 
		return _onMsgFaild(const.MsgId.CreateRoomRsp,"分配房间号失败!")
	end 

	local tableSvr = skynet.newservice("GameTableService")
	if pcall(skynet.call, tableSvr, "lua", "init", skynet.self(), table_id, data) then 
		if not user then 
			user = new(GameUserInfo)
			user:init(uid)
			self.m_users:addObject(user, uid)
		end 
		user:addCreatedTable(table_id)
		self.m_tables:addObject(tableSvr, table_id)
		return const.MsgId.CreateRoomRsp,{status = 0;room_id = table_id;}
	else 
		skynet.kill(tableSvr)
		self.m_idPool:recoverId(table_id)
		return _onMsgFaild(const.MsgId.CreateRoomRsp,"房间初始化失败!")
	end 
end

function GameServerLogic:handlerJoinReq(agent, uid, data)
	--判断房间号存不存在
	local tableAddr = self.m_tables:getObject(data.room_id)
	if not tableAddr then 
		return _onMsgFaild(const.MsgId.JoinRoomRsp,"房间号不存在!")
	end 

	--判断用户是否已经加入过房间了  
	local user = self.m_users:getObject(uid)
	if user and not user:canJoinTable() then 
		--已经在房间里面了 返回重连消息
		local table_id = user:getTableId()
		local tableAddr = self.m_tables:getObject(table_id)

		local retData  = skynet.call(tableAddr,"lua","reconnect",agent, uid)
		return const.MsgId.JoinRoomRsp,retData
	end	

	--
	local succ,retData = skynet.call(tableAddr, "lua", "join", agent, uid)
	if succ then 
		if not user then 
			user = new(GameUserInfo)
			user:init(uid)
			self.m_users:addObject(user, uid)
		end 	
		user:joinTable(table_id)
		return const.MsgId.JoinRoomRsp,retData		
	else 
		return _onMsgFaild(const.MsgId.JoinRoomRsp, retData)
	end 
end



function GameServerLogic:handlerClientReq(uid, msgId, data)
	local user = self.m_users:getObject(uid)
	if user then 
		local table_id  = user:getTableId()
		local tableAddr = self.m_tables:getObject(table_id)

		return skynet.call(tableAddr, "lua", "on_req", uid, msgId, data)
	end		
	log.e("GameServer","Not In Table,can not access unkonwn msgId = ",msgId)
end

return GameServerLogic