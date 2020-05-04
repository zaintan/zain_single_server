--一轮操作
local Super         = require "sub_logic.poke.dezhou.TurnBase"
local TurnPreFlop   = class(Super)
local LOGTAG        = "[TPreFlop]"

function TurnPreFlop:execute()
--	self.m_pRound = pRound
--	self.m_pTable = pRound.m_pTable 

	self.m_beginActionSeat = self.m_pRound:getNextOffsetSeatByIndex(3, 1);--大盲的下家先说话
	self.m_endActionSeat   = self.m_pRound.m_da_mang --没人加注之前,大盲最后说话
	self.m_curActionSeat   = self.m_beginActionSeat
	
	self:dealCards()
	--self.m_lastActionSeat  = self.m_pRound:getNextOffsetSeatByBanker(2);
	-- body
	--
	--刷新状态  
	--通知玩家可以操作
end

function TurnPreFlop:dealCards()
	--每人发两张手牌

	--初始化公牌 空

	--更新操作状态
end

function TurnPreFlop:onOpReq( uid , data )
	-- body
end

return TurnPreFlop