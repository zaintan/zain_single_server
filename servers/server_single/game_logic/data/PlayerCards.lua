------------------------------------------------------
---! @file
---! @brief PlayerCards
------------------------------------------------------

local PlayerCards = class()

local LOGTAG = "PlayerCards"

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

function PlayerCards:removeHandCard(card, count)
	local del_count = count or 1
	for i=1,del_count do
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

function PlayerCards:hasHandCard( card )
	for i,v in ipairs(self.m_hands) do
		if v == card then 
			return true
		end 
	end
end

function PlayerCards:addWeave(kind,center,public,provide)
	local weave = {}
	weave.weave_kind     = kind
	weave.center_card    = center
	weave.public_card    = public
	weave.provide_player = provide
	table.insert(self.m_weaves, weave)
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

--------------------------------------------------------------------

function PlayerCards:_checkAnGang(provide)
	local cardsCountMap = {}
	for i,v in ipairs(self.m_hands) do
		local num = cardsCountMap[v] or 0
		cardsCountMap[v] = num + 1
	end	
	for card,num in pairs(cardsCountMap) do
		if num == 4 then 
			self:_addAction(const.GameAction.AN_GANG,card,0,provide)
		end 
	end
end

function PlayerCards:_checkPengGang(provide,outCard)
	local num = 0
	for i,v in ipairs(self.m_hands) do
		if v == outCard then 
			num = num + 1
		end 
	end	
	if num >= 3 then 
		self:_addAction(const.GameAction.PENG_GANG,outCard,1,provide)
	end 
end

function PlayerCards:_checkBuGang(provide)
	for _,card in ipairs(self.m_hands) do
		for i,v in ipairs(self.m_weaves) do
			if v.center_card == card and v.weave_kind == const.GameAction.PENG then 
				self:_addAction(const.GameAction.BU_GANG,card,1,provide)
			end 
		end
	end
end

function PlayerCards:_checkChi(provide,outCard)
	return false
end

function PlayerCards:_checkPeng(provide,outCard)
	local num = 0
	for i,v in ipairs(self.m_hands) do
		if v == outCard then 
			num = num + 1
		end 
	end	
	if num >= 2 then 
		self:_addAction(const.GameAction.PENG,outCard,1,provide)
	end 
end

function PlayerCards:_checkHu(provide,outCard)
	return 
end

function PlayerCards:_checkZimo(provide)

end 

function PlayerCards:getActions()
	return self.m_actions
end

function PlayerCards:hasAction( action )
	for i,v in ipairs(self.m_actions) do
		if v.weave_kind == action.weave_kind and 
			v.center_card == action.center_card then 
			return v
		end 
	end
	return nil
end

function PlayerCards:cleanActions()
	self.m_actions = {}
end

function PlayerCards:_addAction(kind,center,public,provide)
	local action = {}
	action.weave_kind     = kind
	action.center_card    = center
	action.public_card    = public
	action.provide_player = provide
	table.insert(self.m_actions, action)
end

local kCheckFuncsMap = {
	--[const.GameAction.NULL] = 
	[const.GameAction.LEFT_EAT]   = PlayerCards._checkChi;
	[const.GameAction.RIGHT_EAT]  = PlayerCards._checkChi;
	[const.GameAction.CENTER_EAT] = PlayerCards._checkChi;
	[const.GameAction.PENG]       = PlayerCards._checkPeng;
	[const.GameAction.AN_GANG]    = PlayerCards._checkAnGang;
	[const.GameAction.JIE_PAO]    = PlayerCards._checkHu;
	[const.GameAction.ZI_MO]      = PlayerCards._checkZimo;
	[const.GameAction.PENG_GANG]  = PlayerCards._checkPengGang;
	[const.GameAction.BU_GANG]    = PlayerCards._checkBuGang;		
};

--weave_kind
function PlayerCards:checkAddAction(wiks, card, addNull, provide)
	Log.e(LOGTAG,"checkAddAction provide_player = %s, card = %s,wiks: ",tostring(provide), tostring(card))
	Log.dump(LOGTAG, wiks)

	for _,wik in ipairs(wiks) do
		local func = kCheckFuncsMap[wik]	
		if func then 
			func(self, provide, card)
		else
			Log.e(LOGTAG,"invalid weave_kind = %d",wik)
		end 
	end
	if addNull and #self.m_actions > 0 then 
		self:_addAction(const.GameAction.NULL)
	end 
	return self.m_actions
end
--------------------------------------------------------------------


return PlayerCards