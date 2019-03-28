------------------------------------------------------
---! @file
---! @brief GameTableLogic
------------------------------------------------------
local GameTableLogic = {}


local skynet = require "skynet"
local queue  = require "skynet.queue"

local TAG = "GameTable"

local cs  = queue()

--不校验玩法  认为是一定成功的
function GameTableLogic:init(pGameServer, pTableId, data)
	self.m_msgQue = cs

	self.m_msgQue(function()
		self.m_table = self:_createTable(pTableId, data.game_id,data.game_type,data.game_rules)
		--设置结束条件
		self.m_table:setOverCondition(data.over_type, data.over_val)
		--self.m_table:init()
	end)
end


function GameTableLogic:reconnect(agent, uid)
	return self.m_msgQue(function()
		return self.m_table:getCurState():reconnect(agent, uid)
	end)
end


function GameTableLogic:join(agent, uid)
	return self.m_msgQue(function()
		return self.m_table:getCurState():join(agent, uid)
	end)
end


function GameTableLogic:on_req(uid, msg_id, data)
   	return self.m_msgQue(function()
   		return self.m_table:getCurState():on_req(uid, msg_id, data)
	end)
end

function GameTableLogic:_createTable(...)
	local BaseTable = require("game_logic.table.BaseTable")
	return new(BaseTable, ...)
end

return GameTableLogic