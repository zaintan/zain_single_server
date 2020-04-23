--
local RuleMgr  = class()
--

local LOGTAG = "[RuleMgr]"

function RuleMgr:ctor(pTable)
	--
	self.m_pTable     = pTable
	self.m_gameRules  = self.m_pTable:getGameBaseInfo().game_rules

 	self:_parse()
end

function RuleMgr:dump()
	-- body
end
function RuleMgr:_parse(  )
	--
	Log.dump(LOGTAG, self.m_gameRules)
	--解析玩家人数 固定 or 少人
	self:_parseUserNum()
	--解析结束条件 固定局数/圈数/分数...
	self:_parseOverType()
	--
end

--[1,1000]
function RuleMgr:_isUserNumRule( ruleData )
	return ruleData.id >= 1 and ruleData.id <= 1000
end

--[1001,2000]
function RuleMgr:_isOverTypeRule( ruleData )
	return ruleData.id >= 1001 and ruleData.id <= 2000
end


function RuleMgr:_parseUserNum()

	local maxLimit       = nil

	for _,ruleData in pairs(self.m_gameRules) do
		if self:_isUserNumRule(ruleData) then 
			maxLimit = ruleData.value
		end
	end

	self.m_maxUserNum  = maxLimit
	--
	--self:callModule("user","setFixedUserNum", maxLimit) 
end

--解析结束条件 固定局数/圈数/分数...
function RuleMgr:_parseOverType()

	local over_type  = nil 
	local over_value = nil

	for _,ruleData in pairs(self.m_gameRules) do
		if self:_isOverTypeRule(ruleData) then 
			over_type  = ruleData.id 
			over_value = ruleData.value
		end
	end

	self.m_overType  = over_type
	self.m_overValue = over_value
	--
	--self:callModule("progress","setGameOverCondition", over_type, over_value)
end

function RuleMgr:_getRule( id )
	for _,v in ipairs(self.m_gameRules) do
		if v.id == id then
			return v
		end 
	end
	return nil
end

function RuleMgr:getOverType()
	return self.m_overType
end

function RuleMgr:getOverValue()
	return self.m_overValue
end

function RuleMgr:getMaxUserNum()
	return self.m_maxUserNum
end


return RuleMgr
