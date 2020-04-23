------------------------------------------------------
---! @file
---! @brief TableLogic, 管理
------------------------------------------------------
local skynet    = require "skynet"
require "skynet.manager"

local queue         = require "skynet.queue"
local cs            = queue()

local TableLogic    = {}
--local LOGTAG        = "TableLogic"

--初始化容器
function TableLogic:init(tid, userInfo, data)
	self.m_table = self:_createTable(tid,userInfo,data)
	log.d("TL","TableLogic:init---self=%s,TableLogic=%s,self.m_table=%s",tostring(self),tostring(TableLogic),tostring(self.m_table))
	if self.m_table then 
		return true
	end 
	return false
end

--需推送客户端
function TableLogic:reconnect(fromNodeIndex, fromAddr, uid)
	return cs(function ()
		return self.m_table:recvReconnectReq(fromNodeIndex, fromAddr, uid)
	end)
end

--需推送客户端
function TableLogic:join(fromNodeIndex, fromAddr, userinfo)
	return cs(function ()
		return self.m_table:recvJoinReq(fromNodeIndex, fromAddr, userinfo)
	end)
end

--标记下线即可 无需返回消息
function TableLogic:logout(fromNodeIndex, selfAddr, uid)
	return cs(function ()
		return self.m_table:recvLogout(fromNodeIndex, selfAddr, uid)
	end)
end


function TableLogic:on_req(uid, data)
	return cs(function ()
		log.d("TL","TableLogic:on_req---uid=%d,self=%s,TableLogic=%s,self.m_table=%s",uid,tostring(self),tostring(TableLogic),tostring(self.m_table))		
		return self.m_table:on_req(uid, data)
	end)
end

-------------------------------------------------------------------------
function TableLogic:_createTable(tid,userInfo,data)--tid,userInfo,data
	--data.game_rules --玩法规则
	--data.game_id    --子游戏
	--data.game_type  --子玩法
	--结束条件
	local tblClass = nil
	if data.game_id == 1001 then 
		tblClass = require("subgame.mj.zhuanzhuan.ZZTable")
	end 
	return new(tblClass, tid,userInfo,data)
end

return TableLogic