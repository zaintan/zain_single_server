------------------------------------------------------
---! @file
---! @brief HandlerGang
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerGang = class(Super)

function HandlerGang:ctor(...)
	self.m_status = const.GameHandler.GANG
end

function HandlerGang:onEnter()
	-- body
end

function HandlerGang:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function HandlerGang:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end


return HandlerGang