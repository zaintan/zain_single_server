------------------------------------------------------
---! @file
---! @brief BaseTable
------------------------------------------------------
local skynet = require "skynet"

local BaseTable = class()

local TableUserInfo = require("game_logic.data.TableUserInfo")
local PlayerCards   = require("game_logic.data.PlayerCards")

local LOGTAG = "BaseTable"

function BaseTable:ctor(tableId, gameId, gameType, gameRules)
	self.m_tableId   = tableId
	self.m_gameId    = gameId
	self.m_gameType  = gameType
	self.m_gameRules = gameRules

	self.m_maxPlayerNum = 4
	self.m_curPlayerNum = 0
	--
	self:_initGameRules()
	self:_initCards()

	self:_initPlayers()
	self:_initStates()
end

function BaseTable:setOverCondition(overType, overVal)
	self.m_overType = overType
	self.m_overVal  = overVal
end

function BaseTable:_initGameRules()
	for i,v in ipairs(self.m_gameRules) do
		if v.id == const.GameRule.PLAYER_COUNT then 
			self.m_maxPlayerNum = v.value
		end 
	end
end

function BaseTable:_initCards()
	local CardsPool = require("game_logic.CardsPool")
	self.m_cardsPool = new(CardsPool,self.m_gameRules)
end

function BaseTable:_initStates()

	local TableStateFree = require("game_logic.state.TableStateFree")
	local TableStatePlay = require("game_logic.state.TableStatePlay")
	local TableStateWait = require("game_logic.state.TableStateWait")

	self.m_freeState = new(TableStateFree, self)
	self.m_waitState = new(TableStateWait, self)
	self.m_playState = new(TableStatePlay, self)

	self:changeFree()
end 

function BaseTable:_initPlayers()
	self.m_players = {}

	self.m_playersCards = {}
end

function BaseTable:isInTable( uid )
	return self.m_players[uid] ~= nil
end

function BaseTable:addPlayer(agent, uid, data)
	local player = self.m_players[uid]
	if not player then 
		player = new(TableUserInfo)
		self.m_players[uid] = player
		player:init(agent,data,self.m_curPlayerNum)
		self.m_playersCards[self.m_curPlayerNum] = new(PlayerCards)
		
		self.m_curPlayerNum = self.m_curPlayerNum + 1
		return true,player
	end
	return false,player
end

function BaseTable:getPlayerSeat( uid )
	local player = self.m_players[uid]
	if player then 
		return player.seat_index
	end 
	return -1
end
--[[
function BaseTable:_getPlayerBySeatIndex(seat_index)
	for k,v in pairs(self.m_players) do
		if v.seat_index == seat_index then 
			return v
		end 
	end
end
]]

function BaseTable:cleanActions(seat)
	if seat then 
		self.m_playersCards[seat]:cleanActions()
		return
	end 
	for k,v in pairs(self.m_playersCards) do
		v:cleanActions()
	end
end


function BaseTable:getPlayers()
	return self.m_players
end

function BaseTable:getPlayerCards(seat_index)
	return self.m_playersCards[seat_index]
end

function BaseTable:dealPlayersCards(start_seat_index, num)
	for i=1,self.m_curPlayerNum do
		local seat_index = (start_seat_index + i-1)%self.m_curPlayerNum
		local cards = self.m_cardsPool:dealCards(num)
		self.m_playersCards[seat_index]:dealCards(cards)

		--Log.d(LOGTAG, "####seat_index = %d",seat_index)
		--Log.dump(LOGTAG,self.m_playersCards[seat_index]:getHands())		
	end
	--广播发牌消息
	local hasHand = true
	self.m_curState:broadcastRoomCards(hasHand)
end


function BaseTable:drawCard(seat_index)
	local card = self.m_cardsPool:drawCard()
	if card == 0 then 
		return false
	end 

	self.m_playersCards[seat_index]:drawCard(card)
	--广播抓牌消息
	for id,player in pairs(self.m_players) do
		local msg_data = {
			dispatch_card = seat_index == player.seat_index and card or -1;
			seat_index    = seat_index;
		};
		self:sendMsg(player.user_id, const.MsgId.DispatchCardPush , msg_data )
	end	
	return true,card
end

function BaseTable:outCard(uid,card)
	local player     = self.m_players[uid]
	local seat_index = player.seat_index
	self.m_playersCards[seat_index]:outCard(card)	
	--response
	local rspData = {
		status     = 0
	}
	self:sendMsg(player.user_id, const.MsgId.OutCardRsp , rspData )

	--broadcast
	local msg_data = {
		seat_index = seat_index;
		out_card   = card;
	}
	self:broadcastMsg(const.MsgId.OutCardRsp, msg_data)

	--刷新出牌玩家的手牌--
	local hasHand = true
	self.m_curState:broadcastPlayerCards(msg_data.seat_index, hasHand)
end

function BaseTable:getRandBanker()
	--[1,n]
	return math.random(self.m_curPlayerNum) - 1
end

function BaseTable:getPlayer(uid)
	return self.m_players[uid]
end


function BaseTable:getCurState()
	return self.m_curState
end 

function BaseTable:changeFree()
	self:_changeState(self.m_freeState)
end

function BaseTable:changePlay()
	self:_changeState(self.m_playState)
end

function BaseTable:changeWait()
	self:_changeState(self.m_waitState)
end

function BaseTable:_changeState(toState)
	if self.m_curState then 
		self.m_curState:onExit()
	end 
	self.m_curState = toState
	self.m_curState:onEnter()
end


function BaseTable:getBaseInfo()
	local info = {}
	info.game_id     = self.m_gameId
	info.game_type   = self.m_gameType
	info.game_rules  = self.m_gameRules
	info.players     = self:getPlayerInfo()
	info.game_status = self.m_curState:getStatus()
	info.over_type   = self.m_overType	
	info.over_val    = self.m_overVal				
	--info.round_room_info
	--info.op_info
	--info.cards_infos
	info.room_id     = self.m_tableId
	return info
end

function BaseTable:getPlayerInfo()
	local players = {}
	for _,player in pairs(self.m_players) do
		players[player.seat_index + 1] = player:getProtoInfo()
	end
	return players
end

function BaseTable:isFull()
	return self.m_curPlayerNum == self.m_maxPlayerNum
end

function BaseTable:isAllReady()
	for k,v in pairs(self.m_players) do
		if v.ready == false then 
			return false
		end 
	end
	return true
end

function BaseTable:getCardsPool()
	return self.m_cardsPool
end


function BaseTable:sendMsg( uid, msg_id, msg_data )
	pcall(skynet.call, self.m_players[uid].agent , "lua", "sendMsg", msg_id, msg_data)
end

function BaseTable:broadcastMsg( msg_id, msg_data, except_uid )
	for uid,player in pairs(self.m_players) do
		if not(except_uid and uid == except_uid) then
			pcall(skynet.call, player.agent , "lua", "sendMsg", msg_id, msg_data)
		end   
	end
end



return BaseTable