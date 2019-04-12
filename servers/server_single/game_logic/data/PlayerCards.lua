------------------------------------------------------
---! @file
---! @brief PlayerCards
------------------------------------------------------

local PlayerCards = class()

local LOGTAG = "PlayerCards"

local HuLib  = require("game_logic.hulib.mj.base_split")

function PlayerCards:ctor()
	self:reset()
end

function PlayerCards:reset()
	self.m_hands    = {}
	self.m_discards = {}
	self.m_weaves   = {}
	self:cleanActions()
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
	if #self.m_discards > 0 then 
		table.remove(self.m_discards)
		return true
	end 
	return false
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
	Log.d(LOGTAG,"kind=%d,center=%d,public=%d,provide=%d",kind,center,public,provide)
	Log.dump(LOGTAG,self.m_weaves)
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
			self:_addAction(const.Action.AN_GANG,card,0,provide)
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
		self:_addAction(const.Action.PENG_GANG,outCard,1,provide)
	end 
end

function PlayerCards:_checkBuGang(provide)
	for _,card in ipairs(self.m_hands) do
		for i,v in ipairs(self.m_weaves) do
			if v.center_card == card and v.weave_kind == const.Action.PENG then 
				self:_addAction(const.Action.ZHI_GANG,card,1,provide)
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
		self:_addAction(const.Action.PENG,outCard,1,provide)
	end 
end

function PlayerCards:__translateHuArgs(hands)
	local cards = {
		0,0,0,0,0,0,0,0,0,	-- 1-9万--1,9,  
		0,0,0,0,0,0,0,0,0,	-- 1-9筒--10,18, 
		0,0,0,0,0,0,0,0,0,	-- 1-9条--19,27,  
		--0,0,0,0,0,0,0		-- 东南西北中发白
	}	
	
	for _,card in ipairs(hands) do
		local color   = math.modf(card/16);
		local val     = card - color*16
		local trans_v = color*9+val
		cards[trans_v] = cards[trans_v] + 1
	end
	--28,29,30,31,   
	--32,33,34
	return cards
end

function PlayerCards:_checkHu(provide,outCard)
	table.insert(self.m_hands, outCard)
	local args  = self:__translateHuArgs(self.m_hands)
	table.remove(self.m_hands)

	if HuLib.get_hu_info(args) then 
		self:_addAction(const.Action.JIE_PAO,outCard,0,provide)
	end 
end

function PlayerCards:_checkZimo(provide,sendCard)
	local args  = self:__translateHuArgs(self.m_hands)
	if HuLib.get_hu_info(args) then 
		self:_addAction(const.Action.ZI_MO,sendCard,0,provide)
	end 
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
	--[const.Action.NULL] = 
	[const.Action.LEFT_EAT]   = PlayerCards._checkChi;
	[const.Action.RIGHT_EAT]  = PlayerCards._checkChi;
	[const.Action.CENTER_EAT] = PlayerCards._checkChi;
	[const.Action.PENG]       = PlayerCards._checkPeng;
	[const.Action.AN_GANG]    = PlayerCards._checkAnGang;
	[const.Action.JIE_PAO]    = PlayerCards._checkHu;
	[const.Action.ZI_MO]      = PlayerCards._checkZimo;
	[const.Action.PENG_GANG]  = PlayerCards._checkPengGang;
	[const.Action.ZHI_GANG]    = PlayerCards._checkBuGang;		
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
		self:_addAction(const.Action.NULL)
	end 
	return self.m_actions
end
--------------------------------------------------------------------


return PlayerCards