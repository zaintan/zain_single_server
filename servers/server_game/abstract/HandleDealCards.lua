------------------------------------------------------
---! @file
---! @brief HandleDealCards
------------------------------------------------------
local Super            = require("abstract.BaseHandle")
local HandleDealCards  = class(Super)



function HandleDealCards:onEnter()
	Super.onEnter(self)
	-- body
	--每人抓13张牌
	local num = self.m_pTable:getCurPlayerNum()
	for seat=0,num-1 do
		local cards = self.m_pTable:getCard(13)
		Log.dump("",cards)
		--更新玩家手牌
		self.m_pTable:updateHandCards(seat, cards)
	end
	--
	local head_send_count = self.m_pTable:getUsedCardHeadCount();
	local tail_send_count = self.m_pTable:getUsedCardTailCount();
	--广播发牌消息
	for seat=0,num-1 do 
		local msg_data = self.m_pTable:getStartCardsInfo(seat)
		--
		msg_data.head_send_count = head_send_count
		msg_data.tail_send_count = tail_send_count
		--
		self.m_pTable:sendMsgBySeat(msg.NameToId.DealCardsPush, msg_data, seat)
	end 
	--local hasHand,hasWeave,hasDiscard = true,true,true
	--self.m_pTable:broadcastPlayerCards(hasHand,hasWeave,hasDiscard)
	--切到 发牌状态
	local seat_index = self.m_pTable:getCurSeat()
	self.m_pState:changeHandle(const.GameHandler.SEND_CARD, seat_index)
end

return HandleDealCards