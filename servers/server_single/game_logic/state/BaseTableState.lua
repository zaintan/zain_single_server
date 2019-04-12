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
	elseif msg_id == msg.NameToId.ReleaseRequest then
		return self:_onReleaseReq(msg_id,uid, data)
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


--处理Play 和 Wait状态的
function BaseTableState:_onReleaseReq(msg_id,uid, data)
	local player = self.m_pTable:getPlayer(uid)
	if not player then 
		self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -100;status_tip="找不到该玩家";})
		return
	end 

	--发起投票解散
	if data.type == const.ReleaseRequestType.RELEASE then
		if self.m_releaseVote then --已经有投票在进行中了
			self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -4;status_tip="已有投票在进行";})
			return false
		else 
			self.m_releaseVote = new(require("game_logic.ReleaseVote"))
			self.m_releaseVote:init(self.m_pTable,player.seat_index,function (result)
				self.m_releaseVote = nil
				if result == const.ReleaseVoteResult.SUCCESS then --gameover 如果是牌局中
					self.m_pTable:destroy(const.GameFinishReason.PLAYER_VOTE_RELEASE)
				end 				
			end)
			self.m_releaseVote:handleReleaseReq(player, data,msg_id)
			return true
		end 
	elseif data.type == const.ReleaseRequestType.VOTE then
		if self.m_releaseVote then --已经有投票在进行中了
			self.m_releaseVote:handleVoteReq(player, data,msg_id)
			return true
		else--投票已经结束
			self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -5;status_tip="投票已结束";})
			return false
		end 
	else
		--未知解散请求 回复解散失败
		self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = -3;status_tip="未定义请求";})
		return false		
	end 

end


return BaseTableState