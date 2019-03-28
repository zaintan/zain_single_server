------------------------------------------------------
---! @file
---! @brief HandlerOutCard
------------------------------------------------------
local Super = require("game_logic.handler.BaseHandler")
local HandlerOutCard = class(Super)

function HandlerOutCard:ctor()
	self.m_status = const.GameHandler.OUT_CARD

	self.seat_index = -1
	self.out_card   = 0
end

function HandlerOutCard:onEnter(seat_index, out_card)
	------------------------------
	self.seat_index = seat_index
	self.out_card   = out_card
	-- body
	self.m_pState:resetPlayerStatuses()
	self.m_pTable:cleanActions()

	local hasOneAction = false
	--self.m_pState:changePlayerStatus(seat_index, const.PlayerStatus.NULL)
	for seat = 0,self.m_pTable:getCurPlayerNum() - 1 do
		if seat ~= seat_index then 
			local playerCards = self.m_pTable:getPlayerCards(seat)
			local actions = playerCards:checkAddAction(const.GameAction.PENG, const.GameAction.GANG, const.GameAction.JIE_PAO)
			
			local player_status = const.PlayerStatus.NULL
			if actions and #actions > 0 then 
				player_status = const.PlayerStatus.OPERATE

				hasOneAction  = true
			end 
			self.m_pState:changePlayerStatus(seat, player_status)
		end 
	end
	--广播刷新玩家状态
	self.m_pState:broadcastPlayerStatus()

	--没有任何人操作 切到下一个人发牌
	if not hasOneAction then 
		self.m_pState:turnNextSeat()
		self.m_pState:changeHandler(const.GameHandler.SEND_CARD)
	end 
end

function HandlerOutCard:_onOperateCardReq(msg_id, uid, data)
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

	if data.weave_kind == const.GameAction.PENG then
		--切handlerChiPeng
		self.m_pState:changeHandler(const.GameHandler.CHI_PENG)
	elseif data.weave_kind == const.GameAction.GANG then 
		--切handlerGang
		self.m_pState:changeHandler(const.GameHandler.GANG)
	elseif data.weave_kind == const.GameAction.JIE_PAO then 
		--切gameOver
		self.m_pState:gameRoundOver()
	end 
	--self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return true
end


return HandlerOutCard