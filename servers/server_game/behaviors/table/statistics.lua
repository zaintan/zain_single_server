--大局统计信息
local Super           = require("behaviors.behavior")
local statistics      = class(Super)

statistics.EXPORTED_METHODS = {
    "setGameFinishReason",
    "getCurScoreBySeat",
}

function statistics:_pre_bind_(...)

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
	return 0
end


return statistics
