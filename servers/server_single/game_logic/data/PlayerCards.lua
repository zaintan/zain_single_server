------------------------------------------------------
---! @file
---! @brief PlayerCards
------------------------------------------------------

local PlayerCards = class()


function PlayerCards:ctor()
	self.m_hands    = {}
	self.m_discards = {}
	self.m_weaves   = {}
end

function PlayerCards:getHands()
	return self.m_hands
end

function PlayerCards:getWeaves()
	return {}
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
	if #self.m_discards > 0 then 
		table.remove(self.m_discards)
		return true
	end 
	return false
end

function PlayerCards:hasHandCard( card )
	for i,v in ipairs(self.m_hands) do
		if v == card then 
			return true
		end 
	end
end

--------------------------------------------------------------------
function PlayerCards:getActions()
	return nil
end

function PlayerCards:hasAction( action )
	return false
end

function PlayerCards:cleanActions()
	self.m_actions = {}
end

function PlayerCards:checkAddAction(weave_kind)
	return self.m_actions
end

function PlayerCards:checkAnGang()
	return false
end

function PlayerCards:checkPengGang(outCard)
	return false
end

function PlayerCards:checkBuGang(sendCard)
	return false
end

function PlayerCards:checkChi(outCard)
	return false
end

function PlayerCards:checkPeng(outCard)
	return false
end

function PlayerCards:checkHu(outCard)
	return false
end
--------------------------------------------------------------------


return PlayerCards