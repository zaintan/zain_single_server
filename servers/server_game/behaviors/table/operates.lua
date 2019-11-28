--管理玩家的操作信息
local Super           = require("behaviors.behavior")
local operates        = class(Super)

local HuLib            = require("thirdlib.mj.base_split")
 local tblHelper       = require "TableHelper"

operates.EXPORTED_METHODS = {
    "resetOperates",--重置操作
    "checkPlayerOperates",--检查玩家是否有操作 并广播
    "getPlayerOperateStatus",--获取玩法 当前操作的状态 0无操作 1有操作,等待中 2有操作,已操作
    "recordPlayerOperate",--记录玩家当前做的操作
    "hasMorePriorityUndoOp",--有无 高优先级的操作 处于未操作状态
    "executeHighestPriorityOp",--执行当前最高优先级的生效操作


    "changePlayerStatus",--改变玩家状态
    "getPlayerStatus",--获取玩家状态
    "getAllStatuses",--获取所有玩家状态
    "broadcastPlayersStatus",
    "pushPlayerStatus",
}

function operates:_on_bind_()
	--玩家状态 k:seat+1  v:const.PlayerStatus.NONE,const.PlayerStatus.OPERATE_CARD,const.PlayerStatus.OUT_CARD
	self.m_statuses = {}
	--玩家操作 k:seat+1  v:{{ weave_kind=,center_card=,provide_player=,public_card=};...}
	self.m_operateActions = {}
	--玩家操作结果 k:seat+1  v:{weave_kind=,center_card=}//client operate_req
	self.m_operateResults = {}

	--local num = self.target_:getCurPlayerNum()
	local num = self.target_:getMaxPlayerNum()
	for seat = 0,num-1 do
		self.m_operateActions[seat + 1] = {}
		self.m_statuses[seat + 1]       = const.PlayerStatus.NONE
	end

	self.m_operateId = 0
end

local kGameActionPriMap = {
	[const.Action.NULL]       = 0;
	[const.Action.LEFT_EAT]   = 1;
	[const.Action.RIGHT_EAT]  = 1;
	[const.Action.CENTER_EAT] = 1;
	[const.Action.PENG]       = 2;
	[const.Action.AN_GANG]    = 2;
	[const.Action.JIE_PAO]    = 3;
	[const.Action.ZI_MO]      = 3;
	[const.Action.PENG_GANG]  = 2;
	[const.Action.ZHI_GANG]    = 2;		
}



function operates:resetOperates()
	for i=1,#self.m_operateActions do
		self.m_operateActions[i] = {}
		self.m_statuses[i] = const.PlayerStatus.NONE
		self.m_operateResults[i] = nil
	end
end


--这里检测条件要变更 操作吗
function operates:getPlayerOperateStatus( seat, weave )
	--Log.dump("self.m_operateActions", self.m_operateActions)
	--Log.dump("weave", weave)
	--Log.dump("self.m_operateResults", self.m_operateResults)

	for _,v in pairs(self.m_operateActions[seat+1] or {}) do
		--Log.d("cmp","v.weave_kind = %s, weave.weave_kind=%s",tostring(v.weave_kind),tostring(weave.weave_kind))
		--Log.d("cmp","v.center_card = %s, weave.center_card=%s",tostring(v.center_card),tostring(weave.center_card))
		--Log.d("cmp","v.provide_player = %s, weave.provide_player=%s",tostring(v.provide_player),tostring(weave.provide_player))
		
		if (v.weave_kind == const.Action.NULL and v.weave_kind == weave.weave_kind) or
			(v.weave_kind == weave.weave_kind and v.center_card == weave.center_card) then 
			--有操作
			if self.m_operateResults[seat+1] then 
				--已经操作过了
				return 2
			end	
			return 1
		end 		
	end
	--无此操作
	return 0
end

function operates:recordPlayerOperate(seat_index, data)
	--Log.d("recordPlayerOperate","seat_index = %d, data.provide_player=%s",seat_index,tostring(data.provide_player))
	--Log.dump("recordPlayerOperate", data)
	--provide_player
	local item = {}
	item.weave_kind = data.weave_kind
	item.provide_player = data.provide_player
	item.center_card = data.center_card
	Log.dump("item",item)
	self.m_operateResults[seat_index + 1] = item
end

function operates:_getHighestUndoOp()
	local op = 0
	for i,actions in pairs(self.m_operateActions) do
		if actions ~= nil and #actions > 0 then 
			if not self.m_operateResults[i] then 
				for _,v in ipairs(actions) do
					local cur_op = kGameActionPriMap[v.weave_kind]
					op = math.max(op, cur_op)
				end
			end 
		end 	
	end	
	return op
end

function operates:_getHighestDoneOp()
	local op = -1
	for _,result in pairs(self.m_operateResults) do
		op = math.max(op, kGameActionPriMap[result.weave_kind])
	end
	return op
end


