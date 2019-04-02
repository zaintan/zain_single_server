------------------------------------------------------
---! @file
---! @brief HandlerChiPeng
------------------------------------------------------
local Super = require("game_logic.handler.HandlerOutCard")
local HandlerChiPeng = class(Super)

local LOGTAG = "HandlerChiPeng"


function HandlerChiPeng:ctor(...)
	self.m_status = const.GameHandler.CHI_PENG
end


function HandlerChiPeng:_excuteChiPeng(operReqData,playerCards,providerPlayerCards,provide_player)
		--删除提供牌玩家的弃牌区最後一張
	local succ = providerPlayerCards:removeDiscard()
	if not succ then 
		Log.e(LOGTAG,"刪除玩家丟弃牌失败!")
	end 
	--刪除手牌
	local del_cards  = nil 
	local weave_kind = operReqData.weave_kind 

	if weave_kind == const.GameAction.LEFT_EAT then 
		del_cards = { operReqData.center_card + 1 , operReqData.center_card + 2}
	elseif weave_kind == const.GameAction.CENTER_EAT then 
		del_cards = { operReqData.center_card - 1 , operReqData.center_card + 1}
	elseif weave_kind == const.GameAction.RIGHT_EAT then 
		del_cards = { operReqData.center_card - 1 , operReqData.center_card - 2}
	else --peng
		del_cards = { operReqData.center_card, operReqData.center_card}
	end 

	local succ = playerCards:removeHandCard(del_cards)
	if not succ then 
		Log.e(LOGTAG,"刪除玩家手牌失败!")
	end 
	--操作者 添加组合牌
	playerCards:addWeave(operReqData.weave_kind, operReqData.center_card, 1,provide_player)
end


function HandlerChiPeng:onEnter(seat_index, operReqData, provide_player)
	Log.d(LOGTAG,"seat_index=%d,provide_player=%d",seat_index,provide_player)
	Log.dump(LOGTAG,operReqData)
	--切换到操作玩家
	self.m_pState:turnSeat(seat_index)
	--清空玩家操作状态
	self.m_pState:resetPlayerStatuses()
	--
	--重置操作记录
	self:_cleanOp()

	local playerCards         = self.m_pTable:getPlayerCards(seat_index)

	local providerPlayerCards = self.m_pTable:getPlayerCards(provide_player)
	--清空操作信息
	self.m_pTable:cleanActions()
	--

	if operReqData.weave_kind == const.GameAction.LEFT_EAT or 
	   operReqData.weave_kind == const.GameAction.RIGHT_EAT or 
	   operReqData.weave_kind == const.GameAction.CENTER_EAT or 
	   operReqData.weave_kind == const.GameAction.PENG  then 

	    self:_excuteChiPeng(operReqData,playerCards,providerPlayerCards,provide_player)
	else
		Log.e(LOGTAG,"invalid chipeng weave_kind:%d",operReqData.weave_kind)
	end 

	--刷新玩家手牌  只有提供者 与 操作者牌会变化
	local exceptSeats = {}
	for seat=0,self.m_pTable:getCurPlayerNum()-1 do
		if seat ~= seat_index and seat ~= provide_player then 
			table.insert(exceptSeats, seat)
		end 
	end
	local hasHand, hasWeave, hasDiscard = true, true, true
	self.m_pState:broadcastRoomCards(hasHand, hasWeave, hasDiscard, exceptSeats)

	--------------操作者切换到出牌状态
	self.m_pState:changePlayerStatus(seat_index, const.PlayerStatus.OUT_CARD)

	--广播刷新玩家状态
	self.m_pState:broadcastPlayerStatus()
end

function HandlerChiPeng:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function HandlerChiPeng:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end


return HandlerChiPeng