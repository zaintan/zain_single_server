------------------------------------------------------
---! @file
---! @brief BaseTableState
------------------------------------------------------
local BaseTableState = class()

function BaseTableState:ctor(pTable)
	--self.m_status = const.GameStatus.
	self.m_pTable = pTable

	self.m_release_votes = {}
	self.m_is_voting     = false
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
	if msg_id == const.MsgId.ReadyReq then 
		return self:_onReadyReq(msg_id,uid, data)
	elseif msg_id == const.MsgId.OutCardReq then
		return self:_onOutCardReq(msg_id,uid, data)
	elseif msg_id == const.MsgId.OperateCardReq then
		return self:_onOperateCardReq(msg_id,uid, data)
	elseif msg_id == const.MsgId.ReleaseReq then
		return self:_onReleaseReq(msg_id,uid, data)
	end 
end

function BaseTableState:_onReadyReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function BaseTableState:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function BaseTableState:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;})
	return false
end

function BaseTableState:__resetVotes()
	for i=1,self.m_pTable:getCurPlayerNum() do
		self.m_release_votes[i] = const.Release.VOTE_NO_OP
	end
end

function BaseTableState:__isAllAgreeRelease()
	for i=1,self.m_pTable:getCurPlayerNum() do
		local vote = self.m_release_votes[i]
		if vote and vote ~= const.Release.VOTE_AGREE then
			return false
		end 
	end
	return true
end


--处理Play 和 Wait状态的
function BaseTableState:_onReleaseReq(msg_id,uid, data)
	local player = self.m_pTable:getPlayer(uid)
	if not player then 
		self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -100;})
		return
	end 

	--发起投票解散
	if data.type == const.Release.APPLY_VOTE then

		local result = const.Release.STATUS_VOTING
		if not self.m_is_voting then 
			self.m_is_voting = true
			self:__resetVotes()
			--发起者
			self.m_release_votes[player.seat_index+1] = const.Release.VOTE_AGREE
		else 
			self.m_release_votes[player.seat_index+1] = data.vote_value
			if data.vote_value == const.Release.VOTE_REFUS then --拒绝
				self.m_is_voting = false
				result = const.Release.STATUS_FAILED
			end 
		end 
		if self:__isAllAgreeRelease() then 
			result = const.Release.STATUS_SUCCESS
		end 
		self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = 1;})	
		self.m_pTable:broadcastMsg(const.MsgId.ReleasePush,{result = result;votes=self.m_release_votes;})

		if result == const.Release.STATUS_SUCCESS then 
			--gameover 如果是牌局中
			self.m_pTable:destroy(const.Release.RELEASE_VOTE)
		end 
	else 
		--未知解散请求 回复解散失败
		self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -3;})
		return false		
	end 

end


return BaseTableState