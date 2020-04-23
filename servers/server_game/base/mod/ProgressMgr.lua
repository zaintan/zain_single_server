local ProgressMgr  = class()
--
local LOGTAG = "[ProgressMgr]"

function ProgressMgr:ctor(pTable, overType, overValue)
	self.m_pTable     = pTable
	
	self.m_data = {
		over_type     = overType;
		over_value    = overValue;
		current_value = 0;
	}
end 

function ProgressMgr:addProgress( value )
	self.m_data.current_value = self.m_data.current_value + value
end

function ProgressMgr:getProgressInfo()
	return self.m_data
end

function ProgressMgr:isOver()
	return self.m_data.current_value >= self.m_data.over_value
end

return ProgressMgr