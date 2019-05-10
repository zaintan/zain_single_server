------------------------------------------------------
---! @file
---! @brief HandlerOutCard
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerOutCard = class(Super)

local LOGTAG = "HDOutCard"

function HandlerOutCard:ctor()
	self.m_status = const.GameHandler.OUT_CARD

	self.seat_index = -1
	self.out_card   = 0
end

--添加
function HandlerOutCard:_addOp(seat, actions)
	--添加记录好判断优先级
	local ops = { wiks = {}; op_req = nil;}
	self.operate[seat] = ops
	
	for _,v in ipairs(actions) do
		table.insert(ops.wiks, v.weave_kind)
	end
end

function HandlerOutCard:_doOp(seat, reqData )
	local ops = self.operate[seat]
	if ops then 
		ops.op_req = reqData
		return true
	end 
	return false
end

local kGameActionPriMap = {
	[const.Action.NULL]       = 0;
	[const.Action.LEFT_EAT]   = 1;
	[const.Action.RIGHT_EAT]  = 1;
	[const.Action.CENTER_EAT] = 1;
	[const.Action.PENG]       = 2;
	[const.Action.AN_GANG]    = 2;
	[const.Action.JIE_PAO]    = 3;
	[const.Action.ZI_MO]      = 3;
	[const.Action.PENG_GANG]  = 2;
	[const.Action.ZHI_GANG]    = 2;		
}

function HandlerOutCard:_hasMorePriUndoOp()
	local highestUndo = 0
	for seat,op in pairs(self.operate) do
		--没有做操作
		if not op.op_req then 
			for _,weave_kind in ipairs(op.wiks) do
				if kGameActionPriMap[weave_kind] > highestUndo then 
					highestUndo = kGameActionPriMap[weave_kind]
				end 
			end
		end 	
	end
	----------------------------------------------
	local do_seat,do_data = self:_getHighestOp()
	if do_data and highestUndo > kGameActionPriMap[do_data.weave_kind] then 
		return true
	end
	return false
end

function HandlerOutCard:_getHighestOp()
	local highestUndo = 0
	local ret_seat,ret_data
	for seat,op in pairs(self.operate) do
		if op.op_req then 
			local weave_kind = op.op_req.weave_kind
			if kGameActionPriMap[weave_kind] > highestUndo then 
				highestUndo = kGameActionPriMap[weave_kind]
				ret_seat = seat
				ret_data = op.op_req
			end 
		end 	
	end
	return ret_seat, ret_data
end


function HandlerOutCard:_cleanOp()
	self.operate = {}
end


function HandlerOutCard:_checkOthersAction( checkWiks, out_card )
	local hasAction = false
	for seat = 0,self.m_pTable:getCurPlayerNum() - 1 do
		if seat ~= self.seat_index then 
			local playerCards = self.m_pTable:getPlayerCards(seat)
			local actions = playerCards:checkAddAction(checkWiks, out_card, true, self.seat_index)
			
			local player_status = const.PlayerStatus.NONE
			if actions and #actions > 0 then 
				player_status = const.PlayerStatus.OPERATE_CARD
				hasAction  = true
				self:_addOp(seat, actions)
			end 
			self.m_pState:changePlayerStatus(seat, player_status)
		end 
	end
	return hasAction
end

function HandlerOutCard:onEnter(seat_index, out_card)
	------------------------------
	self.seat_index = seat_index
	self.out_card   = out_card
	--重置操作记录
	self:_cleanOp()
	-- body
	self.m_pState:resetPlayerStatuses()
	self.m_pTable:cleanActions()

	
	--self.m_pState:changePlayerStatus(seat_index, const.PlayerStatus.NONE)

	local checkWiks = {const.Action.PENG, const.Action.PENG_GANG, const.Action.JIE_PAO};
	local hasOneAction = self:_checkOthersAction(checkWiks, out_card)
	Log.d(LOGTAG,"seat = %d,出牌:0x%x ,其他人有操作:%s",seat_index,out_card,tostring(hasOneAction))
	--广播刷新玩家状态
	self.m_pState:broadcastPlayerStatus()

	--没有任何人操作 切到下一个人发牌
	if not hasOneAction then 
		self.m_pState:turnSeat()
		self.m_pState:changeHandler(const.GameHandler.SEND_CARD)
	end 
end


--要判断操作优先级
function HandlerOutCard:_onOperateCardReq(msg_id, uid, data)
	Log.d(LOGTAG, "_onOperateCardReq msg_id=%d,uid=%d",msg_id,uid)
	Log.dump(LOGTAG, data)
	local ret_msg_id = msg_id + msg.ResponseBase
	local seat_index = self.m_pTable:getPlayerSeat(uid)

	local player_status = self.m_pState:getPlayerStatus(seat_index)
	--不在操作状态
	if player_status ~= const.PlayerStatus.OPERATE_CARD then 
		Log.d(LOGTAG, "player_status=%d",player_status)
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -3;})
		return false
	end

	--不存在的操作
	local playerCards = self.m_pTable:getPlayerCards(seat_index)
	if not playerCards:hasAction(data) then 
		Log.d(LOGTAG, "not has Action")
		self.m_pTable:sendMsg(uid, ret_msg_id, {status = -4;})
		return false
	end 

	self:_doOp(seat_index, data)
	--等待更高优先级的操作
	if self:_hasMorePriUndoOp() then 
		Log.d(LOGTAG, "wait more pri player op")
		self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = 2;})
		return false
	end 
	--没有更高友需等待的操作了  取当前最高操作作为生效操作
	local effect_seat,effect_data = self:_getHighestOp()
	--
	if data.weave_kind == const.Action.PENG then
		--切handlerChiPeng
		self.m_pState:changeHandler(const.GameHandler.CHI_PENG,effect_seat, effect_data, self.seat_index)
	elseif data.weave_kind == const.Action.PENG_GANG then 
		--切handlerGang
		self.m_pState:changeHandler(const.GameHandler.GANG, effect_seat, effect_data, self.seat_index)
	elseif data.weave_kind == const.Action.JIE_PAO then 
		--切gameOver
		self.m_pState:gameRoundOver(const.RoundFinishReason.NORMAL,effect_seat, self.seat_index)
	elseif data.weave_kind == const.Action.NULL then--过
		self.m_pState:turnSeat()
		self.m_pState:changeHandler(const.GameHandler.SEND_CARD)
	else 
		Log.e(LOGTAG, "invalid weave_kind = %d",data.weave_kind)
	end 
	--self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return true
end


return HandlerOutCard