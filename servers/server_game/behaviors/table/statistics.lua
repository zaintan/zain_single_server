--大局统计信息
local Super           = require("behaviors.behavior")
local statistics      = class(Super)

statistics.EXPORTED_METHODS = {
    --"setGameFinishReason",
    "getCurScoreBySeat",
    "getAllScores",
    "addScore",
    "addGameCount",
    "addRoundCount",
    "getGameOverInfo",
}

function statistics:_pre_bind_(...)
	self.m_scores    = {}
	self.m_roundInfo = {}
	self.m_gameInfo  = {}
end

function statistics:_on_bind_()
	-- body
end

function statistics:_clear_()
	self.target_  = nil
end

--function statistics:setGameFinishReason(reason)
--	self.m_gameFinishReason = reason
--end

function statistics:getCurScoreBySeat(seat)
	return self.m_scores[seat+1] or 0
end


function statistics:addScore(seat_index, add_score)
	if not self.m_scores[seat_index + 1] then 
		self.m_scores[seat_index + 1] = 0
	end 
	self.m_scores[seat_index + 1] = self.m_scores[seat_index + 1] + add_score
end

function statistics:getAllScores()
	local ret = {}
	local num = self.m_pTable:getCurPlayerNum()
	for seat = 0,num-1 do
		ret[seat+1] = self.m_scores[seat+1] or 0
	end
	return ret
end

function statistics:_addCount( target, seat, id , num )
	if not target[seat + 1] then 
		target[seat + 1] = {}
	end 

	if not target[seat + 1][id] then 
		target[seat+1][id] = 0
	end 

	target[seat+1][id] = target[seat+1][id] + num
end

function statistics:addGameCount( seat_index, id, add_num )
	self:_addCount(self.m_gameInfo, seat_index, id, add_num)
end

function statistics:addRoundCount( seat_index, id, add_num )
	self:_addCount(self.m_roundInfo, seat_index, id, add_num)
end

function statistics:getGameOverInfo()
--	local player_num = self.target_:getCurPlayerNum()
--	local ret = {}
--	for i=1,player_num do
--		local seat_index = i - 1
--		ret[i] = {}
--		ret[i].total_scores   = self._scores[seat_index] or 0
--		ret[i].special_counts = {}
--		for k,v in pairs(self._info[seat_index] or {}) do
--		 	table.insert(ret[i].special_counts, {id = k; count = v;})
--		end 
--	end
--	return ret
end

return statistics
