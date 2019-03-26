------------------------------------------------------
---! @file
---! @brief TableStatePlay
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStatePlay = class(Super)

function TableStatePlay:ctor(pTable)
	self.m_status = const.GameStatus.PLAY
	
	self.m_winSeat   = 0
	self.m_curRound  = 0
	self.m_curBanker = 0
	self.m_curSeatIndex = self.m_curBanker;
	self.dice_values    = {1,1}

	self:_initPlayerStatuses()
	self:_initHandlers()
end


function TableStatePlay:_addHandler(path)
	local handler = require(path)
	local entity = new(handler,self,self.m_pTable)
	self.m_mapHandler[entity:getStatus()] = entity
end

function TableStatePlay:_initHandlers()
	self.m_curHandler = nil
	self.m_mapHandler = {}
	self:_addHandler("game_logic.handler.HandlerDealCards")
	self:_addHandler("game_logic.handler.HandlerSendCard")
	self:_addHandler("game_logic.handler.HandlerChiPeng")
	self:_addHandler("game_logic.handler.HandlerGang")
	self:_addHandler("game_logic.handler.HandlerOutCard")
end

function TableStatePlay:_changeHandler(toHandler)
	if self.m_curHandler then 
		self.m_curHandler:onExit()
	end 
	self.m_curHandler = toHandler
	self.m_curHandler:onEnter()
end

function TableStatePlay:changeHandler( Gamehandler )
	local toHandler = self.m_mapHandler[Gamehandler]
	if toHandler then 
		self:_changeHandler(toHandler)
		return true
	end 
	return false
end

function TableStatePlay:onEnter()
	-- body
	--init Round
	self:resetPlayerStatuses()
	self.m_curRound = self.m_curRound + 1
	--第一局 随机庄家  
	if self.m_curRound == 1 then
		self.m_curBanker = self.m_pTable:getRandBanker()
	else 
		self.m_curBanker = self.m_winSeat--
	end 
	self.m_curSeatIndex = self.m_curBanker	
	--洗牌
	self.m_pTable:getCardsPool():initRound()
	--摇骰子
	self.dice_values[1] = math.random(6)
	self.dice_values[2] = math.random(6)	
	--广播牌局开始消息
	self:broadcastMsg(const.MsgId.GameStartPush, {game_status = self.m_status;round_room_info = self:_getRoundRoomInfo();})
	--发牌
	self:changeHandler(const.Gamehandler.DEAL_CARDS)
end

function TableStatePlay:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStatePlay:join(agent, uid)
	return false,"无法加入,牌局已开始!"
end

--return JoinRoomResponse
function TableStatePlay:reconnect(agent, uid)
	local info = self.m_pTable:getBaseInfo()
	info.status = 0
	info.op_info         = self:_getOpInfo();
	info.cards_infos     = self:_getCardsInfo();
	info.round_room_info = self:_getRoundRoomInfo();
	return info
end


function TableStatePlay:_onReadyReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip = "牌局已经开始,无效准备消息!";})
end

function TableStatePlay:_onOutCardReq(msg_id, uid, data)
	self.m_curHandler:_onOutCardReq(msg_id, uid, data)
end

function TableStatePlay:_onOperateCardReq(msg_id, uid, data)
	self.m_curHandler:_onOperateCardReq(msg_id, uid, data)
end

function TableStatePlay:_getOpInfo()
	return nil
end

function TableStatePlay:_getCardsInfo()
	return nil
end

function TableStatePlay:_getRoundRoomInfo()
	local info = {}
	info.cur_val            = self.m_curRound;
	info.cur_banker         = self.m_curBanker;
	info.pointed_seat_index = self.m_curSeatIndex;
	info.dice_values        = self.dice_values;
	info.player_statuses    = self.player_statuses;

	local cardPool       = self.m_pTable:getCardsPool()
	info.remain_num      = cardPool:getRemainNum()
	info.total_num       = cardPool:getTotalNum()
	info.head_send_count = cardPool:getHeadSendCount();
	info.tail_send_count = cardPool:getTailSendCount();
	return info 
end

function TableStatePlay:resetPlayerStatuses()
	local statuses = self.player_statuses
	for k,v in pairs(statuses) do
		statuses[k] = const.PlayerStatus.NULL
	end
end

function TableStatePlay:_initPlayerStatuses()
	self.player_statuses = {}
	for k,v in pairs(self.m_pTable.m_players) do
		self.player_statuses[v.seat_index] = const.PlayerStatus.NULL
	end
end

return TableStatePlay