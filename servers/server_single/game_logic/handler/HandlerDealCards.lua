------------------------------------------------------
---! @file
---! @brief HandlerDealCards
------------------------------------------------------
local Super            = require("game_logic.handler.BaseHandler")
local HandlerDealCards = class(Super)

function HandlerDealCards:ctor(...)
	self.m_status = const.GameHandler.DEAL_CARDS
end

function HandlerDealCards:onEnter()
	-- body
	--每人抓13张牌
	self.m_pTable:dealPlayersCards(self.m_pState.m_curBanker, 13)
	
	self.m_pState:changeHandler(const.GameHandler.SEND_CARD)
--	--庄家多抓一张
--	self.m_pTable:drawCard(self.m_pState.m_curBanker)
--	--判断庄家是否可以操作
--	local playerCards = self.m_pTable:getPlayerCards(self.m_pState.m_curBanker)
--	if playerCards:canGang() then 
--		self.m_pState:changeHandler(const.GameHandler.)
--	end 
end




return HandlerDealCards