------------------------------------------------------
---! @file
---! @brief HandleOutCard
------------------------------------------------------
local Super            = require("abstract.BaseHandle")
local HandleOutCard    = class(Super)

function HandleOutCard:onEnter(seat_index)
	self.seat_index = seat_index
	--广播玩家状态
	self.m_pTable:broadcastPlayersStatus()
end

function HandleOutCard:onOutCardReq( uid, msg_id, data )
	Log.d(LOGTAG, "onOutCardReq msg_id=%d,uid=%d",msg_id,uid)
	Log.dump(LOGTAG, data)

	local ret_msg_id = msg_id + msg.ResponseBase
	local seat_index = self.m_pTable:getPlayerByUid(uid).seat
	--不是该玩家
	if seat_index ~= self.seat_index then 
		self.m_pTable:sendMsg(ret_msg_id, {status = -2;}, uid)
		return false
	end 
	--不在出牌状态
	local player_status = self.m_pTable:getPlayerStatus(seat_index)
	if player_status ~= const.PlayerStatus.OUT_CARD then 
		self.m_pTable:sendMsg( ret_msg_id, {status = -3;}, uid)
		return false
	end

	--不存在的牌
	local playerCards = self.m_pTable:getPlayerCards(self.seat_index)
	if playerCards:getCardNumInHands(data.out_card) > 0 then 
		self.m_pTable:sendMsg(ret_msg_id, {status = -4;}, uid)
		return false
	end 
	--广播玩家出牌
	self.m_pTable:outCard(seat_index, data.out_card)
	
	local hasOperate = self:_checkOthersCanOperate(data.out_card, seat_index)
	if hasOperate then 
		self.m_pState:changeHandle(const.GameHandler.WAI_OPERATE, data.out_card, seat_index, nil)
	else
		self.m_pState:changeHandle(const.GameHandler.SEND_CARD, self.m_pTable:turnSeat())
	end 
	return true
	
end

function HandleOutCard:_checkOthersCanOperate(card, provider)
	--重置玩家状态 所有操作
	self.m_pTable:resetOperates()
	local checkWiks = {const.Action.PENG, const.Action.PENG_GANG, const.Action.JIE_PAO};

	local hasAction = false
	local num = self.m_pTable:getCurPlayerNum()
	for seat = 0,num-1 do
		--自己的不用检查
		if seat ~= self.seat_index then 
			local playerCards = self.m_pTable:getPlayerCards(self.seat_index) 
			local ret = self.m_pTable:checkPlayerOperates(seat, playerCards, checkWiks, card, provider, true)
			hasAction = hasAction or ret
		end 
	end
	return hasAction
end


return HandleOutCard