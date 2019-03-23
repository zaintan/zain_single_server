------------------------------------------------------
---! @file
---! @brief BaseTableState
------------------------------------------------------
local BaseTableState = class()

function BaseTableState:ctor(pTable)
	--self.m_status = const.GameStatus.
	self.m_pTable = pTable
end

function BaseTableState:onEnter()
	-- body
end

function BaseTableState:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function BaseTableState:join(agent, uid)
	-- body
end

--return JoinRoomResponse
function BaseTableState:reconnect(agent, uid)
	-- body
end


function BaseTableState:on_req(uid, msg_id, data)
	if msg_id == const.MsgId.ReadyReq then 
		return self:_onReadyReq(uid, data)
	elseif msg_id == const.MsgId.OutCardReq then
		return self:_onOutCardReq(uid, data)
	elseif msg_id == const.MsgId.OperateCardReq then
		return self:_onOperateCardReq(uid, data)
	end 
end

function BaseTableState:_onReadyReq(uid, data)
	-- body
end

function BaseTableState:_onOutCardReq(uid, data)
	-- body
end

function BaseTableState:_onOperateCardReq(uid, data)
	-- body
end


return BaseTableState