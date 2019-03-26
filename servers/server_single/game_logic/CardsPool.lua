------------------------------------------------------
---! @file
---! @brief CardsPool
------------------------------------------------------

local CardsPool = class()

function CardsPool:ctor()
	self.m_cards = {}
	-- 万筒条
	for i=0,2 do
		for j=1,9 do
			table.insert(self.m_cards,i * 16 + j)
			table.insert(self.m_cards,i * 16 + j)
			table.insert(self.m_cards,i * 16 + j)
			table.insert(self.m_cards,i * 16 + j)
		end
	end
end

function CardsPool:_shuffle()
	for i = #self.m_cards,1,-1 do
		local index = math.random(i)--[1,i]
		local temp = self.m_cards[i]
		self.m_cards[i] = self.m_cards[index]
		self.m_cards[index] = temp
	end
end

--重新洗牌
function CardsPool:initRound()
	self:_shuffle()
	self.m_pFirst   = 1
	self.m_pLast    = #self.m_cards
end

function CardsPool:getRemainNum()
	return self.m_pLast - self.m_pFirst + 1
end

function CardsPool:getTotalNum()
	return #self.m_cards
end

function CardsPool:getHeadSendCount()
	return self.m_pFirst - 1
end

function CardsPool:getTailSendCount()
	return #self.m_cards - self.m_pFirst
end


function CardsPool:drawCard(isBack)
	--牌用完了
	if self.m_pFirst - self.m_pLast >  1 then 
		return 0
	end 
	local card = nil
	if isBack then 
		card = self.m_cards[self.m_pLast]
		self.m_pLast = self.m_pLast - 1
	else
		card = self.m_cards[self.m_pFirst]
		self.m_pFirst = self.m_pFirst + 1
	end 
	return card
end

function CardsPool:dealCards(num)
	local cards = {}
	for i=1,num do
		cards[i] = self:drawCard()
	end
	return cards
end

return CardsPool