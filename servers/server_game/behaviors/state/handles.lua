--behaviors.state.handles
local Super            = require("behaviors.behavior")
local handles          = class(Super)

local LOGTAG = "handles"

handles.EXPORTED_METHODS = {
    "changeHandle",
    "getCurHandle",     
}

handles.handles_cfg = {
	[const.GameHandler.DEAL_CARDS] = "abstract.HandleDealCards",
	[const.GameHandler.SEND_CARD]  = "abstract.HandleSendCard",
	[const.GameHandler.CHI_PENG]   = "abstract.HandleChiPeng",	
	[const.GameHandler.GANG]       = "abstract.HandleGang",	
	[const.GameHandler.OUT_CARD]   = "abstract.HandleOutCard",			
}

function handles:_pre_bind_(...)
	self.m_handles   = {}
	self.m_curHandle = nil
end

function handles:_on_bind_()
	for status,handle_path in pairs(self.handles_cfg) do
		local c  = require(handle_path)
		assert(c ~= nil)
		local st = new(c,self.target_,status)
		assert(st ~= nil)
		assert(self.m_handles[status] == nil)
		self.m_handles[status] = st
	end
end


function handles:_clear_()
    self.target_     = nil
    self.m_handles   = nil
end

function handles:changeHandle( handle )
	local tohandle= nil
	if type(handle) == "number" then 
		tohandle = self.m_handles[handle]
	elseif type(handle) == "table" then  
		tohandle = handle
	end 

	if not tohandle then 
		Log.e(LOGTAG,"maybe err!切换状态失败tohandle=%s",tostring(tohandle))
		return false
	end 
	assert(self.m_curHandle ~= tohandle)
	if self.m_curHandle then 
		self.m_curHandle:onExit()
	end 
	self.m_curHandle = tohandle
	self.m_curHandle:onEnter()
	return true
end

function handles:getCurHandle()
	return self.m_curHandle
end

return handles
