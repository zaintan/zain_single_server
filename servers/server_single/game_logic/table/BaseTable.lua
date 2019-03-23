------------------------------------------------------
---! @file
---! @brief BaseTable
------------------------------------------------------
local BaseTable = class()

function BaseTable:ctor(tableId, gameId, gameType, gameRules)
	self.m_tableId   = tableId
	self.m_gameId    = gameId
	self.m_gameType  = gameType
	self.m_gameRules = gameRules

	self.m_players = {}

	self:_initStates()
end

function BaseTable:setOverCondition(overType, overVal)
	self.m_overType = overType
	self.m_overVal  = overVal
end

function BaseTable:_initStates()

	local TableStateFree = require("game_logic.state.TableStateFree")
	local TableStatePlay = require("game_logic.state.TableStatePlay")
	local TableStateWait = require("game_logic.state.TableStateWait")

	self.m_freeState = new(TableStateFree, self)
	self.m_waitState = new(TableStateWait, self)
	self.m_playState = new(TableStatePlay, self)

	self:changeFree()
end 


function BaseTable:getCurState()
	return self.m_curState
end 

function BaseTable:changeFree()
	self:_changeState(self.m_freeState)
end

function BaseTable:changePlay()
	self:_changeState(self.m_playState)
end

function BaseTable:changeWait()
	self:_changeState(self.m_waitState)
end

function BaseTable:_changeState(toState)
	if self.m_curState then 
		self.m_curState:onExit()
	end 
	self.m_curState = toState
	self.m_curState:onEnter()
end


function BaseTable:getBaseInfo()
	local info = {}
	info.game_id    = self.m_gameId
	info.game_type  = self.m_gameType
	info.game_rules = self.m_gameRules
	--info.players
	info.game_status = self.m_curState:getStatus()
	info.over_type   = self.m_overType	
	info.over_val    = self.m_overVal				
	--info.round_room_info
	--info.op_info
	--info.cards_infos
	info.room_id     = self.m_tableId
	return info
end

return BaseTable