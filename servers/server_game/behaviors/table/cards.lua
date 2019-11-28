--管理玩家的手牌
local Super           = require("behaviors.behavior")
local cards           = class(Super)

local tblHelper       = require "TableHelper"
local PlayerCards     = require("data.PlayerCards")

cards.EXPORTED_METHODS = {
    "resetCards",
    "updateHandCards",
    "broadcastPlayerCards",
    "dispatchCard",
    "getPlayerCards",
    "outCard",
}


function cards:_on_bind_()
	self.m_cards = {}
	--local num = self.target_:getCurPlayerNum()
	local num = self.target_:getMaxPlayerNum()
	for seat = 0,num-1 do
		self.m_cards[seat + 1] = new(PlayerCards)
	end
end

function cards:resetCards()
	for i=1,#self.m_cards do
		self.m_cards[i]:reset()
	end
end

function cards:updateHandCards(seat, values)
	Log.i("","updateHandCards seat = %d",seat)
	Log.dump("",values)
	self.m_cards[seat+1]:dealCards(values)
end


function cards:_getPlayerHandsInfo(seat, showSeat)
	if seat == showSeat then 
		return self.m_cards[seat + 1]:getHands()
	end
	--
	local ret = {}
	for i,v in ipairs(self.m_cards[seat + 1]:getHands()) do
		table.insert(ret, -1)
	end
	return ret
end

--这里 不同麻将的 暗杠 要视情况处理下
function cards:_getPlayerWeavesInfo(seat, showSeat)
	return self.m_cards[seat + 1]:getWeaves()
end

function cards:_getPlayerDiscardsInfo(seat)
	return self.m_cards[seat + 1]:getDiscards()
end

function cards:_getAllPlayersCardsInfo(hasHand, hasWeave, hasDiscard,toSeat, containSeats)
	local data = { cards_infos = {};};

	for _,seat in ipairs(containSeats) do
		local item = {
			has_hands    = hasHand and true or false;
			has_weaves   = hasWeave and true or false;
			has_discards = hasDiscard and true or false;
			seat_index   = seat;		
		}
		if hasHand then 
			item.hands = self:_getPlayerHandsInfo(seat,  toSeat)
		end 
		if hasWeave then 
			item.weaves = self:_getPlayerWeavesInfo(seat,  toSeat)
		end 
		if hasDiscard then 
			item.discards = self:_getPlayerDiscardsInfo(seat)
		end 		
		table.insert(data.cards_infos,  item)
	end
	return data
end

function cards:_getAllSeats()
	local ret = {}
	for i=1,#self.m_cards do
		table.insert(ret, i-1)
	end	
	return ret
end

function cards:broadcastPlayerCards(hasHand, hasWeave, hasDiscard, containSeats)
	local cards_seats = containSeats-- or {}--不包括这些座位号玩家的牌
	 --no seat means all seats!
	if not cards_seats then
		cards_seats = self:_getAllSeats()
	end 
	--不包含任何人的牌 则不需要广播  无意义
	if tblHelper.isTableEmpty(cards_seats) then 
		Log.e("","maybe error!广播玩家的牌,不包含任何人的牌")
		return 
	end 
	--
	for i=1,#self.m_cards do 
		local seat     = i - 1
		local msg_data = self:_getAllPlayersCardsInfo(hasHand, hasWeave, hasDiscard, seat, cards_seats)
		self.target_:sendMsgBySeat(msg.NameToId.RoomCardsPush, msg_data, seat)
	end 
end


function cards:reconnectPush(uid)
	--self:broadcastPlayerCards(true, true, true)
	local seat     = self.target_:getPlayerByUid(uid).seat
	local msg_data = self:_getAllPlayersCardsInfo(true, true, true, seat, self:_getAllSeats())
	self.target_:sendMsg(msg.NameToId.RoomCardsPush, msg_data, uid)
end

function cards:dispatchCard(seat, card, isGangDraw )
	if type(card) == "number" then 
		self.m_cards[seat+1]:drawCard(card)
	--elseif type(card) == "table" then
	--	for _,v in ipairs(card) do
	--		table.insert(self.m_cards[seat].hands,  v)
	--	end
	else 
		Log.e("","maybe error! dispatchCard card type=%s", type(card)) 
	end 
	--广播抓牌消息
	self:_broadcastDispatchCard(seat, card, isGangDraw)
end

function cards:_broadcastDispatchCard(send_seat, card, isGangDraw)
	for i=1,#self.m_cards do 
		local seat     = i - 1
		local msg_data = {
			dispatch_card = seat == send_seat and card or -1;
			seat_index    = send_seat;	
			dispatch_type = isGangDraw and 2 or 1	--发牌类型：1：顺序发牌，2：尾部补牌	
		}
		self.target_:sendMsgBySeat(msg.NameToId.DispatchCardPush, msg_data, seat)
	end 
end

function cards:getPlayerCards(seat)
	return self.m_cards[seat+1]
end

function cards:outCard( seat, card )
	local ret = self:getPlayerCards(seat):outCard(card)
	if not ret then 
		Log.e("","may be error!从玩家seat=%d手牌中找不到该牌card=%d",seat,card)
	end 
	--成功的rsp可以省略
	self:_broadcastOutCard(seat, card)
end

function cards:_broadcastOutCard(seat, card)
	local msg_data = {
		seat_index = seat;
		out_card   = card;		
	}
	self.target_:broadcastMsg(msg.NameToId.OutCardPush, msg_data)
end

return cards

