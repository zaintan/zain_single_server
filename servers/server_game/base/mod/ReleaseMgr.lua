local ReleaseMgr  = class()

local LOGTAG = "[ReleaseMgr]"

function ReleaseMgr:ctor(pTable, maxReleaseReqLimit, defaultWaitSeconds)
	self.m_pTable     = pTable
	self.m_userMgr    = self.m_pTable.m_userMgr
	self.m_timer      = self.m_pTable.m_timer
	self.m_creatorUid = self.m_pTable.m_createrInfo.user_id

	self.m_maxReleaseReqLimit = maxReleaseReqLimit or 3--默认最多3次解散
	self.m_curReleaseCount    = 0
	self.m_defaultWaitSeconds = defaultWaitSeconds or 90--默认等待90s
	self.m_timeHandler        = nil
	self.m_startVoteTime      = 0
end 

--function ReleaseMgr:_isTableOwner(uid)
--	return uid == self.m_creatorUid
--end

--系统后台解散  通过调分配服接口
function ReleaseMgr:onSysRelease()
	Log.d(LOGTAG,"onSysRelease")

	if not self.m_voteData then 
		self:_initVoteData()
	end 
	self:_stopVote(const.ReleaseVote.SUCCESS)
	--广播通知 刷新房间里面所有人
	self:_broadcastReleasePush()
	--
	self.m_pTable:changeToGameOver(const.GameFinishReason.RELEASE_SYS)
	return true
end

function ReleaseMgr:onReleaseReq( uid, data )
	--牌局还未开始
	if self.m_pTable:isGameFree() then 
		Log.i(LOGTAG,"invalid release req! table state is GAME_FREE!")
		return false
	end	
	--
	if data.type == const.ReleaseReqType.RELEASE then 
		return self:_onRelease(uid)
	elseif data.type == const.ReleaseReqType.VOTE then 
		return self:_onVote(uid, data.value)
	else 
		Log.w(LOGTAG, "maybe error! invalid release req type=%d", data.type)
		self:_rspReleaseReq(uid, data.type, MsgCode.ReleaseFailedType)
		return false
	end 
end

function ReleaseMgr:_rspReleaseReq(uid, req_type,  msgcode)
	local data    = g_createMsg(msgcode)
	data.req_type = req_type
	self.m_userMgr:sendMsgByUid(msg.NameToId.ReleaseResponse, data, uid)
end

function ReleaseMgr:_onRelease( uid )
	--正在投票
	if self:_isVoting() then 
		Log.w(LOGTAG, "maybe error! is already voting!")
		self:_rspReleaseReq(uid, const.ReleaseReqType.RELEASE, MsgCode.ReleaseFailedRepeat)
		return false
	end 
	--次数限制
	if self.m_curReleaseCount >= self.m_maxReleaseReqLimit then 
		self:_rspReleaseReq(uid, const.ReleaseReqType.RELEASE, MsgCode.ReleaseFailedCount)
		return false
	end 

	self:_startVote(uid)	
	return true
end

function ReleaseMgr:_onVote( uid, value )
	local user_vote = self:_getUserVote(uid)
	--无效投票
	if (value ~= const.ReleaseVoteVal.AGREE and value ~= const.ReleaseVoteVal.REJECT)
		or (not user_vote) or user_vote.vote ~= const.ReleaseVoteVal.UNDO  then 
		--回复投票失败
		self:_rspReleaseReq(uid, const.ReleaseReqType.VOTE, MsgCode.VoteFailed)
		return false
	end 
	user_vote.vote = value
	if value == const.ReleaseVoteVal.AGREE then 
		if self:_isAllUserAgree() then 
			self:_stopVote(const.ReleaseVote.SUCCESS)--成功解散
		end 
	else --reject
		self:_stopVote(const.ReleaseVote.FAILED)--失败
	end 
	--广播通知 刷新
	self:_broadcastReleasePush()
	--
	if self.m_voteData.status == const.ReleaseVote.SUCCESS then 
		self.m_pTable:changeToGameOver(const.GameFinishReason.RELEASE_USER)
	end 
	return true
end

function ReleaseMgr:_initVoteData()
	local data   = {}
	data.user_id            = 0
	data.cur_release_count  = self.m_curReleaseCount
	data.max_realease_limit = self.m_maxReleaseReqLimit
	data.cur_seconds        = self.m_defaultWaitSeconds
	data.max_seconds        = self.m_defaultWaitSeconds
	data.status             = const.ReleaseVote.VOTING
	data.votes              = {}
	local uids      = self.m_userMgr:getAllUids()
	for _,uid in ipairs(uids) do
		--if uid ~= req_uid then 
		table.insert(data.votes, {vote = const.ReleaseVoteVal.UNDO;  user_id = uid;})
		--end  	
	end 	
	self.m_voteData = data
end

function ReleaseMgr:_startVote( req_uid )
	--
	self.m_curReleaseCount = self.m_curReleaseCount + 1
	self.m_startVoteTime   = os.time()

	if not self.m_voteData then 
		self:_initVoteData()
	end 

	self.m_voteData.user_id = req_uid
	--重置 投票状态
	for _,v in ipairs(self.m_voteData.votes) do
		v.vote = v.user_id == req_uid and const.ReleaseVoteVal.AGREE or const.ReleaseVoteVal.UNDO
	end
	--起定时器
	self.m_timeHandler = self.m_timer:registerOnceNow(self.onWaitTimeOut, self.m_defaultWaitSeconds * 1000 ,self)--//  times=-1需手动unregister
end

function ReleaseMgr:_stopVote( result )
	--
	self.m_voteData.status = result--const.ReleaseVote.
	--停止定时器
	self.m_timer:unregister(self.m_timeHandler)
	self.m_timeHandler = nil
end

function ReleaseMgr:_isVoting()
	return self.m_timeHandler and true or false
end

function ReleaseMgr:_updateTimeOfVoteData()
	if self.m_voteData then 
		local passedSeconds = os.time() - self.m_startVoteTime
		local remainSeconds = self.m_defaultWaitSeconds - passedSeconds 
		self.m_voteData.cur_seconds = remainSeconds < 0 and 0 or remainSeconds
	end  
end

function ReleaseMgr:_getUserVote( uid )
	if self.m_voteData then 
		for index,v in ipairs(self.m_voteData.votes) do
			if v.user_id == uid then 
				return v
			end 
		end
	end
end

function ReleaseMgr:_isAllUserAgree()
	if self.m_voteData then 
		for index,v in ipairs(self.m_voteData.votes) do
			if v.vote ~= const.ReleaseVoteVal.AGREE then 
				return false
			end 
		end
		return true
	end
	return false
end

function ReleaseMgr:_broadcastReleasePush()
	local data = {
		info = self:getReleaseInfo()
	}
	self.m_userMgr:broadcastMsg(msg.NameToId.ReleasePush, data)
end

function ReleaseMgr:onWaitTimeOut()
	--超时解散
	self:_stopVote(const.ReleaseVote.SUCCESS)
	self:_broadcastReleasePush()
	self.m_pTable:changeToGameOver(const.GameFinishReason.RELEASE_TIMEOUT)
end


function ReleaseMgr:getReleaseInfo()
	if self:_isVoting() then 
		self:_updateTimeOfVoteData()
		return self.m_voteData
	end 	
	return nil
end

return ReleaseMgr