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
	--Log.d(LOGTAG,"_changeHandler")
	if self.m_curHandler then 
		self.m_curHandler:onExit()
	end 
	self.m_curHandler = toHandler
	Log.d(LOGTAG,"_changeHandler = %d",self.m_curHandler:getStatus() )
	self.m_curHandler:onEnter(...)
end

function TableStatePlay:changeHandler( handler, ...)
	local toHandler = self.m_mapHandler[handler]
	if toHandler then 
		self:_changeHandler(toHandler, ...)
		return true
	end 
	return false
end

function TableStatePlay:onEnter()
	-- body
	--init Round
	self:resetPlayerStatuses()
	self.m_curRound = self.m_curRound + 1
	--
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
	self.m_pTable:broadcastMsg(msg.NameToId.GameStartPush, {game_status = self.m_status;round_room_info = self:_getRoundRoomInfo();})
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

function TableStatePlay:turnSeat(nextSeat)
	if nextSeat then 
		self.m_curSeatIndex = nextSeat
	else 
		self.m_curSeatIndex = (self.m_curSeatIndex + 1)%self.m_pTable:getCurPlayerNum()
	end 
end


function TableStatePlay:_onReadyReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;status_tip = "牌局已经开始,无效准备消息!";})
end

function TableStatePlay:_onOutCardReq(msg_id, uid, data)
	Log.d(LOGTAG, "_onOutCardReq msg_id=%d,uid=%d",msg_id,uid)
	self.m_curHandler:_onOutCardReq(msg_id, uid, data)
end

function TableStatePlay:_onOperateCardReq(msg_id, uid, data)
	Log.d(LOGTAG, "_onOperateCardReq msg_id=%d,uid=%d",msg_id,uid)
	self.m_curHandler:_onOperateCardReq(msg_id, uid, data)
end

function TableStatePlay:_getOpInfo(uid)
	local info = {}
	local player = self.m_pTable:getPlayer(uid)
	info.weaves  = self.m_pTable:getPlayerCards(player.seat_index):getActions();
	return info
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
		statuses[k] = const.PlayerStatus.NONE
	end
end

function TableStatePlay:_initPlayerStatuses()
	self.player_statuses = {}
	local num = self.m_pTable:getMaxPlayerNum()
	--local players = self.m_pTable:getPlayers()
	--Log.d(LOGTAG,"_initPlayerStatuses num=%d self=%s",num,tostring(self));
	for i=1,num do
		self.player_statuses[i] = const.PlayerStatus.NONE
	end
	--Log.dump(LOGTAG,self.player_statuses)
end

function TableStatePlay:changePlayerStatus( seat_index, status )
	self.player_statuses[seat_index+1] = status
end

function TableStatePlay:getPlayerStatus(seat_index)
	return self.player_statuses[seat_index+1]
end

function TableStatePlay:broadcastPlayerStatus()
	local players     = self.m_pTable:getPlayers()	

	for id,player in pairs(players) do
		local seat_index = player.seat_index
		
		local msg_data = {};
		msg_data.player_status      = self.player_statuses[seat_index+1];
		msg_data.pointed_seat_index = self.m_curSeatIndex;
		msg_data.op_info = {}            
		msg_data.op_info.weaves = self.m_pTable:getPlayerCards(seat_index):getActions();

		self.m_pTable:sendMsg(player.user_id, msg.NameToId.PlayerStatusPush , msg_data)
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
	Log.d(LOGTAG,"getPlayerCardsInfo:cards_seat=%d,send_seat=%d",cards_seat,send_seat);
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
	Log.dump(LOGTAG,data);
	return data
end

function TableStatePlay:broadcastRoomCards(hasHand, hasWeave, hasDiscard, exceptSeats)
	local except = exceptSeats or {}--不包括这些座位号玩家的牌
	
	local players = self.m_pTable:getPlayers()
	--Log.d(LOGTAG,"broadcastRoomCards: %s",tostring(self));
	for id,player in pairs(players) do
		local msg_data = {cards_infos = {};};
		--Log.dump(LOGTAG,self.player_statuses)
		for seat,_ in pairs(self.player_statuses) do
			local cards_seat  = seat - 1
			--Log.d(LOGTAG,"cards_seat:%d,except",cards_seat);
			--Log.dump(LOGTAG,except)

			if not _isInArray(cards_seat,  except) then 
				local playerCards = self.m_pTable:getPlayerCards(cards_seat)
				local data = _getPlayerCardsInfo(playerCards,cards_seat,player.seat_index,hasHand, hasWeave, hasDiscard)
				table.insert(msg_data.cards_infos, data)
			end
		end
		self.m_pTable:sendMsg(player.user_id, msg.NameToId.RoomCardsPush , msg_data )
	end
