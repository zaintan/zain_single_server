------------------------------------------------------
---! @file
---! @brief GameStatistics 牌局统计信息
------------------------------------------------------
local GameStatistics = class()

function GameStatistics:ctor(pTable)
	self.m_pTable = pTable
	--self.m_player_num  = player_num
	self._info  = {}
	self._scores = {}
end


function GameStatistics:addSpecailCount(seat_index, id, add_num)
	if not self._info[seat_index] then 
		self._info[seat_index] = {}
	end 
	local tmp = self._info[seat_index]
	if not tmp[id] then 
		tmp[id] = 0
	end 
	tmp[id] = tmp[id] + add_num
end

function GameStatistics:addScore(seat_index, add_score)
	if not self._scores[seat_index] then 
		self._scores[seat_index] = 0
	end 

	self._scores[seat_index] = self._scores[seat_index] + add_score
end

function GameStatistics:getInfo()
	local player_num = self.m_pTable:getCurPlayerNum()
	local ret = {}
	for i=1,player_num do
		local seat_index = i - 1
		ret[i] = {}
		ret[i].total_scores   = self._scores[seat_index] or 0
		ret[i].special_counts = {}
		for k,v in pairs(self._info[seat_index] or {}) do
		 	table.insert(ret[i].special_counts, {id = k; count = v;})
		end 
	end
	return ret
end

return GameStatistics

