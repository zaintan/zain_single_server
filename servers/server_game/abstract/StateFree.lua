------------------------------------------------------
---! @file
---! @brief StateFree
------------------------------------------------------
local Super     = require("abstract.BaseState")
local StateFree = class(Super)


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


function StateFree:onPlayerExitReq(uid, msg_id, data)
	local player = self.m_pTable:getPlayerByUid(uid)
	if not player then 
		Log.e(LOGTAG,"maybe err! player uid=%d not in this table!", uid)
		return false
	end 

	--通知->AllocServer清掉  --agent
	local tid    = self.m_pTable:getTableId()
	local index  = skynet.getenv("server_alloc")
	local bNotifiGame = false
    local ok,ret = ClusterHelper.callIndex(index,".AllocService","exit",uid,tid,bNotifiGame)
    --response player  and broadcast others
	self.m_pTable:delPlayer(uid)
	return true
end

return StateFree