end

function TableStatePlay:broadcastPlayerCards(cards_seat, hasHand, hasWeave, hasDiscard)
	local players = self.m_pTable:getPlayers()
	for id,player in pairs(players) do
		local msg_data = {};
		local playerCards    = self.m_pTable:getPlayerCards(cards_seat)
		msg_data.cards_infos = _getPlayerCardsInfo(playerCards,cards_seat, player.seat_index,hasHand, hasWeave, hasDiscard)
		self.m_pTable:sendMsg(player.user_id, msg.NameToId.PlayerCardsPush , msg_data)
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

function TableStatePlay:broadcastShowCards()
	local data = {	cards_infos = {}; };
	for i=1,self.m_pTable:getCurPlayerNum() do
		local info = {
			has_hands    = true;
			has_weaves   = false;
			has_discards = false;
			seat_index   = i-1;
		}
		info.hands = self.m_pTable:getPlayerCards(i-1):getHands()
		table.insert(data.cards_infos, info)
	end
	self.m_pTable:broadcastMsg(msg.NameToId.ShowHandCardsPush, data)
end

function TableStatePlay:gameRoundOver(roundOverType, hu_seat, provider)
	--确定下把的庄家
	if roundOverType == const.RoundFinishReason.NORMAL then 
		self.m_winSeat = hu_seat	
	else
		local haidiSeat = (self.m_curSeatIndex - 1)%self.m_pTable:getCurPlayerNum()
		self.m_winSeat  = haidiSeat
	end 
	self:broadcastShowCards()
	--推送游戏结束消息
	local data = {}
	data.game_status     = const.GameStatus.WAIT
	data.finish_desc     = {}
	data.final_scores    = {}
	--data.win_types       = {}
	data.cards_infos     = {}

	local score_beilv = 1
	local player_num  = self.m_pTable:getCurPlayerNum()
	for i=1,player_num do
		local seat = i - 1
		if hu_seat and provider == hu_seat then --自摸
			if seat == hu_seat then 
				data.finish_desc[i]  = "自摸"
				data.final_scores[i] = (player_num-1)*score_beilv
				self.m_pTable.m_statistics:addSpecailCount(seat,const.SpecialCountType.ZI_MO,1)	
			else 
				data.finish_desc[i]  = ""
				data.final_scores[i] = -score_beilv	
			end 
		elseif hu_seat and provider ~= hu_seat then --放炮
			if seat == hu_seat then 
				data.finish_desc[i]  = "接炮"
				data.final_scores[i] = score_beilv
				--data.win_types[i]    = 0
				self.m_pTable.m_statistics:addSpecailCount(seat,const.SpecialCountType.JIE_PAO,1)				
			elseif seat == provider then 
				data.finish_desc[i]  = "放炮"
				data.final_scores[i] = -score_beilv
				--data.win_types[i]    = 0
			else 
				data.finish_desc[i]  = ""
				data.final_scores[i] = 0
				--data.win_types[i]    = 0
			end 
		else
			data.finish_desc[i]  = ""
			data.final_scores[i] = 0
			--data.win_types[i]    = 0
		end 

		self.m_pTable.m_statistics:addScore(seat,data.final_scores[i])

		local playerCards = self.m_pTable:getPlayerCards(seat)
		local card_data   = _getPlayerCardsInfo(playerCards,seat,seat,true,true)
		data.cards_infos[i] = card_data
		--table.insert(msg_data.cards_infos, data)
	end
	self.m_pTable:broadcastMsg(msg.NameToId.RoundFinishPush, data)
	--累积分数
	local players = self.m_pTable:getPlayers()
	for k,player in pairs(players) do
		player.score = player.score + data.final_scores[player.seat_index + 1]
	end
	--
	----大结算
	if self.m_curRound == self.m_pTable:getOverVal() then 
		--game over
		local over_data = {player_infos = {};};
		for _,player in pairs(players) do
			local pinfo = {}
			pinfo.total_scores = player.score
			over_data.player_infos[player.seat_index] = pinfo
		end		
		--self.m_pTable:broadcastMsg(msg.NameToId.GameFinishPush, over_data)
		self.m_pTable:destroy(const.GameFinishReason.NORMAL)
	else
		--切换到小局之间的等待状态
		self.m_pTable:changeWait()
	end 	
end
return TableStatePlay