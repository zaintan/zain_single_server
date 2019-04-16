------------------------------------------------------
---! @file
---! @brief TableStateFree
------------------------------------------------------
local skynet = require "skynet"

local Super = require("game_logic.state.BaseTableState")
local TableStateFree = class(Super)

function TableStateFree:ctor(pTable)
	self.m_status = const.GameStatus.FREE
end

function TableStateFree:onEnter()
	-- body
end

function TableStateFree:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStateFree:join(agent, uid)
	-- body
	if self.m_pTable:isFull() then 
		return false,"房间已经满了!"
	end 

	if not self.m_pTable:isInTable(uid) then 
		local ok,data = pcall(skynet.call, ".LoginService", "lua", "query", uid)
		if ok and data then 
			local _,player = self.m_pTable:addPlayer(agent, uid, data)
			--广播通知其他玩家 有玩家加入
			local msg_data = {}
			msg_data.player = player:getProtoInfo()
			self.m_pTable:broadcastMsg(msg.NameToId.PlayerEnterPush, msg_data,uid)
			----------			
		else
			return false,"登录服查不到该玩家!"
		end	 
	end 
	local info = self.m_pTable:getBaseInfo()
	info.status = 1
	return true,info
end

--return JoinRoomResponse
function TableStateFree:reconnect(agent, uid)
	Super.reconnect(self, agent, uid)
	
	local info = self.m_pTable:getBaseInfo()
	info.status = 1
	return info
end


function TableStateFree:_onReadyReq(msg_id, uid, data)
	local player = self.m_pTable:getPlayer(uid)
	if not player then 
		self.m_pTable:sendMsg(uid, msg.NameToId.ReadyResponse, {status = -1;})
		return false
	end 

	player.ready = data.ready
	self.m_pTable:sendMsg(uid, msg.NameToId.ReadyResponse, {status = 0;ready = data.ready;})
	
	local push_data = {
		ready_infos = {{seat_index = player.seat_index;ready = data.ready;}}
	}
	self.m_pTable:broadcastMsg(msg.NameToId.ReadyPush, push_data, uid)
	
	if self.m_pTable:isFull() and self.m_pTable:isAllReady() then 
		self.m_pTable:changePlay()
	end 
	return true
end

function TableStateFree:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;status_tip = "牌局还未开始,无法出牌!";})
end

function TableStateFree:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;status_tip = "牌局还未开始,无法操作牌!";})
end

--处理Free状态的
function TableStateFree:_onPlayerExitReq(msg_id, uid, data)
	local player = self.m_pTable:getPlayer(uid)
	if not player then 
		--玩家不在这个房间 回复解散失败
		self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -2;})
		return false
	end 
	--通知GameServers
	pcall(skynet.call, ".GameService", "lua","leaveTable", uid, self.m_tableId)
	--广播玩家离开
	self.m_pTable:broadcastMsg(msg.NameToId.PlayerExitPush, {seat_index=player.seat_index;}, uid)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = 1;})		
	return true
end



return TableStateFree