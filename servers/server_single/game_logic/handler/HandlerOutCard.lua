------------------------------------------------------
---! @file
---! @brief HandlerOutCard
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerOutCard = class(Super)

function HandlerOutCard:ctor()
	self.m_status = const.GameHandler.OUT_CARD

	self.seat_index = -1
	self.out_card   = 0
end

function HandlerOutCard:onEnter(seat_index, out_card)
	------------------------------
	self.seat_index = seat_index
	self.out_card   = out_card
	-- body
	self.m_pState:resetPlayerStatuses()
	self.m_pTable:cleanActions()
	
	for seat = 0,self.m_pTable:getCurPlayerNum() - 1 do
		if seat ~= seat_index then 
			local playerCards = self.m_pTable:getPlayerCards(seat)
			local actions = playerCards:checkAddAction(const.GameAction.GANG, const.GameAction.ZI_MO)
			if actions and #actions > 0 then 
				self.player_status = const.PlayerStatus.OPERATE
			else 
				self.player_status = const.PlayerStatus.OUT_CARD
			end 
		end 
	end
end

function HandlerOutCard:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function HandlerOutCard:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end


return HandlerOutCard