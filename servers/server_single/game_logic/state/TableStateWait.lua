------------------------------------------------------
---! @file
---! @brief TableStateWait
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStateWait = class(Super)

function TableStateWait:ctor(pTable)
	self.m_status = const.GameStatus.WAIT
end

function TableStateWait:onEnter()
	--取消所有玩家的准备状态
	local push_data = {
		ready_infos = {}
	}

	local players     = self.m_pTable:getPlayers()	
	for id,player in pairs(players) do
		player.ready  = false
		table.insert(push_data.ready_infos,{seat_index = player.seat_index;ready = false;})	
		
		--清理掉玩家的牌
		local playerCards = self.m_pTable:getPlayerCards(player.seat_index)
		playerCards:reset()
	end
	self.m_pTable:broadcastMsg(msg.NameToId.ReadyPush, push_data)	
end

function TableStateWait:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStateWait:join(agent, uid)
	return false,"无法加入,牌局已开始!"
end

--return JoinRoomResponse
function TableStateWait:reconnect(agent, uid)
	Super.reconnect(self, agent, uid)
	
	local info = self.m_pTable:getBaseInfo()
	info.status = 1
	return info	
end


function TableStateWait:_onReadyReq(msg_id, uid, data)
	local player = self.m_pTable:getPlayer(uid)
	if not player then 
		self.m_pTable:sendMsg(uid, msg.NameToId.ReadyResponse, {status = -1;})
		return false
	end

	player.ready = data.ready
	self.m_pTable:sendMsg(uid, msg.NameToId.ReadyResponse, {status = 0;ready = data.ready;})

	local push_data = {
		ready_infos = {{seat_index = player.seat_index;ready = data.ready;}}
	}
	self.m_pTable:broadcastMsg(msg.NameToId.ReadyPush, push_data, uid)
	
	if self.m_pTable:isAllReady() then 
		self.m_pTable:changePlay()
	end 
	return true	
end

function TableStateWait:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;status_tip = "牌局还未开始,无法出牌!";})
end

function TableStateWait:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;status_tip = "牌局还未开始,无法操作牌!";})
end


return TableStateWait