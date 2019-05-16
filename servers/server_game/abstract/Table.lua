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
    { path = "behaviors.table.users";  bArgs = false; },
    { path = "behaviors.table.info";   bArgs = true;  },
    { path = "behaviors.table.states"; bArgs = false; },
    { path = "behaviors.table.pool";   bArgs = false; },
    { path = "behaviors.table.cards";  bArgs = false; },
}

function Table:ctor(...)
	self:changeState(const.GameStatus.FREE)
end

function Table:_getInfo()
	local info = {}
	info.game_status = self:getCurState():getStatus()
	--info
	local tblInfo     = self:getTableInfo()
	--players
	local playersInfo = self:getPlayersInfo()
	--release_info
	local releaseInfo = self:getReleaseInfo()
	--round_info
	local roundInfo   = self:getRoundInfo()
	--op_info
	local opInfo      = self:getOperateInfo()
	--cars_info
	local cardsInfo   = self:getCardsInfo()
	--合并
	local data = table.union(info,tblInfo,playersInfo,releaseInfo,roundInfo,opInfo,cardsInfo)

	return data
end

--房间内重连
function Table:reconnect(fromNodeIndex, fromAddr, uid)
	--update uid agent,广播通知其他玩家
	--users.playerReconnect
	local succ = self:playerReconnect(fromNodeIndex, fromAddr, uid)
	if not succ then 
		--该玩家不在房间中
		Log.e(LOGTAG,"uid=%d 逻辑服重连失败!房间内找不到该玩家",uid)
		ClusterHelper.callIndex(fromNodeIndex,fromAddr,"sendMsg",msg.NameToId.JoinRoomResponse,{status = -401;}
		return false
	end 
	--回复该玩家自己的重连信息
	local rsp         = self:_getInfo()
	rsp.status        = 1
	self:sendMsg(msg.NameToId.JoinRoomResponse,rsp,uid)
	return true
end

--加入房间
function Table:join(node, addr, userinfo)
	-- body
	local state = self:getCurState()
	if not state then 
		Log.e(LOGTAG,"maybe err! table state can not be nil!")
		ClusterHelper.callIndex(node,addr,"sendMsg",msg.NameToId.JoinRoomResponse,{status = -401;})
		return false
	end 

	--牌局已开始
	if self:getCurState():getStatus() ~= const.GameStatus.FREE then
		Log.i(LOGTAG,"牌局已经开始,无法加入! uid=%d,tid=%d",userinfo.FUserID, self:getTableId())
		ClusterHelper.callIndex(node,addr,"sendMsg",msg.NameToId.JoinRoomResponse,{status = -402;})
		return false
	end  

	--users.addPlayer(agentNode, agentAddr, uid , data)
	local ret = self:addPlayer(node, addr, userinfo.FUserID ,userinfo) 
	if ret < 0 then --failed
		--Log.i(LOGTAG,"牌局已经开始,无法加入! uid=%d,tid=%d",userinfo.FUserID, self:getTableId())
		ClusterHelper.callIndex(node,addr,"sendMsg",msg.NameToId.JoinRoomResponse,{status = ret-410;})
		return false
	end 

	--回复该玩家加入房间的信息
	local rsp         = self:_getInfo()
	rsp.status        = 1
	self:sendMsg(msg.NameToId.JoinRoomResponse,rsp,uid)
	return true
end


--下线
--users实现该行为logout

Table._COMMAND_MAP_ = {
	[msg.NameToId.ReadyRequest]          = "onReadyReq";
	[msg.NameToId.OutCardRequest]        = "onOutCardReq";
	[msg.NameToId.OperateCardRequest]    = "onOperateCardReq";
	[msg.NameToId.PlayerExitRequest]     = "onPlayerExitReq";
}

--收到客户端消息
function Table:on_req(uid, msg_id, data)
	local func_name = self._COMMAND_MAP_[msg_id]
	if func_name then 
		local state = self:getCurState()
		local func  = state[func_name]
		if func then 
			func(state, uid, msg_id, data )
		else 
			log.e(LOGTAG,"maybe err! state has not complete this function:%s",func_name)
		end 
	else
		log.e(LOGTAG,"maybe err! unlisten msg_id:%d",msg_id)
	end 
end

return Table