function operates:hasMorePriorityUndoOp(seat_index, data)

	local maxUndo = self:_getHighestUndoOp()
	local maxDone = self:_getHighestDoneOp()

	if maxUndo > maxDone then 
		return true
	end 

	if maxUndo == maxDone and maxUndo ~= 0 then 
		return true
	end 

	return false
end
--广播生效操作
function operates:executeHighestPriorityOp()
	local maxDone = self:_getHighestDoneOp()
	if maxDone == 0 then --过的  不需要广播通知
		return 
	end 
	--已经删除的牌，防止一炮多响的时候 多次删除弃牌 
	local deledCards = {}

	local effect_seat,effect_data
	--provide_player
	for i,result in pairs(self.m_operateResults) do
		local seat = i - 1
		--同级操作 都生效;--麻将除了一炮多响  其他不可能会有同优先级的操作
		if kGameActionPriMap[result.weave_kind] == maxDone then 
			self:_executeAction(seat, result, deledCards)
			--
			effect_seat = seat
			effect_data = result
		end  
	end
	self:resetOperates()

	return effect_seat, effect_data
end

local function _isInArray( arr, v )
	for _,c in ipairs(arr) do
		if c == v then 
			return true
		end 
	end
	return false
end

function operates:_broadcastExecuteAction(seat, action)
	--广播玩家执行了操作
	local msg_data = {
		seat_index     = seat;
		weave_kind     = action.weave_kind;
		provide_player = action.provide_player;
		center_card    = action.center_card;
	}
	self.target_:broadcastMsg(msg.NameToId.OperateCardPush, msg_data)
end 

function operates:_checkRemoveDiscard( deledCards,  card,  providerPlayerCards )
	if not _isInArray(deledCards, card) then 
		providerPlayerCards:removeDiscard()
		table.insert(deledCards, waitRemoveCard)
	end 
end

function operates:_executeGuo(  )
	-- body
end

function operates:_executeChi( seat, action, deledCards )
	local providerPlayerCards = self.target_:getPlayerCards(action.provide_player)
	local operaterPlayerCards = self.target_:getPlayerCards(seat)

	self:_checkRemoveDiscard(deledCards, action.center_card, providerPlayerCards)

	if action.weave_kind == const.Action.LEFT_EAT then
		operaterPlayerCards:removeHandCard({action.center_card + 1 , action.center_card + 2})
		operaterPlayerCards:addWeave(action.weave_kind,action.center_card, 1, action.provide_player)
	elseif action.weave_kind == const.Action.CENTER_EAT then 
		operaterPlayerCards:removeHandCard({action.center_card - 1 , action.center_card + 1})
		operaterPlayerCards:addWeave(action.weave_kind,action.center_card, 1, action.provide_player)
	else
		operaterPlayerCards:removeHandCard({action.center_card - 1 , action.center_card - 2})
		operaterPlayerCards:addWeave(action.weave_kind,action.center_card, 1, action.provide_player)
	end
	--广播执行操作
	self:_broadcastExecuteAction(seat, action)
	--刷新提供者的弃牌
	self.target_:broadcastPlayerCards(false,false,true,{action.provide_player})
	--刷新操作者的手牌
	self.target_:broadcastPlayerCards(true,true,false,{seat})
end

function operates:_executePeng( seat, action, deledCards )
	local providerPlayerCards = self.target_:getPlayerCards(action.provide_player)
	local operaterPlayerCards = self.target_:getPlayerCards(seat)

	self:_checkRemoveDiscard(deledCards, action.center_card, providerPlayerCards)	
	
	operaterPlayerCards:removeHandCard({action.center_card, action.center_card})
	operaterPlayerCards:addWeave(action.weave_kind,action.center_card, 1, action.provide_player)

	--广播执行操作
	self:_broadcastExecuteAction(seat, action)
	--刷新提供者的弃牌
	self.target_:broadcastPlayerCards(false,false,true,{action.provide_player})
	--刷新操作者的手牌
	self.target_:broadcastPlayerCards(true,true,false,{seat})
end

function operates:_executeAnGang( seat, action, deledCards )
	
	local providerPlayerCards = self.target_:getPlayerCards(action.provide_player)
	local operaterPlayerCards = self.target_:getPlayerCards(seat)

	operaterPlayerCards:removeHandCard({action.center_card, action.center_card, action.center_card, action.center_card})
	operaterPlayerCards:addWeave(action.weave_kind,action.center_card, 1, action.provide_player)

	--广播执行操作
	self:_broadcastExecuteAction(seat, action)
	--刷新操作者的手牌
	self.target_:broadcastPlayerCards(true,true,false,{seat})
end

function operates:_executeHu( seat, action, deledCards )
	local providerPlayerCards = self.target_:getPlayerCards(action.provide_player)
	local operaterPlayerCards = self.target_:getPlayerCards(seat)

	self:_checkRemoveDiscard(deledCards, action.center_card, providerPlayerCards)	
	
	operaterPlayerCards:addHu(action.weave_kind, action.center_card, action.provide_player)

	--广播执行操作
	self:_broadcastExecuteAction(seat, action)
	--刷新提供者的弃牌
	self.target_:broadcastPlayerCards(false,false,true,{action.provide_player})
	--刷新操作者的手牌 
	--self.target_:broadcastPlayerCards(true,true,false,{seat})
