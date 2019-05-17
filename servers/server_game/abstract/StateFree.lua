------------------------------------------------------
---! @file
---! @brief StateFree
---! @auth  ZainTan
------------------------------------------------------
local Super     = require("abstract.BaseState")
local StateFree = class(Super)
----
function StateFree:onJoin(node, addr, userinfo)
	--users.addPlayer(agentNode, agentAddr, uid , data)
	local ret = self.m_pTable:addPlayer(node, addr, userinfo.FUserID ,userinfo) 
	if ret < 0 then --failed
		ClusterHelper.callIndex(node,addr,"sendMsg",msg.NameToId.JoinRoomResponse,{status = ret-410;})
		return false
	end 

	--回复该玩家加入房间的信息
	local rsp         = self.m_pTable:getJoinInfo()
	rsp.status        = 1
	self:sendMsg(msg.NameToId.JoinRoomResponse,rsp,uid)
	return true
end
----
function StateFree:onReadyReq(uid, msg_id, data)
	--修改玩家准备状态 广播通知其他玩家
	self.m_pTable:setReadyState(uid, data.ready)
	--判断游戏是否开始
	if data.ready and self.m_pTable:playerNumCanStart() and self.m_pTable:isAllReady() then 
		--座位是否需要调整
		self.m_pTable:tidySeat()
		--切换到play状态
		self.m_pTable:changeState(const.GameStatus.PLAY)
	end 
	return true
end
----
function StateFree:onPlayerExitReq(uid, msg_id, data)
	local player = self.m_pTable:getPlayerByUid(uid)
	if not player then 
		Log.e(LOGTAG,"maybe err! player uid=%d not in this table!", uid)
		return false
	end 

	--通知->AllocServer清掉  --agent
	local tid    = self.m_pTable:getTableId()
	local index  = skynet.getenv("server_alloc")
    local ok,ret = ClusterHelper.callIndex(index,".AllocService","exit",uid,tid)
    --response player  and broadcast others
	self.m_pTable:delPlayer(uid)
	return true
end

----
function StateFree:onReleaseReq(uid, msg_id, data)
	local errcode = 0
	--牌局未开始 创建者可以解散 普通人可以离开
	if data.type == const.ReleaseRequestType.RELEASE then

		local creater = self.m_pTable:getTableCreaterInfo()

		if creater and uid == creater.user_id then 
			--
			self.m_pTable:onCreatorRelease(uid, errcode)
			return true
		else
			errcode = -402
		end 
	else 
		errcode = -403
	end 
	self.m_pTable:onCreatorRelease(uid, errcode)
	return false
end

function StateFree:broadcastGameOver()
	-- body
	--free状态无需 广播结束
end

return StateFree