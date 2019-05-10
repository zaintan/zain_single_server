------------------------------------------------------
---! @file桌子id池
---! @brief TableIdPool
------------------------------------------------------
local TableIdPool = class()

function TableIdPool:init()
	self.m_ids  = {}
	self.m_used = {}
	self.m_used_num  = 0
	self.m_cur_index = 1
	for i=100000,999999 do
		table.insert(self.m_ids, i)
	end
	--random
	local randomIndex = nil
	local tmpVal      = nil
	for i=#self.m_ids,2,-1 do
		randomIndex = math.random(1, i-1)
		tmpVal = self.m_ids[i]
		self.m_ids[i] = self.m_ids[randomIndex]
		self.m_ids[randomIndex] = tmpVal
	end
	return self
end

--可用区域[head,tail]
function TableIdPool:allocId()
	local count = 0
	while(true) do 
		if self.m_cur_index >= #self.m_ids then 
			self.m_cur_index = 0
		end 
		self.m_cur_index = self.m_cur_index + 1
		
		local id = self.m_ids[self.m_cur_index]
		if not self.m_used[id] then --没有使用
			self.m_used[id] = true
			self.m_used_num = self.m_used_num + 1
			return id
		end 
		-------------------------------------------------------------------------------
		count = count + 1
		if count > 100000 then 
			Log.e("TableIdPool","获取空余房间号遍历超过100000次 可能死循环!!!!")
			return nil
		end 
		-------------------------------------------------------------------------------
	end 
end

function TableIdPool:recoverId( table_id )
	if self.m_used[table_id] then 
		self.m_used[table_id] = nil
		self.m_used_num = self.m_used_num - 1
		return true
	end 
	return false
end

return TableIdPool