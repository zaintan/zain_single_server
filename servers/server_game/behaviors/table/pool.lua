--牌池
local Super           = require("behaviors.behavior")
local pool            = class(Super)

pool.EXPORTED_METHODS = {
    "getCard",
    "resetPool",
    "getRemainCardNum",
    "getTotalCardNum",
    "getUsedCardHeadCount",
    "getUsedCardTailCount",     
}
--default
pool.cards_cfg = {
	0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9,
	0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9,
	0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9,
	0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9,

	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,

	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,		
}


function pool:_on_bind_()
	self.m_cards  = self.cards_cfg
	self.m_pFirst = 1
	self.m_pLast  = #self.m_cards
end

function pool:_clear_()
	Super._clear_(self)
	self.m_cards  = nil

	self.m_pFirst = 0
	self.m_pLast  = 0
end

--num:card_num
function pool:getCard(num, bBack)
	local n = num or 1

	if self:getRemainCardNum() < num then 
		return false
	end  

	if num == 1 then 
		local ret_card = nil
		if bBack then 
			ret_card = self.m_cards[self.m_pLast]
			self.m_pLast = self.m_pLast - 1
		else 
			ret_card = self.m_cards[self.m_pFirst]
			self.m_pFirst = self.m_pFirst + 1
		end 
		return ret_card
	end 

	local ret = {}
	if bBack then 
		for i=1,n do
			table.insert(ret, self.m_cards[self.m_pLast])
			self.m_pLast = self.m_pLast - 1
		end
	else
		for i=1,n do
			table.insert(ret, self.m_cards[self.m_pFirst])
			self.m_pFirst = self.m_pFirst + 1
		end		
	end 
	return ret
end

function pool:_shuffle()
	for i = #self.m_cards,1,-1 do
		local index = math.random(i)--[1,i]
		local temp          = self.m_cards[i]
		self.m_cards[i]     = self.m_cards[index]
		self.m_cards[index] = temp
	end
end

function pool:resetPool()
	self:_shuffle()
	self.m_pFirst = 1
	self.m_pLast  = #self.m_cards

	return self.target_
end

function pool:getRemainCardNum()
	return self.m_pLast - self.m_pFirst + 1
end

function pool:getTotalCardNum()
	return #self.m_cards
end

function pool:getUsedCardHeadCount()
	return self.m_pFirst - 1
end

function pool:getUsedCardTailCount()
	return #self.m_cards - self.m_pLast
end

return pool