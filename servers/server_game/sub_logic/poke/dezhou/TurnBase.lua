--一轮操作
local TurnBase   = class()

function TurnBase:ctor(pRound)

	self.m_pRound = pRound
	self.m_pTable = pRound.m_pTable 
	-- body
	--self.m_chipPools      = {}--筹码池 分池信息
	self.m_startIndex     = nil;
	self.m_lastRaiseIndex = nil;
end

--入场操作, 触发发牌 or 翻公牌
--通知操作玩家做决策
function TurnBase:execute()
	-- body
	--self:dealCards()
	--刷新状态  
	--通知玩家可以操作
end

function TurnBase:isOverTurn()
	-- body
end

function TurnBase:isOverRound()
	-- body
end

function TurnBase:turnNext()
	-- body
end

function TurnBase:dealCards()
	-- body
end

function TurnBase:onOpReq( uid , data )
	-- body
end

return TurnBase