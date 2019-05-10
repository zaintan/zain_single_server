------------------------------------------------------
---! @file
---! @brief BaseTableState
------------------------------------------------------
local BaseTableState = class()

function BaseTableState:ctor(pTable)
	--self.m_status = const.GameStatus.
	self.m_pTable = pTable

end

function BaseTableState:getStatus()
	return self.m_status
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
	local player = self.m_pTable:getPlayer(uid)
	if player then 
		player.agent = agent
	end 
end


function BaseTableState:on_req(uid, msg_id, data)
	if msg_id == msg.NameToId.ReadyRequest then 
		return self:_onReadyReq(msg_id,uid, data)
	elseif msg_id == msg.NameToId.OutCardRequest then
		return self:_onOutCardReq(msg_id,uid, data)
	elseif msg_id == msg.NameToId.OperateCardRequest then
		return self:_onOperateCardReq(msg_id,uid, data)
	elseif msg_id == msg.NameToId.PlayerExitRequest then
		return self:_onPlayerExitReq(msg_id,uid, data)		
	end 
end

function BaseTableState:_onReadyReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return false
end

function BaseTableState:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return false
end

function BaseTableState:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return false
end



--处理Play 和 Wait状态的
function BaseTableState:_onPlayerExitReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -1;})
	return false
end


return BaseTableState