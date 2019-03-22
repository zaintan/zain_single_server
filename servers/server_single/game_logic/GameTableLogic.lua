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
		self.m_table = self:_createTable(data.game_id,data.game_type,data.game_rules)
		--设置结束条件
		self.m_table:setOverCondition(data.over_type, data.over_val)
	end)
end

--return JoinRoomResponse
function GameTableLogic:reconnect(agent, uid)
	return self.m_msgQue(function()
		return {
			status = 0;
			game_id = 1;
			game_type = 1;
			game_rules = {1};
			game_status = 0;
			over_type   = 0;
			over_val    = 0;
			room_id     = 0;
			players = {};
		};
	end)
end

--return true,JoinRoomResponse
--return false,"reason"
function GameTableLogic:join(agent, uid)
	return self.m_msgQue(function()
		return false,"房间已经开始!"
	end)
end

function GameTableLogic:_handlerReadyReq(uid, data)

end 

function GameTableLogic:_handlerOperateCardReq(uid, data)

end 

function GameTableLogic:_handlerOutCardReq(uid, data)

end 

local ComandFuncMap = {
    [const.MsgId.ReadyReq]       = GameTableLogic._handlerReadyReq;
    [const.MsgId.OperateCardReq] = GameTableLogic._handlerOperateCardReq;
    [const.MsgId.OutCardReq]     = GameTableLogic._handlerOutCardReq;    
}

function GameTableLogic:on_req(uid, msgId, data)
    local func = ComandFuncMap[msg_id]
    if func then 
    	return self.m_msgQue(function()
    		func(uid, data)
		end)
	end 
end

function GameTableLogic:_createTable(game_id, game_type, game_rules)

end

return GameTableLogic