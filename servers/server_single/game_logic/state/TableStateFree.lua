------------------------------------------------------
---! @file
---! @brief TableStateFree
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStateFree = class(Super)

function TableStateFree:ctor(pTable)
	self.m_status = const.GameStatus.FREE
end

function TableStateFree:onEnter()
	-- body
end

function TableStateFree:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStateFree:join(agent, uid)
	-- body
	if self.m_pTable:isFull() then 
		return false,"房间已经满了!"
	end 

	if not self.m_pTable:isInTable() then 
		local ok,data = pcall(skynet.call, ".LoginService", "lua", "query", uid)
		if ok and data then 
			self.m_pTable:addPlayer(agent, uid, data)
		else
			return false,"登录服查不到该玩家!"
		end 
	end 

	local info = self.m_pTable:getBaseInfo()
	info.status = 0
	return true,info
end

--return JoinRoomResponse
function TableStateFree:reconnect(agent, uid)
	local info = self.m_pTable:getBaseInfo()
	info.status = 0
	return info
end


function TableStateFree:_onReadyReq(msg_id, uid, data)
	local player = self.m_pTable:getPlayer(uid)
	if not player then 
		self.m_pTable:sendMsg(uid, const.MsgId.ReadyRsp, {status = -1;})
		return false
	end 

	player.ready = data.ready
	self.m_pTable:sendMsg(uid, const.MsgId.ReadyRsp, {status = 0;ready = data.ready;})
	self.m_pTable:broadcastMsg(const.MsgId.ReadyPush, {seat_index = player.seat_index;ready = data.ready;}, uid)
	
	if self.m_pTable:isFull() and self.m_pTable:isAllReady() then 
		self.m_pTable:changePlay()
	end 
	return true
end

function TableStateFree:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip = "牌局还未开始,无法出牌!";})
end

function TableStateFree:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip = "牌局还未开始,无法操作牌!";})
end


return TableStateFree