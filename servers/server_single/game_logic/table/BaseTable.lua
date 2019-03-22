------------------------------------------------------
---! @file
---! @brief BaseTable
------------------------------------------------------
local BaseTable = class("BaseTable")

function BaseTable:ctor(gameId, gameType, gameRules)
	self.m_gameId    = gameId
	self.m_gameType  = gameType
	self.m_gameRules = gameRules


	self.m_players = {}
end

function BaseTable:setOverCondition(overType, overVal)
	self.m_overType = overType
	self.m_overVal  = overVal
end


return BaseTable