------------------------------------------------------
---! @file
---! @brief HandleDealCards
------------------------------------------------------
local Super            = require("abstract.BaseHandle")
local HandleDealCards  = class(Super)



function HandleDealCards:onEnter()
	-- body
	--每人抓13张牌
	local num = self.m_pTable:getCurPlayerNum()
	for seat=0,num-1 do
		local cards = self.m_pTable:dispatchCard(13)
		--更新玩家手牌
		self.m_pTable:updateHandCards(seat, cards)
	end
	--广播发牌消息
	self:_broadcastPlayerCards()
	--切到 发牌状态
	self.m_pState:changeHandler(const.GameHandler.SEND_CARD)
end


function HandleDealCards:_broadcastPlayerCards()
	-- body
end



return HandleDealCards