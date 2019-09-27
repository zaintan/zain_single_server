------------------------------------------------------
---! @file
---! @brief HandleSendCard
------------------------------------------------------
local Super            = require("abstract.BaseHandle")
local HandleSendCard  = class(Super)

function HandleSendCard:onEnter()
	--重置玩家状态 所有操作
	self.m_pTable:resetOperates()
	--当前操作者
	self.seat_index = self.m_pTable:getCurSeat()
	--发牌
	local card = self.m_pTable:getCard(1)
	if not card then 
		Log.i("","发牌失败！牌池没有牌了, 流局")
		self.m_pState:handleRoundOver()
		return
	end 
	self.send_card = card
	self.m_pTable:dispatchCard(self.seat_index, card)
	--判断当前操作者是否可以操作 广播操作状态
	local checkWiks   = {const.Action.AN_GANG, const.Action.ZHI_GANG, const.Action.ZI_MO };
	local playerCards = self.m_pTable:getPlayerCards() 
	
	self.m_pTable:checkPlayerOperates(self.seat_index, playerCards,checkWiks, card, self.seat_index, true)

	self.player_status = self.m_pTable:getPlayerStatus(self.seat_index)
end


function HandleSendCard:_onOutCardReq(msg_id, uid, data)
	local ret_msg_id = msg_id + msg.ResponseBase
	local seat_index = self.m_pTable:getPlayerSeat(uid)
	--不是该玩家
	if seat_index ~= self.seat_index then 
		self.m_pTable:sendMsg(ret_msg_id, {status = -2;}, uid)
		return false
	end 
	--不在出牌状态
	if self.player_status ~= const.PlayerStatus.OUT_CARD then 
		self.m_pTable:sendMsg( ret_msg_id, {status = -3;}, uid)
		return false
	end

	--不存在的牌
	local playerCards = self.m_pTable:getPlayerCards(self.seat_index)
	if playerCards:getCardNumInHands(data.out_card) > 0 then 
		self.m_pTable:sendMsg(ret_msg_id, {status = -4;}, uid)
		return false
	end 

	self.m_pTable:outCard(uid, data.out_card)
	--changehandler
	self.m_pState:changeHandler(const.GameHandler.OUT_CARD, seat_index, data.out_card)
	return false
end

function HandleSendCard:_onOperateCardReq(msg_id, uid, data)
	Log.d(LOGTAG, "_onOperateCardReq msg_id=%d,uid=%d",msg_id,uid)
	Log.dump(LOGTAG, data)

	local ret_msg_id = msg_id + msg.ResponseBase
	local seat_index = self.m_pTable:getPlayerSeat(uid)
	--不是该玩家
	if seat_index ~= self.seat_index then 
		Log.d(LOGTAG, "seat_index=%d, self.seat_index=%d",seat_index,self.seat_index)
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -2;})
		return false
	end 
	--不在出牌状态
	if self.player_status ~= const.PlayerStatus.OPERATE_CARD then 
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

	if data.weave_kind == const.Action.AN_GANG
		or data.weave_kind == const.Action.ZHI_GANG  then 
		--切handlerGang
		self.m_pState:changeHandler(const.GameHandler.GANG, seat_index, data, self.seat_index)		
	elseif data.weave_kind == const.Action.ZI_MO then 
		--切gameOver
		self.m_pState:gameRoundOver(const.RoundFinishReason.NORMAL,self.seat_index,self.seat_index)
	end 
	--self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return true
end
return HandleSendCard