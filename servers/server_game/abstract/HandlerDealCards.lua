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
end




return HandlerDealCards