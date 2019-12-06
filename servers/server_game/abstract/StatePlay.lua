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

function StatePlay:handleRoundOver(reason, huPlayerSeat, effectOp)
	--
	local msg_data        = self.m_pTable:getShowAllCardsInfo()
	msg_data.game_status  = const.GameStatus.WAIT --self:getStatus()
	msg_data.final_scores = self.m_pTable:getAllScores()
	msg_data.round_finish_reason = reason
	msg_data.over_time    = os.time()

	msg_data.finish_desc  = {}
	msg_data.win_types    = {}
	--

	--胡牌了的
	if reason == const.RoundFinishReason.NORMAL then 

		table.insert(msg_data.win_types, effectOp.weave_kind)
		--
		local num = self.m_pTable:getCurPlayerNum()
		for seat=0,num-1 do
			msg_data.finish_desc[seat+1] = ""
		end
		--
		if effectOp.weave_kind == const.Action.ZI_MO then 
			msg_data.finish_desc[huPlayerSeat+1] = "自摸"
		else
			msg_data.finish_desc[huPlayerSeat+1] = "接炮"
			msg_data.finish_desc[effectOp.provide_player + 1] = "放炮"
		end 
	end
	--
	self.m_pTable:broadcastMsg(msg.NameToId.RoundFinishPush, msg_data)
	--
	if self.m_pTable:isLastRound() then 
		--game over
		self.m_pTable:destroy(const.GameFinishReason.NORMAL)
	else 
		self.m_pTable:changeState(const.GameStatus.WAIT)
	end 
end



return StatePlay