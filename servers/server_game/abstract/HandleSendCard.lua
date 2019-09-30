------------------------------------------------------
---! @file
---! @brief HandleSendCard
------------------------------------------------------
local Super            = require("abstract.BaseHandle")
local HandleSendCard  = class(Super)

function HandleSendCard:onEnter(seat_index, isGangDraw)
	Super.onEnter(self)
	--重置玩家状态 所有操作
	self.m_pTable:resetOperates()
	--当前操作者
	self.seat_index = seat_index
	--发牌
	local card = self.m_pTable:getCard(1)
	if not card then 
		Log.i("","发牌失败！牌池没有牌了, 流局")
		self.m_pState:handleRoundOver()
		return
	end 
	self.send_card = card
	--广播发牌
	self.m_pTable:dispatchCard(self.seat_index, card)
	--判断当前操作者是否可以操作
	local checkWiks   = {const.Action.AN_GANG, const.Action.ZHI_GANG, const.Action.ZI_MO };
	local playerCards = self.m_pTable:getPlayerCards(self.seat_index) 
	
	--有无操作 均会刷新通知玩家状态
	local hasOp = self.m_pTable:checkPlayerOperates(self.seat_index, playerCards,checkWiks, card, self.seat_index, true)
	
	if hasOp then 
		self.m_pState:changeHandle(const.GameHandler.WAI_OPERATE,  self.send_card , self.seat_index, self.seat_index)
	else 
		self.m_pState:changeHandle(const.GameHandler.OUT_CARD, self.seat_index)
	end 
end



return HandleSendCard