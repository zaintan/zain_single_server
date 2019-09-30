------------------------------------------------------
---! @file
---! @brief BaseHandle
------------------------------------------------------
local BaseHandle = class()

function BaseHandle:ctor(pState,status)
	self.m_pState = pState
	self.m_status = status
	--
	self.m_pTable = pState.m_pTable
	--
	self:onInit()
end

function BaseHandle:getStatus()
	return self.m_status
end

function BaseHandle:onInit()
	-- body
end

function BaseHandle:onEnter()
	Log.i("","Handle:%d onEnter",self.m_status)
end

function BaseHandle:onExit()
	Log.i("","Handle:%d onExit",self.m_status)
end


local function _retDefaultMsg(uid, msg_id)
	self.m_pTable:sendMsg(msg_id + msg.ResponseBase , {status = -450;}, uid)
	return false
end

function BaseHandle:onOutCardReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseHandle:onOperateCardReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

return BaseHandle