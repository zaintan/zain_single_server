--大局统计信息
local Super           = require("behaviors.behavior")
local statistics      = class(Super)

statistics.EXPORTED_METHODS = {
    "setGameFinishReason",
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

function statistics:setGameFinishReason(reason)
	self.m_gameFinishReason = reason
end

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
	local num = self.target_:getCurPlayerNum()
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
	--
	local msg_data = {}
	msg_data.game_finish_reason = self.m_gameFinishReason
	--
	local countIds = {
		const.SpecialCountType.ZI_MO, 
		const.SpecialCountType.JIE_PAO,
		const.SpecialCountType.FANG_PAO,
		const.SpecialCountType.AN_GANG,
		const.SpecialCountType.PENG_GANG,
		const.SpecialCountType.ZHI_GANG
	}

	local player_num = self.target_:getCurPlayerNum()
	local player_infos = {}
	for i=1,player_num do
		local item = {}
		item.total_scores = self.m_scores[i] or 0
		item.special_counts = {}
		for _,id in ipairs(countIds) do
			table.insert(item.special_counts, { id = id; count = self.m_gameInfo[i][id] or 0 })
		end
		player_infos[i] = item
	end
	--
	msg_data.player_infos = player_infos

	return msg_data
end

return statistics
