------------------------------------------------------
---! @file
---! @brief HandlerSendCard
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerSendCard = class(Super)

function HandlerSendCard:ctor(...)
	self.m_status = const.GameHandler.SEND_CARD
end

function HandlerSendCard:onEnter()
	-- body
end

function HandlerSendCard:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function HandlerSendCard:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end


return HandlerSendCard