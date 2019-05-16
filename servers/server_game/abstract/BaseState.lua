------------------------------------------------------
---! @file
---! @brief BaseState
------------------------------------------------------

local Super     = require("abstract.BaseContainer")
local BaseState = class(Super)

function BaseState:ctor(pTable, status)
	self.m_pTable = pTable
	self.m_status = status
	
	self:onInit()
end

function BaseState:getStatus()
	return self.m_status
end

function BaseState:onInit()
	-- body
end


function BaseState:onEnter()
	Log.i("","State:%d onEnter",self.m_status)
end

function BaseState:onExit()
	Log.i("","State:%d onExit",self.m_status)
end


local function _retDefaultMsg(uid, msg_id)
	self.m_pTable:sendMsg(msg_id + msg.ResponseBase , {status = -401;}, uid)
	return false
end


function BaseState:onReadyReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseState:onOutCardReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseState:onOperateCardReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseState:onPlayerExitReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

return BaseState