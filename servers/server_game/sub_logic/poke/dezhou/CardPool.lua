--牌池
--local Super     = require "abstract.BaseModule"
local CardPool  = class()

local LOGTAG = "[pool]"

--麻将标准 纯万条筒
local MJ_NORMAL = {
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

function pool:ctor(cards)
	self.m_cards  = cards or MJ_NORMAL
end

function pool:dump()
	-- body
end

--发放起手手牌
function pool:dealQiShouCards( eachUserNum )
	-- body
	local ret = {}
	for i=1,self.m_userNum do
		local oneHandCards = self:dispatchCardByHead(eachUserNum)
		table.insert(ret,  oneHandCards)
	end
	return ret
end

--头部发
function pool:dispatchCardByHead(num)
	if self:getRemainCardNum() < num then 
		return nil
	end 

	local ret = {}
	for i = 1,num do
		table.insert(ret, self.m_cards[self.m_pFirst])
		self.m_pFirst = self.m_pFirst + 1
	end		

	return ret
end

function pool:dispatchCardByTail()
	--
	if self:getRemainCardNum() < num then 
		return nil
	end 

	local ret = {}
	for i = 1,num do
		table.insert(ret, self.m_cards[self.m_pLast])
		self.m_pLast = self.m_pLast - 1
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

function pool:reset()
	self:_shuffle()
	--
	self:__debug_test()
	--
	self.m_pFirst = 1
	self.m_pLast  = #self.m_cards
	--
end


function pool:encode()
	return {
		total           = self:getTotalCardNum();
		remain          = self:getRemainCardNum();
		head_send_count = self:getUsedCardHeadCount();
		tail_send_count = self:getUsedCardTailCount();
	}
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


function CardPool:__debug_test()
	self.m_cards = {
	0x1, 0x1, 0x1, 0x5, 0x5, 0x5, 0x9, 0x9, 0x9,
	0x1, 0x2, 0x3, 0x4, 
	0x6, 0x6, 0x6, 0x6, 0x9, 0x3, 0x3, 0x3, 0x3, 
	0x7, 0x7, 0x7, 0x7, 
	0x4, 0x4, 0x4, 0x4, 0x4, 0x8, 0x8, 0x8, 0x8, 0x9,

	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,

	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29	
	}
end
return CardPool