------------------------------------------------------
---! @file
---! @brief TableStateFree
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStateFree = class(Super)

function TableStateFree:ctor(pTable)
	self.m_status = const.GameStatus.FREE
end

function TableStateFree:onEnter()
	-- body
end

function TableStateFree:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStateFree:join(agent, uid)
	-- body
end

--return JoinRoomResponse
function TableStateFree:reconnect(agent, uid)
	local info = self.m_pTable:getBaseInfo()
	info.status = 0
	return info
end


function TableStateFree:_onReadyReq(uid, data)
	-- body
end

function TableStateFree:_onOutCardReq(uid, data)
	-- body
end

function TableStateFree:_onOperateCardReq(uid, data)
	-- body
end


return TableStateFree