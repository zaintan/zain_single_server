------------------------------------------------------
---! @file
---! @brief HandlerChiPeng
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerChiPeng = class(Super)

function HandlerChiPeng:ctor(...)
	self.m_status = const.GameHandler.CHI_PENG
end

function HandlerChiPeng:onEnter()
	-- body
end

function HandlerChiPeng:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function HandlerChiPeng:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end


return HandlerChiPeng