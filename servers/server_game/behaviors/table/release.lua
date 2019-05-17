--管理玩家解散信息
local Super           = require("behaviors.behavior")
local release         = class(Super)

local skynet          = require "skynet"
--倒计时时间
local COUNT_DOWN_TIME = 150

release.EXPORTED_METHODS = {
    "getReleaseInfo",
    "onCreatorRelease",
    "onReleaseStartVote",
    "onReleaseDoVote",
}

function release:_pre_bind_(...)

end

function release:_on_bind_()
	-- body
end

function release:_clear_()
	self.target_  = nil
end


function release:onCreatorRelease(uid, errCode)
	--failed
	if errCode < 0 then 
		self.target_:sendMsg(msg.NameToId.ReleaseResponse , {status = errCode;}, uid)
		return 
	end 

	--返回请求者
	self.target_:sendMsg(msg.NameToId.ReleaseResponse, {status = 1}, uid)
	--广播
	local data = {
		release_info = {
			result = const.ReleaseVoteResult.SUCCESS;
		};
	}
	self.target_:broadcastMsg(msg.NameToId.ReleasePush, data)


	--标记GameOver原因 const.GameFinishReason.CREATOR_RELEASE
	self.target_:setGameFinishReason(const.GameFinishReason.CREATOR_RELEASE);
	--大结算 销毁table
	self.target_:destroy()

	return true
end

local function cancelable_timeout(ti, func)
	local function callback()
		if func then 
			func()
		end 
	end

	local function cancel()
		func = nil
	end

	skynet.timeout(ti, callback)
	return cancel
end

--开始投票解散
function release:onReleaseStartVote(uid, data)
	--已经有投票在进行中了
	if self.m_vote then 
		self.target_:sendMsg(msg.NameToId.ReleaseResponse, {status = -420;}, uid)
		return
	end 

	self:_initVote(uid)
	--回复 + 广播
	self.target_:sendMsg(msg.NameToId.ReleaseResponse, {status = 1;})

	self:_broacastVote()
end

--投票
function release:onReleaseDoVote(uid, data)
	if not self.m_vote then 
		self.target_:sendMsg(msg.NameToId.ReleaseResponse, {status = -421;}, uid)
		return
	end 

	local player     = self.target_:getPlayerByUid(uid)
	local seat       = player.seat
	local vote_value = data.vote_value

	if vote_value == const.ReleaseVote.REFUSE then 
		self.target_:sendMsg(msg.NameToId.ReleaseResponse, {status = 0;}, uid)
		self:_onRefuse(seat, vote_value)
	elseif vote_value == const.ReleaseVote.AGREE then
		self.target_:sendMsg(msg.NameToId.ReleaseResponse, {status = 0;}, uid) 
		self:_onAgree(seat, vote_value)
	else
		self.target_:sendMsg(msg.NameToId.ReleaseResponse, {status = -422;}, uid)
		return 
	end 

end

function release:_getVoteRemainSeconds()
	return COUNT_DOWN_TIME - (os.time() - self.m_vote.start_time);
end 

function release:_initVote(uid)
	
	local t = {}

	t.result     = const.ReleaseVoteResult.VOTING
	t.start_time = os.time()
	
	local player = self.target_:getPlayerByUid(uid)
	t.seat       = player.seat

	t.votes      = {}
	local num    = self.target_:getCurPlayerNum()
	for seat=0,num-1 do
		t.votes[seat+1] = ( (seat == player.seat) and const.ReleaseVote.AGREE or const.ReleaseVote.NONE)
	end

	t.cancel     = cancelable_timeout(COUNT_DOWN_TIME*100, function ()
		--倒计时结束
		self.m_vote.result = const.ReleaseVoteResult.SUCCESS
		--over
		--标记GameOver原因 
		self.target_:setGameFinishReason(const.GameFinishReason.PLAYER_VOTE_RELEASE);
		--大结算 销毁table
		self.target_:destroy()		
	end)

	self.m_vote = t
end 

function release:_broacastVote()
	local info = self:getReleaseInfo()
	self.target_:broadcastMsg(msg.NameToId.ReleasePush,{release_info = info})
end

function release:_onAgree(seat, value)
	self.m_vote.votes[seat+1] = value
	--
	local isAllAgree = true
	for i,v in ipairs(self.m_vote.votes) do
		if v ~= const.ReleaseVote.AGREE then 
			isAllAgree = false
			break
		end 
	end
	--
	if isAllAgree then 
		self.m_vote.result = const.ReleaseVoteResult.SUCCESS
		--广播投票结果
		self:_broacastVote()
		--标记GameOver原因 
		self.target_:setGameFinishReason(const.GameFinishReason.PLAYER_VOTE_RELEASE);
		--大结算 销毁table
		self.target_:destroy()	
	else
		self:_broacastVote() 
	end 
end

function release:_onRefuse(seat, value)
	self.m_vote.votes[seat+1] = value
	self.m_vote.result = const.ReleaseVoteResult.FAILED
	self:_broacastVote()

	if self.m_vote.cancel then 
		self.m_vote.cancel()
	end 
	self.m_vote = nil
end

function release:getReleaseInfo()
	if not self.m_vote then 
		return nil 
	end 

	local data = {
		result     = self.m_vote.result;
		votes      = self.m_vote.votes;
		seat_index = self.m_vote.seat;
		time       = self:_getVoteRemainSeconds()		
	}

	return data
end



return release
