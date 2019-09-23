------------------------------------------------------
---! @file
---! @brief AbstractTable
------------------------------------------------------
local ClusterHelper = require "ClusterHelper"

local Super     = require("abstract.BaseContainer")
local Table     = class(Super)

local LOGTAG = "Table"

--初始化顺序 从上到下
Table._behavior_cfgs_ = {
    { path = "behaviors.table.users";},
    { path = "behaviors.table.info";   bArgs = true;},
    { path = "behaviors.table.states";},
    { path = "behaviors.table.pool"; },
    { path = "behaviors.table.cards";},
}

function Table:ctor(...)
	self:changeState(const.GameStatus.FREE)
end

function Table:pushRoomInfo(uid)
	local game_status = self:getCurState():getStatus()
	self:_getBehavior("info"):reconnectPush(uid,game_status)
	self:_getBehavior("cards"):reconnectPush(uid)	
	self:_getBehavior("operates"):reconnectPush(uid)
	self:_getBehavior("release"):reconnectPush(uid)
end

--房间内重连
function Table:reconnect(fromNodeIndex, fromAddr, uid)
	--update uid agent,广播通知其他玩家
	--users.playerReconnect
	local succ = self:playerReconnect(fromNodeIndex, fromAddr, uid)
	if not succ then 
		--该玩家不在房间中
		Log.e(LOGTAG,"uid=%d 逻辑服重连失败!房间内找不到该玩家",uid)
		ClusterHelper.callIndex(fromNodeIndex,fromAddr,"sendMsg",msg.NameToId.JoinRoomResponse,{status = -401;})
		return false
	end 
	--回复该玩家自己的重连信息
	self:sendMsg(msg.NameToId.JoinRoomResponse,{status = 1;},uid)
	self:pushRoomInfo(uid)
	return true
end

--加入房间
function Table:join(...)
	return self:getCurState():onJoin(...)
end

--下线
--users实现该行为logout

Table._COMMAND_MAP_ = {
	[msg.NameToId.ReadyRequest]          = "onReadyReq";
	[msg.NameToId.OutCardRequest]        = "onOutCardReq";
	[msg.NameToId.OperateCardRequest]    = "onOperateCardReq";
	[msg.NameToId.PlayerExitRequest]     = "onPlayerExitReq";
	[msg.NameToId.ReleaseRequest]        = "onReleaseReq";
}

--收到客户端消息
function Table:on_req(uid, msg_id, data)
	if self._bWaitDestroy then 
		log.e(LOGTAG,"maybe err!销毁状态 接收到msg_id:%d",msg_id)
		return false
	end 

	local func_name = self._COMMAND_MAP_[msg_id]
	if func_name then 
		local state = self:getCurState()
		local func  = state[func_name]
		if func then 
			return func(state, uid, msg_id, data )
		else 
			log.e(LOGTAG,"maybe err! state has not complete this function:%s",func_name)
		end 
	else
		log.e(LOGTAG,"maybe err! unlisten msg_id:%d",msg_id)
	end 
	return false
end

--销毁
function Table:destroy()
	--通知AllocServer
	local tid    = self.m_pTable:getTableId()
	local index  = skynet.getenv("server_alloc")
	local bNotifiGame = false
    ClusterHelper.callIndex(index,".AllocService","release",tid, bNotifiGame)
	--
	self:_onGameEnd()
end 

--alloc server 透传 强制解散
function Table:out_release()
	self:_onGameEnd()
end


function Table:_onGameEnd()
	--大结算 广播客户端 游戏结束
	self:getCurState():broadcastGameOver()
	--标记即将销毁  不再处理消息
	self._bWaitDestroy = true
	--延时退出exit  防止队列阻塞不返回
	skynet.timeout(1,function()
		skynet.exit()
	end)
end 


return Table