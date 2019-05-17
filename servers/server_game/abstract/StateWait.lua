------------------------------------------------------
---! @file
---! @brief StateWait
------------------------------------------------------
local Super     = require("abstract.BaseState")
local StateWait = class(Super)



function StateWait:onEnter()
	Log.i("","State:%d onEnter",self.m_status)

	--取消所有玩家的准备状态
	local bReady     = false
	local bBroadcast = true
	self.m_pTable:resetAllReadyState(bReady, bBroadcast)
	
	--清理掉所有玩家的手牌
	--这个也可以放在牌局开始前处理
	--self.m_pTable:resetAllPlayersCards()
end



function StateWait:onReadyReq(uid, msg_id, data)
	--修改玩家准备状态 广播通知其他玩家
	self.m_pTable:setReadyState(uid, data.ready)
	--判断游戏是否开始
	if data.ready and self.m_pTable:isAllReady() then 
		--切换到play状态
		self.m_pTable:changeState(const.GameStatus.PLAY)
	end 
	return true
end

return StateWait