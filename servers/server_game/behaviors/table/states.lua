--behaviors.states
local Super            = require("behaviors.behavior")
local states           = class(Super)

local LOGTAG = "states"

states.EXPORTED_METHODS = {
    "changeState",
    "getCurState",     
}

states.states_cfg = {
	[const.GameStatus.FREE] = "abstract.StateFree",
	[const.GameStatus.PLAY] = "abstract.StatePlay",
	[const.GameStatus.WAIT] = "abstract.StateWait",	
}

function states:_pre_bind_(...)
	self.m_states   = {}
	self.m_curState = nil
end

function states:_on_bind_()
	for status,state_path in pairs(self.states_cfg) do
		local c  = require(state_path)
		assert(c ~= nil)
		local st = new(c,self.target_,status)
		assert(st ~= nil)
		assert(self.m_states[status] == nil)
		self.m_states[status] = st
	end
end


function states:_clear_()
    self.target_    = nil
    self.m_states   = nil
end

function states:changeState( state )
	local toState = nil
	if type(state) == "number" then 
		toState = self.m_states[state]
	elseif type(state) == "table" then  
		toState = state
	end 

	if not toState then 
		Log.e(LOGTAG,"maybe err!切换状态失败tostate=%s",tostring(state))
		return false
	end 
	if self.m_curState then 
		self.m_curState:onExit()
	end 
	self.m_curState = toState
	self.m_curState:onEnter()
	return true
end

function states:getCurState()
	return self.m_curState
end

return states
