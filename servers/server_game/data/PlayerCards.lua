------------------------------------------------------
---! @file
---! @brief PlayerCards
------------------------------------------------------

local PlayerCards = class()

function PlayerCards:ctor()
	self:reset()
end

function PlayerCards:reset()
	self.m_hands    = {}
	self.m_discards = {}
	self.m_weaves   = {}

	self.hu_info    = {}
end

function PlayerCards:getHands()
	return self.m_hands
end

function PlayerCards:getWeaves()
	return self.m_weaves
end

function PlayerCards:getDiscards()
	return self.m_discards
end

function PlayerCards:dealCards( cards )
	self.m_hands = {}
	for i,v in ipairs(cards) do
		table.insert(self.m_hands, v)
	end

	table.sort(self.m_hands, function ( a,b )
		return a < b
	end)
end

function PlayerCards:drawCard(card)
	table.insert(self.m_hands, card)

	table.sort(self.m_hands, function ( a,b )
		return a < b
	end)	
end

function PlayerCards:outCard(card)
	for index, v in ipairs(self.m_hands) do
		if v == card then 
			table.remove(self.m_hands, index)
			table.insert(self.m_discards, card)
			return card
		end 
	end
	return nil
end

function PlayerCards:removeDiscard()
	local ret = self.m_discards[#self.m_discards]
	if not ret then 
		Log.e("","删除牌错误，弃牌区已经没有牌了!")
	end 
	table.remove(self.m_discards)
	return ret
end

function PlayerCards:removeHandCard(cards)
	for i=1,#cards do
		local card = cards[i]
		--防止死循環
		local notFound = true
		for index,v in ipairs(self.m_hands) do
			if v == card then 
				table.remove(self.m_hands, index)
				notFound = false
				break
			end 
		end
		--防止死循環
		if notFound then 
			return false
		end 
	end
	return true
end 

function PlayerCards:getCardNumInHands( card )
	local count = 0
	for i,v in ipairs(self.m_hands) do
		if v == card then 
			count = count + 1
		end 
	end
	return count
end

function PlayerCards:getMoreThanNumCardsInHand(num)
	local cardsCountMap = {}
	for i,v in ipairs(self.m_hands) do
		local num = cardsCountMap[v] or 0
		cardsCountMap[v] = num + 1
	end	
	--
	local ret = {}
	for card,n in pairs(cardsCountMap) do
		if n >= num then 
			table.insert(ret, card)
		end 
	end	
	return ret
end



function PlayerCards:addWeave(kind,center,public,provide)
	local weave = {}
	weave.weave_kind     = kind
	weave.center_card    = center
	weave.public_card    = public
	weave.provide_player = provide
	table.insert(self.m_weaves, weave)
	Log.d("","kind=%d,center=%d,public=%d,provide=%d",kind,center,public,provide)
	Log.dump("",self.m_weaves)
end

function PlayerCards:getWeave( data  )
	for i,v in ipairs(self.m_weaves) do
		if v.weave_kind == data.weave_kind and 
			v.center_card == data.center_card then 
			return v
		end 
	end
	return nil
end

function PlayerCards:addHu( weave_kind, card, provide )
	self.hu_info.weave_kind  = weave_kind
	self.hu_info.center_card = card
	self.hu_info.provide_player = provide
end

function PlayerCards:getHuInfo()
	return self.hu_info
end

return PlayerCards