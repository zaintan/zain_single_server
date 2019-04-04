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
			self.m_pTable:broadcastMsg(const.MsgId.PlayerEnterPush, msg_data,uid)
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
		self.m_pTable:sendMsg(uid, const.MsgId.ReadyRsp, {status = -1;})
		return false
	end 

	player.ready = data.ready
	self.m_pTable:sendMsg(uid, const.MsgId.ReadyRsp, {status = 0;ready = data.ready;})
	
	local push_data = {
		ready_infos = {{seat_index = player.seat_index;ready = data.ready;}}
	}
	self.m_pTable:broadcastMsg(const.MsgId.ReadyPush, push_data, uid)
	
	if self.m_pTable:isFull() and self.m_pTable:isAllReady() then 
		self.m_pTable:changePlay()
	end 
	return true
end

function TableStateFree:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip = "牌局还未开始,无法出牌!";})
end

function TableStateFree:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip = "牌局还未开始,无法操作牌!";})
end

function TableStateFree:_onReleaseReq(msg_id,uid, data)
	--牌局未开始 创建者可以解散 普通人可以离开
	if data.type == const.Release.APPLY_RELEASE then
		if uid == self.m_pTable.m_createUid then 
			--解散成功
			self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = const.Release.RELEASE_CREATOR;status_tip="创建者已解散房间!"})
			--destroy会推送成功解散的消息
			self.m_pTable:destroy(const.Release.RELEASE_CREATOR)
			return true
		else
			self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip="非创建者无权解散房间!"})
			return false
		end 
	elseif data.type == const.Release.APPLY_EXIT then 
		local player = self.m_pTable:getPlayer(uid)
		if not player then 
			--玩家不在这个房间 回复解散失败
			self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -2;})
			return false
		end 
		--通知GameServers
		pcall(skynet.call, ".GameService", "lua","leaveTable", uid, self.m_tableId)
		--广播玩家离开
		self.m_pTable:broadcastMsg(const.MsgId.PlayerExitPush, {seat_index=player.seat_index;}, uid)
		self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = 1;})		
		return true
	end 
	--未知解散请求 回复解散失败
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -3;})
	return false
end

return TableStateFree