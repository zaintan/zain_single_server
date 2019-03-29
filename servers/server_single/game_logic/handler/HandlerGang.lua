------------------------------------------------------
---! @file
---! @brief HandlerGang
------------------------------------------------------
local Super = require("game_logic.handler.HandlerOutCard")
local HandlerGang = class(Super)

local LOGTAG = "HandlerGang"

function HandlerGang:ctor(...)
	self.m_status = const.GameHandler.GANG
end

function HandlerGang:onEnter(seat_index, operReqData, provide_player)
	Log.d(LOGTAG,"seat_index=%d,provide_player=%d",seat_index,provide_player)
	Log.dump(LOGTAG,operReqData)
	--切换到操作玩家
	self.m_pState:turnSeat(seat_index)
	--清空玩家操作状态
	self.m_pState:resetPlayerStatuses()
	--
	--重置操作记录
	self:_cleanOp()

	local playerCards  = self.m_pTable:getPlayerCards(seat_index)

	local providerPlayerCards = self.m_pTable:getPlayerCards(provide_player)
	--清空操作信息
	self.m_pTable:cleanActions()
	--
	self.seat_index = seat_index
	self.card       = operReqData.center_card

	if operReqData.weave_kind == const.GameAction.PENG_GANG then 
		--删除提供牌玩家的弃牌区最後一張
		local succ = providerPlayerCards:removeDiscard()
		if not succ then 
			Log.e(LOGTAG,"刪除玩家丟弃牌失败!")
		end 
		--操作者 添加组合牌
		playerCards:addWeave(operReqData.weave_kind, operReqData.center_card, 1,provide_player)

	elseif operReqData.weave_kind == const.GameAction.BU_GANG then 
		--刪除手牌 一张
		local succ = providerPlayerCards:removeHandCard(operReqData.center_card, 1)
		if not succ then 
			Log.e(LOGTAG,"刪除玩家手牌失败!")
		end 	
		--操作者 变碰->杠
		local findData = {
			weave_kind  = const.GameAction.PENG;
			center_card = operReqData.center_card;
		}
		local weave = playerCards:getWeave(findData)
		if not weave then 
			Log.e(LOGTAG,"补杠失败!找不到碰")
		end 
		weave.weave_kind = const.GameAction.BU_GANG

	elseif operReqData.weave_kind == const.GameAction.AN_GANG then
		--刪除手牌
		local succ = providerPlayerCards:removeHandCard(operReqData.center_card, 4)
		if not succ then 
			Log.e(LOGTAG,"刪除玩家手牌失败!")
		end 
		--操作者 添加组合牌
		playerCards:addWeave(operReqData.weave_kind, operReqData.center_card, 0,provide_player)
	else 
		Log.e(LOGTAG,"invalid GANG weave_kind:%d",operReqData.weave_kind)
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

	local hasAction = false
	--补杠和碰杠 还需要判断是否其他玩家能抢杠胡
	if operReqData.weave_kind == const.GameAction.BU_GANG or 
		operReqData.weave_kind == const.GameAction.PENG_GANG then 
		
		hasAction = self:_checkOthersAction({const.GameAction.JIE_PAO}, operReqData.center_card)
	end 

	--广播刷新玩家状态
	self.m_pState:broadcastPlayerStatus()

	--没有任何人操作 发牌给杠的玩家
	if not hasAction then 
		self.m_pState:changeHandler(const.GameHandler.SEND_CARD)
	end	
	
end


--要判断操作优先级
function HandlerGang:_onOperateCardReq(msg_id, uid, data)
	Log.d(LOGTAG, "_onOperateCardReq msg_id=%d,uid=%d",msg_id,uid)
	
	local ret_msg_id = msg_id + const.MsgId.BaseResponse
	local seat_index = self.m_pTable:getPlayerSeat(uid)

	local player_status = self.m_pState:getPlayerStatus(seat_index)
	--不在操作状态
	if player_status ~= const.PlayerStatus.OPERATE then 
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -3;})
		return false
	end

	--不存在的操作
	local playerCards = self.m_pTable:getPlayerCards(seat_index)
	if not playerCards:hasAction(data) then 
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -4;})
		return false
	end 

	self:_doOp(seat_index, data)
	--等待更高优先级的操作
	if self:_hasMorePriUndoOp() then 
		self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = 2;})
		return
	end 
	--没有更高友需等待的操作了  取当前最高操作作为生效操作
	local effect_seat,effect_data = self:_getHighestOp()

	if data.weave_kind == const.GameAction.JIE_PAO then 
		--切gameOver
		self.m_pState:gameRoundOver()
	elseif data.weave_kind == const.GameAction.NULL then--过
		self.m_pState:changeHandler(const.GameHandler.SEND_CARD)
	else 
		Log.e(LOGTAG,"invalid weave_kind:%d",data.weave_kind)
	end 
	--self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return true
end

return HandlerGang