------------------------------------------------------
---! @file
---! @brief BaseState
------------------------------------------------------
local ClusterHelper = require "ClusterHelper"

local Super     = require("abstract.BaseContainer")
local BaseState = class(Super)

function BaseState:ctor(pTable, status)
	self.m_pTable = pTable
	self.m_status = status
	
	self:onInit()
end

function BaseState:getStatus()
	return self.m_status
end

function BaseState:onInit()
	-- body
end


function BaseState:onEnter()
	Log.i("","State:%d onEnter",self.m_status)
end

function BaseState:onExit()
	Log.i("","State:%d onExit",self.m_status)
end


local function _retDefaultMsg(uid, msg_id)
	self.m_pTable:sendMsg(msg_id + msg.ResponseBase , {status = -401;}, uid)
	return false
end


function BaseState:onReadyReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseState:onOutCardReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseState:onOperateCardReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseState:onPlayerExitReq(uid, msg_id, data)
	return _retDefaultMsg(uid, msg_id)
end

function BaseState:onReleaseReq(uid, msg_id, data)
	local player = self.m_pTable:getPlayerByUid(uid)
	if not player then 
		Log.e("","maybe err!牌局找不到该玩家 uid=%d",uid, self.m_pTable:getTableId())
		return false
	end 

	if data.type == const.ReleaseRequestType.RELEASE then
		--发起投票
		return self.m_pTable:onReleaseStartVote(uid, data)
	elseif data.type == const.ReleaseRequestType.VOTE then
		--投票
		return self.m_pTable:onReleaseDoVote(uid, data)
	else --未知请求
		Log.e("","maybe err!未知解散请求 uid=%d data.type=%d",uid, data.type)
		return _retDefaultMsg(uid, msg_id)
	end 
end

function BaseState:onJoin(node, addr, userinfo)
	Log.i("","牌局已经开始,无法加入! uid=%d,tid=%d",userinfo.FUserID, self.m_pTable:getTableId())
	ClusterHelper.callIndex(node,addr,"sendMsg",msg.NameToId.JoinRoomResponse,{status = -402;})
	return false
end

function BaseState:broadcastGameOver()
	-- body
end

return BaseState