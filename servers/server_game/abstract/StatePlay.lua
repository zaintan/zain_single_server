------------------------------------------------------
---! @file
---! @brief StatePlay
------------------------------------------------------
local Super     = require("abstract.BaseState")
local StatePlay = class(Super)

--初始化顺序 从上到下
StatePlay._behavior_cfgs_ = {
    { path = "behaviors.state.handles"; },
}

function StatePlay:onInit()
	-- body
end

function StatePlay:onEnter()
	Log.i("","State:%d onEnter",self.m_status)
	--初始化玩家操作
	self.m_pTable:resetOperates()	
	--初始化玩家手牌
	self.m_pTable:resetCards()
	--重新洗牌
	self.m_pTable:resetPool()
	--round init
	self.m_pTable:startRound()
	--change DealCards
	self:changeHandle(const.GameHandler.DEAL_CARDS)
end

function StatePlay:onExit()
	Log.i("","State:%d onExit",self.m_status)
end


function StatePlay:onOutCardReq(...)
	return self:getCurHandle():onOutCardReq(...)
end

function StatePlay:onOperateCardReq(...)
	return self:getCurHandle():onOperateCardReq(...)
end

function StatePlay:handleRoundOver()
	-- body
end


return StatePlay