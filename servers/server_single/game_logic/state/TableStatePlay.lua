------------------------------------------------------
---! @file
---! @brief TableStatePlay
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStatePlay = class(Super)

local LOGTAG = "TSPlay"

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

function TableStatePlay:_changeHandler(toHandler, ...)
	if self.m_curHandler then 
		self.m_curHandler:onExit()
	end 
	self.m_curHandler = toHandler
	self.m_curHandler:onEnter(...)
end

function TableStatePlay:changeHandler( handler )
	local toHandler = self.m_mapHandler[handler]
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
	self.m_pTable:broadcastMsg(const.MsgId.GameStartPush, {game_status = self.m_status;round_room_info = self:_getRoundRoomInfo();})
	--发牌
	self:changeHandler(const.GameHandler.DEAL_CARDS)
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
	Super.reconnect(self, agent, uid)

	local info = self.m_pTable:getBaseInfo()
	info.status = 1
	info.op_info         = self:_getOpInfo(uid);
	info.cards_infos     = self:_getCardsInfo(uid);
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

function TableStatePlay:_getOpInfo(uid)
	local player = self.m_pTable:getPlayer(uid)
	return self.m_pTable:getPlayerCards(player.seat_index):getActions();
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
	local players = self.m_pTable:getPlayers()

	for i=1,self.m_pTable:getMaxPlayerNum() do
		self.player_statuses[i] = const.PlayerStatus.NULL
	end
end

function TableStatePlay:changePlayerStatus( seat_index, status )
	self.player_statuses[seat_index+1] = status
end

function TableStatePlay:gameRoundOver()
	-- body
end

function TableStatePlay:broadcastPlayerStatus()
	local players     = self.m_pTable:getPlayers()	

	for id,player in pairs(players) do
		local seat_index = player.seat_index
		
		local msg_data = {};
		msg_data.player_status      = self.player_statuses[seat_index+1];
		msg_data.pointed_seat_index = self.m_curSeatIndex;
		msg_data.op_info            = self.m_pTable:getPlayerCards(seat_index):getActions();

		self.m_pTable:sendMsg(player.user_id, const.MsgId.PlayerStatusPush , msg_data)
	end
end



local function _isInArray( val, array )
	for i,v in ipairs(array) do
		if v == val then 
			return true
		end 
	end
	return false
end

local function _getOtherCards(cardsArr)
	local ret = {}
	for i,v in ipairs(cardsArr) do
		table.insert(ret, -1)
	end
	return ret
end

local function _getHands( playerHands, player_seat, send_seat )
	if player_seat == send_seat then 
		return playerHands
	else
		return _getOtherCards(playerHands)
	end
end

local function _getPlayerCardsInfo(playerCards,cards_seat, send_seat ,hasHand, hasWeave, hasDiscard)
	local data = {
		has_hands    = hasHand and true or false;
		has_weaves   = hasWeave and true or false;
		has_discards = hasDiscard and true or false;
		seat_index   = cards_seat;		
	}
	local hands = playerCards:getHands()
	--Log.d(LOGTAG,"getPlayerCardsInfo:cards_seat=%d,send_seat=%d",cards_seat,send_seat);
	--Log.dump(LOGTAG,hands);
	--add hands
	if hasHand then 
		data.hands = _getHands(hands,cards_seat, send_seat)
	end 
	--add weaves
	if hasWeave then 
		data.weaves = playerCards:getWeaves()
	end 
	--add discards
	if hasDiscard then 
		data.discards = playerCards:getDiscards()
	end 
	--Log.dump(LOGTAG,data);
	return data
end

function TableStatePlay:broadcastRoomCards(hasHand, hasWeave, hasDiscard, exceptSeats)
	local except = exceptSeats or {}--不包括这些座位号玩家的牌
	
	local players = self.m_pTable:getPlayers()

	for id,player in pairs(players) do
		local msg_data = {cards_infos = {};};
		for seat,_ in pairs(self.player_statuses) do
			local cards_seat  = seat - 1
			if not _isInArray(cards_seat,  except) then 
				local playerCards = self.m_pTable:getPlayerCards(cards_seat)
				local data = _getPlayerCardsInfo(playerCards,cards_seat,player.seat_index,hasHand, hasWeave, hasDiscard)
				table.insert(msg_data.cards_infos, data)
			end
		end
		self.m_pTable:sendMsg(player.user_id, const.MsgId.RoomCardsPush , msg_data )
	end
end

function TableStatePlay:broadcastPlayerCards(cards_seat, hasHand, hasWeave, hasDiscard)
	local players = self.m_pTable:getPlayers()
	for id,player in pairs(players) do
		local msg_data = {};
		local playerCards    = self.m_pTable:getPlayerCards(cards_seat)
		msg_data.cards_infos = _getPlayerCardsInfo(playerCards,cards_seat, player.seat_index,hasHand, hasWeave, hasDiscard)
		self.m_pTable:sendMsg(player.user_id, const.MsgId.PlayerCardsPush , msg_data)
	end
end

function TableStatePlay:_getCardsInfo(uid)
	local player = self.m_pTable:getPlayer(uid)

	local cards_infos = {}
	for seat,_ in pairs(self.player_statuses) do
		local cards_seat = seat - 1
		local playerCards = self.m_pTable:getPlayerCards(cards_seat)
		local data        = _getPlayerCardsInfo(playerCards,cards_seat,player.seat_index,true,true,true)
		table.insert(cards_infos, data)
	end	
	return cards_infos
end


return TableStatePlay