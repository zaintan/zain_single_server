------------------------------------------------------
---! @file
---! @brief TableStatePlay
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStatePlay = class(Super)

function TableStatePlay:ctor(pTable)
	self.m_status = const.GameStatus.PLAY
end

function TableStatePlay:onEnter()
	-- body
end

function TableStatePlay:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStatePlay:join(agent, uid)
	return false,"无法加入,牌局已开始!"
end

--return JoinRoomResponse
function TableStatePlay:reconnect(agent, uid)
	-- body
end


function TableStatePlay:_onReadyReq(uid, data)
	-- body
end

function TableStatePlay:_onOutCardReq(uid, data)
	-- body
end

function TableStatePlay:_onOperateCardReq(uid, data)
	-- body
end


return TableStatePlay