end

function operates:_executeZimo( seat, action, deledCards )
	local providerPlayerCards = self.target_:getPlayerCards(action.provide_player)
	local operaterPlayerCards = self.target_:getPlayerCards(seat)

	self:_checkRemoveDiscard(deledCards, action.center_card, providerPlayerCards)	

	operaterPlayerCards:addHu(action.weave_kind, action.center_card, action.provide_player)
	--广播执行操作
	self:_broadcastExecuteAction(seat, action)
	--刷新操作者的手牌 
	--self.target_:broadcastPlayerCards(true,true,false,{seat})	
end

function operates:_executePengGang( seat, action, deledCards )
	local providerPlayerCards = self.target_:getPlayerCards(action.provide_player)
	local operaterPlayerCards = self.target_:getPlayerCards(seat)

	self:_checkRemoveDiscard(deledCards, action.center_card, providerPlayerCards)	
	
	operaterPlayerCards:removeHandCard({action.center_card, action.center_card, action.center_card})
	operaterPlayerCards:addWeave(action.weave_kind,action.center_card, 1, action.provide_player)

	--广播执行操作
	self:_broadcastExecuteAction(seat, action)
	--刷新提供者的弃牌
	self.target_:broadcastPlayerCards(false,false,true,{action.provide_player})
	--刷新操作者的手牌
	self.target_:broadcastPlayerCards(true,true,false,{seat})
end

function operates:_executeBuGang( seat, action, deledCards )
	local providerPlayerCards = self.target_:getPlayerCards(action.provide_player)
	local operaterPlayerCards = self.target_:getPlayerCards(seat)

	operaterPlayerCards:removeHandCard({action.center_card})
	--changeWeave
	local weave = operaterPlayerCards:getWeave({weave_kind=const.Action.PENG,center_card=action.center_card})
	if not weave then 
		Log.e(LOGTAG,"补杠失败!找不到碰center_card=%d",action.center_card)
	end 
	weave.weave_kind = const.Action.ZHI_GANG	
	--
	--广播执行操作
	self:_broadcastExecuteAction(seat, action)
	--刷新操作者的手牌
	self.target_:broadcastPlayerCards(true,true,false,{seat})
end

local kExecuteActionMap = {
	[const.Action.NULL]       = operates._executeGuo;
	[const.Action.LEFT_EAT]   = operates._executeChi;
	[const.Action.RIGHT_EAT]  = operates._executeChi;
	[const.Action.CENTER_EAT] = operates._executeChi;
	[const.Action.PENG]       = operates._executePeng;
	[const.Action.AN_GANG]    = operates._executeAnGang;
	[const.Action.JIE_PAO]    = operates._executeHu;
	[const.Action.ZI_MO]      = operates._executeZimo;
	[const.Action.PENG_GANG]  = operates._executePengGang;
	[const.Action.ZHI_GANG]   = operates._executeBuGang;		
}

function operates:_executeAction(seat, action, deledCards)
	--1.删除提供者的弃牌
	--2.删除操作者的手牌
	--3.添加组合牌
	--4.广播
	local func = kExecuteActionMap[action.weave_kind]
	if func then 
		func(self, seat, action, deledCards )
	else
		Log.e("","未定义的weave_kind=%d",action.weave_kind)
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

function operates:_checkChi(seat, playerCards ,card, provider)
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
	if self.target_:getRemainCardNum() <= 0 then 
		return
	end 
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
	if self.target_:getRemainCardNum() <= 0 then 
		return
	end 	
	--
	local num = playerCards:getCardNumInHands(card)
	if num >= 3 then 
		self:_addAction(seat, const.Action.PENG_GANG, card, provider, 1)
	end 
end

function operates:_checkBuGang(seat, playerCards ,card, provider)
	if self.target_:getRemainCardNum() <= 0 then 
		return
	end 
	
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
	--Log.i("","checkPlayerOperates seat=%d,card=%d,provider=%d,addNull=%s",seat,card,provider,tostring(addNull))
	--Log.dump("playerCards", playerCards)
	--Log.dump("wiks",wiks)
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
	local hasOp = false
	if #self.m_operateActions[seat + 1] > 0 then 
		self:changePlayerStatus(seat, const.PlayerStatus.OPERATE_CARD)
		hasOp = true
	else 
		self:changePlayerStatus(seat, const.PlayerStatus.OUT_CARD)
	end 	
	--
	return hasOp
end

function operates:broadcastPlayersStatus()
	for i,_ in ipairs(self.m_statuses) do
		local seat = i - 1
		self:pushPlayerStatus(seat)
	end
end

function operates:pushPlayerStatus( seat )
	
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
	--有操作 且没有已经操作过
	if self:getPlayerStatus(seat) == const.PlayerStatus.OPERATE_CARD
		and self.m_operateResults[seat+1] == nil then 

		self:pushPlayerStatus(seat)
	end 
end

return operates
