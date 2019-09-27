--管理玩家的操作信息
local Super           = require("behaviors.behavior")
local operates        = class(Super)

local HuLib            = require("thirdlib.mj.base_split")
 local tblHelper       = require "TableHelper"

operates.EXPORTED_METHODS = {
    "resetOperates",
    "checkPlayerOperates",


    "changePlayerStatus",
    "getPlayerStatus",
    "getAllStatuses",
}

function operates:_on_bind_()
	self.m_statuses = {}

	self.m_operateActions = {}
	local num = self.target_:getCurPlayerNum()
	for seat = 0,num-1 do
		self.m_operateActions[seat + 1] = {}
		self.m_statuses[seat + 1]       = const.PlayerStatus.NONE
	end

	self.m_curId = 0
end

function operates:resetOperates()
	for i=1,#self.m_operateActions do
		self.m_operateActions[i] = {}
		self.m_statuses[i] = const.PlayerStatus.NONE
	end
end

function operates:_addAction( seat, weave_kind, center_card, provider, public)
	local action = {}
	action.weave_kind     = weave_kind
	action.center_card    = center_card
	action.provide_player = provider
	action.public_card    = public

	table.insert(self.m_operateActions[seat+1],  action)
end

function operates:_checkChi(...)
	return
end

function operates:_checkPeng(seat, playerCards ,card, provider)
	if seat == provider then 
		return
	end 
	--
	local num = playerCards:getCardNumInHands(card)
	if num >= 2 then 
		self:_addAction(seat, const.Action.PENG, card, provider, 1)
	end 
end

function operates:_checkAnGang(seat, playerCards ,card, provider)
	--
	local cards = playerCards:getMoreThanNumCardsInHand(4)
	for _,card in ipairs(cards) do
		self:_addAction(seat, const.Action.AN_GANG, card, provider, 1)
	end
end

function operates:_checkPengGang(seat, playerCards ,card, provider)
	if seat == provider then 
		return
	end 
	--
	local num = playerCards:getCardNumInHands(card)
	if num >= 3 then 
		self:_addAction(seat, const.Action.PENG_GANG, card, provider, 1)
	end 
end

function operates:_checkBuGang(seat, playerCards ,card, provider)
	--
	local num = playerCards:getCardNumInHands(card)
	if num >= 4 then 
		self:_addAction(seat, const.Action.ZHI_GANG, card, provider, 1)
	end 
end


function operates:__translateHuArgs(hands)
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


function operates:_checkHu(seat, playerCards ,card, provider)
	if seat == provider then 
		return
	end 

	local cards = tblHelper.cloneArray(playerCards:getHands())
	table.insert(cards, card)
	local trans_cards  = self:__translateHuArgs(cards)

	if HuLib.get_hu_info(trans_cards) then 
		self:_addAction(seat, const.Action.JIE_PAO, card, provider, 1)
	end
end


function operates:_checkZimo(seat, playerCards ,card, provider)
	--
	local trans_cards  = self:__translateHuArgs(playerCards:getHands())
	--
	if HuLib.get_hu_info(trans_cards) then 
		self:_addAction(seat, const.Action.ZI_MO, card, provider, 1)
	end
end

local kCheckFuncsMap = {
	[const.Action.LEFT_EAT]   = operates._checkChi;
	[const.Action.RIGHT_EAT]  = operates._checkChi;
	[const.Action.CENTER_EAT] = operates._checkChi;
	[const.Action.PENG]       = operates._checkPeng;
	[const.Action.AN_GANG]    = operates._checkAnGang;
	[const.Action.JIE_PAO]    = operates._checkHu;
	[const.Action.ZI_MO]      = operates._checkZimo;
	[const.Action.PENG_GANG]  = operates._checkPengGang;
	[const.Action.ZHI_GANG]   = operates._checkBuGang;		
};

function operates:checkPlayerOperates(seat, playerCards, wiks, card, provider, addNull)
	Log.i("","checkPlayerOperates seat=%d,card=%d,provider=%d,addNull=%s",seat,card,provider,tostring(addNull))
	Log.dump("playerCards", playerCards)
	Log.dump("wiks",wiks)
	-- 检查是否有操作
	for _,wik in ipairs(wiks) do
		local func = kCheckFuncsMap[wik]	
		if func then 
			func(self,seat, playerCards ,card, provider)
		else
			Log.e("","invalid weave_kind = %d",wik)
		end 
	end
	--添加过操作
	if addNull and #self.m_operateActions[seat + 1] > 0 then 
		self:_addAction(seat, const.Action.NULL)
	end 
	-- 改变玩家操作状态
	if #self.m_operateActions[seat + 1] > 0 then 
		self:changePlayerStatus(seat, const.PlayerStatus.OPERATE_CARD)
	else 
		self:changePlayerStatus(seat, const.PlayerStatus.OUT_CARD)
	end 	
	-- 广播通知客户端刷新
	self:_broadcastPlayerStatus()
end

function operates:_broadcastPlayerStatus()
	for i,_ in ipairs(self.m_statuses) do
		local seat = i - 1
		self:_pushPlayerStatus(seat)
	end
end

function operates:_pushPlayerStatus( seat )
	
	local msg_data = {}
	msg_data.player_status      = self:getPlayerStatus(seat)
	msg_data.pointed_seat_index = self.target_:getCurSeat()
	msg_data.op_info = {} 
	msg_data.op_info.weaves     = self.m_operateActions[seat + 1]

	self.target_:sendMsgBySeat(msg.NameToId.PlayerStatusPush,msg_data,seat)
end


function operates:changePlayerStatus(seat, toStatus)
	self.m_statuses[seat + 1] = toStatus
end

function operates:getPlayerStatus(seat)
	return self.m_statuses[seat + 1]
end

function operates:getAllStatuses()
	return self.m_statuses
end


function operates:reconnectPush(uid)
	local seat     = self.target_:getPlayerByUid(uid).seat
	self:_pushPlayerStatus(seat)
end

return operates
