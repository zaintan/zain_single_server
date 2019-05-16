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
	if self.m_table then 
		return true
	end 
	return false
end

--需推送客户端
function TableLogic:reconnect(fromNodeIndex, fromAddr, uid)
	return cs(function ()
		return self.m_table:reconnect(fromNodeIndex, fromAddr, uid)
	end)
end

--需推送客户端
function TableLogic:join(fromNodeIndex, fromAddr, userinfo)
	return cs(function ()
		return self.m_table:join(fromNodeIndex, fromAddr, userinfo)
	end)
end

--标记下线即可 无需返回消息
function TableLogic:logout(fromNodeIndex, selfAddr, uid)
	return cs(function ()
		return self.m_table:logout(fromNodeIndex, selfAddr, uid)
	end)
end


function TableLogic:on_req(uid, msg_id, data)
	return cs(function ()
		return self.m_table:on_req(uid, msg_id, data)
	end)
end

-------------------------------------------------------------------------
function TableLogic:_createTable(...)
	local BaseTable = require("abstract.Table")
	return new(BaseTable, ...)
end

return TableLogic