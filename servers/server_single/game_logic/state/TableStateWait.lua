------------------------------------------------------
---! @file
---! @brief TableStateWait
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStateWait = class(Super)

function TableStateWait:ctor(pTable)
	self.m_status = const.GameStatus.WAIT
end

function TableStateWait:onEnter()
	-- body
end

function TableStateWait:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStateWait:join(agent, uid)
	return false,"无法加入,牌局已开始!"
end

--return JoinRoomResponse
function TableStateWait:reconnect(agent, uid)
	-- body
end


function TableStateWait:_onReadyReq(uid, data)
	-- body
end

function TableStateWait:_onOutCardReq(uid, data)
	-- body
end

function TableStateWait:_onOperateCardReq(uid, data)
	-- body
end


return TableStateWait