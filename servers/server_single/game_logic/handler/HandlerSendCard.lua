------------------------------------------------------
---! @file
---! @brief HandlerSendCard
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerSendCard = class(Super)

function HandlerSendCard:ctor(...)
	self.m_status = const.GameHandler.SEND_CARD


	self.seat_index    = -1
	self.player_status = const.PlayerStatus.NULL
end

function HandlerSendCard:onEnter()
	self.m_pState:resetPlayerStatuses()

	self.seat_index = self.m_pState.m_curSeatIndex
	--广播抓牌
	local succ,sendCard = self.m_pTable:drawCard(self.seat_index)
	if not succ then --失败  没有牌了 
		self.m_pState:gameRoundOver()
		return
	end 
--	--判断庄家是否可以操作
--  暗杆 or  自摸 or 补缸
	self.m_pTable:cleanActions()
	--self.m_pTable:cleanActions(self.seat_index)
	local playerCards = self.m_pTable:getPlayerCards(self.seat_index)
	
	local checkWiks = {const.GameAction.AN_GANG,const.GameAction.BU_GANG, const.GameAction.ZI_MO};

	local actions = playerCards:checkAddAction(checkWiks, nil, true, self.seat_index)
	if actions and #actions > 0 then 
		self.player_status = const.PlayerStatus.OPERATE
	else 
		self.player_status = const.PlayerStatus.OUT_CARD
	end 
	self.m_pState:changePlayerStatus(self.seat_index, self.player_status)
	--广播刷新玩家状态
	self.m_pState:broadcastPlayerStatus()
	
end

function HandlerSendCard:_onOutCardReq(msg_id, uid, data)
	local ret_msg_id = msg_id + const.MsgId.BaseResponse
	local seat_index = self.m_pTable:getPlayerSeat(uid)
	--不是该玩家
	if seat_index ~= self.seat_index then 
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -2;})
		return false
	end 
	--不在出牌状态
	if self.player_status ~= const.PlayerStatus.OUT_CARD then 
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -3;})
		return false
	end

	--不存在的牌
	local playerCards = self.m_pTable:getPlayerCards(self.seat_index)
	if not playerCards:hasHandCard(data.out_card) then 
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -4;})
		return false
	end 

	self.m_pTable:outCard(uid, data.out_card)
	--changehandler
	self.m_pState:changeHandler(const.GameHandler.OUT_CARD, seat_index, data.out_card)
	return false
end

function HandlerSendCard:_onOperateCardReq(msg_id, uid, data)
	Log.d(LOGTAG, "_onOperateCardReq msg_id=%d,uid=%d",msg_id,uid)
	Log.dump(LOGTAG, data)

	local ret_msg_id = msg_id + const.MsgId.BaseResponse
	local seat_index = self.m_pTable:getPlayerSeat(uid)
	--不是该玩家
	if seat_index ~= self.seat_index then 
		Log.d(LOGTAG, "seat_index=%d, self.seat_index=%d",seat_index,self.seat_index)
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -2;})
		return false
	end 
	--不在出牌状态
	if self.player_status ~= const.PlayerStatus.OPERATE then 
		Log.d(LOGTAG, "self.player_status=%d",self.player_status)
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -3;})
		return false
	end

	--不存在的操作
	local playerCards = self.m_pTable:getPlayerCards(self.seat_index)
	if not playerCards:hasAction(data) then 
		Log.d(LOGTAG, "not has Action")
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -4;})
		return false
	end 

	if data.weave_kind == const.GameAction.AN_GANG
		or data.weave_kind == const.GameAction.BU_GANG  then 
		--切handlerGang
		self.m_pState:changeHandler(const.GameHandler.GANG, seat_index, data, self.seat_index)		
	elseif data.weave_kind == const.GameAction.ZI_MO then 
		--切gameOver
		self.m_pState:gameRoundOver()
	end 
	--self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return true
end


return HandlerSendCard