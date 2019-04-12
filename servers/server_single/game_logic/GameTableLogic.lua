------------------------------------------------------
---! @file
---! @brief GameTableLogic
------------------------------------------------------
local GameTableLogic = {}


local skynet = require "skynet"
local queue  = require "skynet.queue"

local LOGTAG = "GT"

local cs  = queue()

--不校验玩法  认为是一定成功的
function GameTableLogic:init(pGameServer, pTableId,create_uid, data)
	self.m_msgQue = cs
	Log.d(LOGTAG, "init")
	self.m_msgQue(function()
		Log.d(LOGTAG, "init_")
		self.m_table = self:_createTable(pTableId, create_uid,data.game_id,data.game_type,data.game_rules)
		--设置结束条件
		self.m_table:setOverCondition(data.over_type, data.over_val)
		--self.m_table:init()
	end)
end


function GameTableLogic:reconnect(agent, uid)
	Log.d(LOGTAG, "reconnect agent=%x,uid=%d",agent,uid)
	return self.m_msgQue(function()
		Log.d(LOGTAG, "reconnect")
		return self.m_table:getCurState():reconnect(agent, uid)
	end)
end


function GameTableLogic:join(agent, uid)
	Log.d(LOGTAG, "join agent=%x,uid=%d",agent,uid)
	return self.m_msgQue(function()
		Log.d(LOGTAG, "join")
		return self.m_table:getCurState():join(agent, uid)
	end)
end


function GameTableLogic:on_req(uid, msg_id, data)
	Log.d(LOGTAG, "on_req msg_id=%d,uid=%d",msg_id,uid)
   	return self.m_msgQue(function()
   		if msg_id == msg.NameToId.ReleaseRequest then
   			return self.m_table:onReleaseReq(uid, msg_id, data)
   		else
   			return self.m_table:getCurState():on_req(uid, msg_id, data)
   		end 
	end)
end

function GameTableLogic:_createTable(...)
	local BaseTable = require("game_logic.table.BaseTable")
	return new(BaseTable, ...)
end

return GameTableLogic