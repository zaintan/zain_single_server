------------------------------------------------------
---! @file
---! @brief BaseHandler
------------------------------------------------------
local BaseHandler = class()

function BaseHandler:ctor(pState,pTable)
	self.m_pState = pState
	self.m_pTable = pTable
end

function BaseHandler:getStatus()
	return self.m_status
end


function BaseHandler:onEnter()
	-- body
end

function BaseHandler:onExit()
	-- body
end

function BaseHandler:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return false
end

function BaseHandler:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return false
end


return BaseHandler