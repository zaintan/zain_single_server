------------------------------------------------------
---! @file
---! @brief HandlerOutCard
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerOutCard = class(Super)

function HandlerOutCard:ctor()
	self.m_status = const.GameHandler.OUT_CARD
end

function HandlerOutCard:onEnter(seat_index, out_card)
	-- body
	self.m_pState:resetPlayerStatuses()
	
	for seat = 0,self.m_pTable.m_curPlayerNum-1 do
		if seat ~= seat_index then 
			local playerCards = self.m_pTable:getPlayerCards(seat)
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