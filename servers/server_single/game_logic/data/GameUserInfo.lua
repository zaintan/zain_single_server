------------------------------------------------------
---! @file
---! @brief GameUserInfo
------------------------------------------------------

local GameUserInfo = class()

GameUserInfo.MAX_CREATE_TABLE_NUM = 10

function GameUserInfo:init(uid)
	self.m_nUid = uid
	self.m_tCreatedTableIds = {}
	self.m_nJoinTableId     = nil
end

function GameUserInfo:canRecover()
	if #self.m_tCreatedTableIds <= 0 and self.m_nJoinTableId == nil then 
		return true 
	end 
	return false
end


function GameUserInfo:canCreateTable()
	return #self.m_tCreatedTableIds < GameUserInfo.MAX_CREATE_TABLE_NUM
end

function GameUserInfo:canJoinTable()
	return self.m_nJoinTableId == nil
end

function GameUserInfo:addCreatedTable(table_id)
	if self:_hadTable(table_id) then 
		return 
	end 
	table.insert(self.m_tCreatedTableIds, table_id)
end

function GameUserInfo:joinTable(table_id)
	self.m_nJoinTableId     = table_id
end

function GameUserInfo:removeCreatedTable(table_id)
	for i,v in ipairs(self.m_tCreatedTableIds) do
		if v == table_id then 
			table.remove(self.m_tCreatedTableIds,i)
			return true
		end 
	end
	return false
end

function GameUserInfo:_hadTable(table_id)
	for i,v in ipairs(self.m_tCreatedTableIds) do
		if v == table_id then 
			return true
		end 
	end
	return false
end

function GameUserInfo:getTableId()
	return self.m_nJoinTableId
end



return GameUserInfo