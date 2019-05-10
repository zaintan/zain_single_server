------------------------------------------------------
---! @file
---! @brief AllocUser
------------------------------------------------------

local AllocUser = class()

AllocUser.DEFAULT_MAX_LIMIT = 10

function AllocUser:init(uid)
	self.m_nUid = uid
	self.m_tCreatedTableIds = {}
	self.m_nJoinTableId     = nil
	return self
end

function AllocUser:canRecover()
	if #self.m_tCreatedTableIds <= 0 and self.m_nJoinTableId == nil then 
		return true 
	end 
	return false
end

function AllocUser:canCreateTable()
	local limit = skynet.getenv("create_limit") or AllocUser.DEFAULT_MAX_LIMIT
	return #self.m_tCreatedTableIds < tonumber(limit)
end

function AllocUser:canJoinTable()
	return self.m_nJoinTableId == nil
end

function AllocUser:addCreatedTable(table_id)
	if self:_hadTable(table_id) then 
		return 
	end 
	table.insert(self.m_tCreatedTableIds, table_id)
end

function AllocUser:joinTable(table_id)
	self.m_nJoinTableId     = table_id
end

function AllocUser:removeCreatedTable(table_id)
	for i,v in ipairs(self.m_tCreatedTableIds) do
		if v == table_id then 
			table.remove(self.m_tCreatedTableIds,i)
			return true
		end 
	end
	return false
end

function AllocUser:_hadTable(table_id)
	for _,v in ipairs(self.m_tCreatedTableIds) do
		if v == table_id then 
			return true
		end 
	end
	return false
end

function AllocUser:getTableId()
	return self.m_nJoinTableId
end

return AllocUser