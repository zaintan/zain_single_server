------------------------------------------------------
---! @file
---! @brief ReleaseVote
------------------------------------------------------
local ReleaseVote = class()

---! 依赖库
local skynet       = require "skynet"

local COUNT_DOWN_TIME = 150--seconds

function ReleaseVote:init(pTable,source,callback)
	self.m_pTable      = pTable
	self.m_player_num  = pTable:getCurPlayerNum()
	self.m_source_seat = source 

	self.m_result   = const.ReleaseVoteResult.VOTING
	self.m_callback = callback

	self.m_votes   = {}
	self:__resetVotes()

	skynet.timeout(COUNT_DOWN_TIME*100,function ()
		if self.m_bClear then 
			return
		end 

		self.m_result = const.ReleaseVoteResult.SUCCESS
		self:_over()
	end)
end

function ReleaseVote:handleReleaseReq(player , data, msg_id)
	--发起者
	self.m_votes[player.seat_index+1] = const.ReleaseVote.AGREE
	self.m_pTable:sendMsg(player.user_id, msg_id+msg.ResponseBase, {status = 1;})	
	self.m_pTable:broadcastMsg(msg.NameToId.ReleasePush,{result = const.ReleaseVoteResult.VOTING;votes = self.m_votes;})
end

function ReleaseVote:handleVoteReq(player, data, msg_id)
	self.m_votes[player.seat_index+1] = data.vote_value
	if data.vote_value == const.ReleaseVote.REFUSE then --拒绝
		self.m_pTable:sendMsg(player.user_id, msg_id+msg.ResponseBase, {status = 1;})
		self.m_result = const.ReleaseVoteResult.FAILED
		self:_broadcastVoteResult()
		self:_over()
	elseif data.vote_value == const.ReleaseVote.AGREE then --同意
		self.m_pTable:sendMsg(player.user_id, msg_id+msg.ResponseBase, {status = 1;})
		if self:__isAllAgreeRelease() then 
			self.m_result = const.ReleaseVoteResult.SUCCESS
			self:_broadcastVoteResult()
			self:_over()
		else 
			self:_broadcastVoteResult()
		end 
	else 
		self.m_pTable:sendMsg(player.user_id, msg_id+msg.ResponseBase, {status = -100;status_tip="无效投票类型"})
	end 
end

function ReleaseVote:_broadcastVoteResult()
	self.m_pTable:broadcastMsg(msg.NameToId.ReleasePush,{result = self.m_result;votes=self.m_votes;})
end

function ReleaseVote:_over()
	self:__clearTimer()
	self.m_callback(self.m_result)	
end


function ReleaseVote:__isAllAgreeRelease()
	for i=1,self.m_player_num do
		local vote = self.m_votes[i]
		if vote and vote ~= const.ReleaseVote.AGREE then
			return false
		end 
	end
	return true
end

function ReleaseVote:__resetVotes()
	for i=1,self.m_player_num do
		self.m_votes[i] = const.ReleaseVote.NONE
	end
end

function ReleaseVote:__clearTimer()
	self.m_bClear = true
end


return ReleaseVote

