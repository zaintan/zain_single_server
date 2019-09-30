------------------------------------------------------
---! @file
---! @brief HandleWaitOperate
------------------------------------------------------
local Super              = require("abstract.BaseHandle")
local HandleWaitOperate  = class(Super)

local LOGTAG = "WaitOpHandle"


function HandleWaitOperate:onEnter(card, provider, wait_seat)
	Super.onEnter(self)
	--广播玩家状态
	self.m_pTable:broadcastPlayersStatus()
	--
end

function HandleWaitOperate:onOperateCardReq( uid, msg_id, data )
	Log.d(LOGTAG, "_onOperateCardReq msg_id=%d,uid=%d",msg_id,uid)
	Log.dump(LOGTAG, data)


	local ret_msg_id    = msg_id + msg.ResponseBase
	local seat_index    = self.m_pTable:getPlayerBySeat(uid)
	local player_status = self.m_pTable:getPlayerStatus(seat_index)

	--不在操作状态
	if player_status ~= const.PlayerStatus.OPERATE_CARD then 
		Log.d(LOGTAG, "player_status=%d",player_status)
		self.m_pTable:sendMsg(ret_msg_id, {status = -3;}, uid)
		return false
	end

	--不存在的操作
	local player_op_status = self.m_pTable:getPlayerOperateStatus(seat_index, data)
	if player_op_status == 0 then 
		Log.d(LOGTAG, "不存在的操作")
		self.m_pTable:sendMsg(ret_msg_id, {status = -4;}, uid)
		return false
	elseif player_op_status == 2 then --已经操作过了
		Log.d(LOGTAG, "已经操作过了")
		self.m_pTable:sendMsg(ret_msg_id, {status = -5;}, uid)
		return false		
	end 

	--
	self.m_pTable:recordPlayerOperate(seat_index, data)
	--等待更高优先级的操作
	if self.m_pTable:hasMorePriorityUndoOp(seat_index, data) then 
		Log.d(LOGTAG, "还需等待其他玩家操作")
		self.m_pTable:sendMsg(msg_id+msg.ResponseBase, {status = 2;},uid)
		return false
	end 
	--回复操作成功
	self.m_pTable:sendMsg(msg_id+msg.ResponseBase, {status = 0;},uid)
	
	--没有更高友需等待的操作了  取当前最高操作作为生效操作 --广播生效操作
	local effect_seat,effect_data = self.m_pTable:executeHighestPriorityOp()
	--胡牌
	if self:_isHu(effect_data.weave_kind) then
		
		self.m_pState:handleRoundOver()

	elseif self:_isChiPeng(effect_data.weave_kind) then 
		
		self.m_pState:changeHandle(const.GameHandler.OUT_CARD, effect_seat)

	elseif self:_isGang(effect_data.weave_kind) then 

		self.m_pState:changeHandle(const.GameHandler.SEND_CARD, effect_seat , true)

	elseif effect_data.weave_kind == const.Action.NULL then 
		
		self.m_pState:changeHandle(const.GameHandler.SEND_CARD, self.m_pTable:turnSeat())

	else 
		Log.e(LOGTAG, "不识别的操作:weave_kind=%d",effect_data.weave_kind) 
	end 

	return true
end


function HandleWaitOperate:_isIn(kind, arr)
	for _,v in ipairs(arr) do
		if v == kind then 
			return true
		end 
	end
	return false
end

function HandleWaitOperate:_isChiPeng(kind)
	return self:_isIn(kind, {const.Action.LEFT_EAT,const.Action.RIGHT_EAT,const.Action.CENTER_EAT,const.Action.PENG})
end

function HandleWaitOperate:_isHu( kind )
	return self:_isIn(kind, {const.Action.JIE_PAO,const.Action.ZI_MO})
end

function HandleWaitOperate:_isGang( kind )
	return self:_isIn(kind, {const.Action.ZHI_GANG,const.Action.PENG_GANG,const.Action.AN_GANG})
end

return HandleWaitOperate