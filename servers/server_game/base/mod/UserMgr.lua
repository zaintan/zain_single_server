--
local UserMgr  = class()
--
local ClusterHelper = require "ClusterHelper"

local LOGTAG = "[UserMgr]"

function UserMgr:ctor(pTable, maxUserNum)
	--
	self.m_pTable     = pTable
    -- k:uid  v: RoomPlayer
    self.m_users      = {}
    --
    self.m_curUserNum = 0
    --
	self.m_maxUserNum = maxUserNum or 4
end

function UserMgr:dump()
	-- body
end

--当前房间内人数
function UserMgr:getCurUserNum()
	return self.m_curUserNum
end

--房间最大容纳人数
function UserMgr:setFixedUserNum( num )
	self.m_maxUserNum = num or self.m_maxUserNum
end


function UserMgr:setAllReady( bState )
	for uid,u in pairs(self.m_users) do
		u:setReady(bState)
	end
end

function UserMgr:_isAllReady()
	for _,u in pairs(self.m_users) do
		if not u:isReady() then 
			return false
		end 
	end
	return true
end

function UserMgr:_canGameStart()--full and all readyed 
	return self.m_curUserNum == self.m_maxUserNum and self:_isAllReady()
end

function UserMgr:_checkGameStart()
	if self:_canGameStart() then 
		self.m_pTable:changeToGamePlay()
	end 
end


function UserMgr:getUser( uid )
	assert(uid and type(uid) == "number")
	return self.m_users[uid]
end

function UserMgr:getUserBySeat( seat )
	assert(seat and type(seat) == "number")

	for _,u in pairs(self.m_users) do
		if u:getSeat() == seat then 
			return u
		end 
	end
	return nil
end

--获取空座位号
function UserMgr:_getEmptySeat()
	for seat=0,self.m_maxUserNum-1 do
		local bUsed = false
		for _,u in pairs(self.m_users) do
			if u:getSeat() == seat then
				bUsed = true
				break
			end 
		end
		if not bUsed then 
			return seat 
		end 
	end
	return nil
end

function UserMgr:_createUser()
	return new(require("base.BaseUser"))
end

--回复玩家加入成功
function UserMgr:_rspJoinSucc(u)
	local statusInfo = MsgCode.JoinSuccess
	--
	local data  = {
		status         = statusInfo[1];
		status_tip     = statusInfo[2];
		game_base_info = self.m_pTable:getGameBaseInfo();		
	}

	local node,addr = u:getAddr()
	--回复该玩家加入房间的信息
	ClusterHelper.callIndex(node,addr,"sendMsg", msg.NameToId.JoinRoomResponse, data)
end

--回复玩家加入失败
function UserMgr:_rspJoinFail(node, addr, msgcode)
	local data = {
		status     = msgcode[1];
		status_tip = msgcode[2] or "";
	}
	ClusterHelper.callIndex(node,addr,"sendMsg", msg.NameToId.JoinRoomResponse, data)
end

--回复玩家退出
function UserMgr:_rspExit(user, msgcode)
	local data = {
		status     = msgcode[1];
		status_tip = msgcode[2] or "";
	}
	ClusterHelper.callIndex(node,addr,"sendMsg", msg.NameToId.UserExitResponse, data)
end

function UserMgr:sendMsgByUid(cmd, data, uid)
	local u = self:getUser(uid)
	if not u then 
		Log.e(LOGTAG,"sendMsgByUid failed! can't find user by uid:%d",uid)
		return
	end 
	self:_sendRoomContentMsg(cmd, data, u)
end

function UserMgr:sendMsgBySeat( cmd, data, seat )
	local u = self:getUserBySeat(seat)
	if not u or seat < 0 then 
		Log.e(LOGTAG,"sendMsgBySeat failed! can't find user by uid:%d",uid)
		return
	end 
	self:_sendRoomContentMsg(cmd, data, u)
end


function UserMgr:_sendRoomContentMsg( cmd, data, u )
	local sendData  = self.m_pTable:encodeRoomContentRsp(cmd, data)
	local node,addr = u:getAddr()
	if node and addr then 
		local ok = ClusterHelper.callIndex(node, addr, "sendMsg", msg.NameToId.RoomContentResponse, sendData)
		if not ok then 
			Log.e(LOGTAG,"_sendRoomContentMsg fail! id=%d,node=%s,addr=%s",u:getId(), tostring(node),tostring(addr)) 
			u:setAddr(nil, nil)
			u:setOnline(false)
		end 		
	end 
end


function UserMgr:broadcastMsg(cmd, data, except_uid)
	for _,u in pairs(self.m_users) do
		if not(except_uid and except_uid == u:getId() ) then 
			self:_sendRoomContentMsg(cmd, data, u)
		end 
	end
end

function UserMgr:broadcastMsgBySeat(cmd, data, except_seat)
	for _,u in pairs(self.m_users) do
		if not(except_seat and except_seat == u:getSeat() ) then 
			self:_sendRoomContentMsg(cmd, data, u)
		end 
	end
end

--广播通知其他玩家  有玩家进入房间
function UserMgr:_broadcastToOthersUserEnter(u)
	--
	local data   = {
		user_base_info = u:encodeBase();
		user_info      = u:encode();
	}
	--
	local except_uid = u:getId()
	--
	self:broadcastMsg(msg.NameToId.UserEnterPush, data, except_uid)
end
--广播通知其他玩家  有玩家退出房间
function UserMgr:_broadcastToOthersUserExit(u)
	local data = {
		user_id = u:getId()
	}
	local except_uid = u:getId()
	self:broadcastMsg(msg.NameToId.UserExitPush, data, except_uid)
end
--广播通知其他玩家  有玩家信息刷新
function UserMgr:_broadcastToOthersUserRefresh(u)
	local data = {
		user_info = {u:encode();}
	}
	local except_uid = u:getId()
	self:broadcastMsg(msg.NameToId.UserInfoPush, data, except_uid)
end
--广播通知所有玩家  有玩家信息刷新
function UserMgr:_broadcastUserRefresh( u )
	local data = {
		user_info = {u:encode();}
	}
	self:broadcastMsg(msg.NameToId.UserInfoPush, data)
end
--广播通知所有玩家  所有玩家信息刷新
function UserMgr:_broadcastAllUsersRefresh()
	local data = {
		user_info = self:getAllUserInfo();
	}
	self:broadcastMsg(msg.NameToId.UserInfoPush, data)
end

function UserMgr:getAllUserBaseInfo()
	local ret = {}
	for _,u in pairs(self.m_users) do
		table.insert(ret, u:encodeBase())
	end	
	return ret
end
function UserMgr:getAllUserInfo()
	local ret = {}
	for _,u in pairs(self.m_users) do
		table.insert(ret, u:encode())
	end	
	return ret
end

--userinfo.user_id
function UserMgr:onJoinReq( node, addr ,userinfo)
	Log.i("","UserMgr:onJoinReq node=%s",tostring(node))

	if self.m_pTable:isGameStart() then 
		Log.i("","Table is already start! can't join!")
		self:_rspJoinFail(node, addr, MsgCode.JoinFailedStart)
		return false
	end 

	if not userinfo or not userinfo.user_id then 
		Log.e(LOGTAG,"invalid args: userinfo")
		self:_rspJoinFail(node, addr, MsgCode.JoinFailedArgs)
		return false
	end 

	local u = self:getUser(userinfo.user_id)
	if u then 
		Log.e(LOGTAG,"repeated add user")
		self:_rspJoinFail(node, addr, MsgCode.JoinFailedRepeat)
		return false
	end 

	if self.m_curUserNum >= self.m_maxUserNum then 
		Log.w(LOGTAG,"table is full![%d/%d]", self.m_curUserNum, self.m_maxUserNum)
		self:_rspJoinFail(node, addr, MsgCode.JoinFailedFull)
		return false
	end 

	local seat = self:_getEmptySeat()
	if not seat then 
		Log.i(LOGTAG,"can't find seat!")
		self:_rspJoinFail(node, addr, MsgCode.JoinFailedFull)
		return false
	end  

	Log.i(LOGTAG,"add user uid:%d name:%s",userinfo.user_id, userinfo.user_name)
	self.m_curUserNum = self.m_curUserNum + 1

	local u = self:_createUser()
	u:parse(userinfo)
	u:setSeat(seat)
	u:setAddr(node, addr)
	u:setOnline(true)	
	self.m_users[userinfo.user_id] = u
	--广播通知其他人 玩家加入房间
	self:_broadcastToOthersUserEnter(u)
	--回复该玩家成功加入
	self:_rspJoinSucc(u)
	--发送给该玩家房间信息
	self:_sendMsg(msg.NameToId.RoomInfoPush, self.m_pTable:getTableInfo(), u)
	return true
end


--
function UserMgr:onExitReq( uid, data )
	local u = self:getUser(uid)
	if not u then 
		--出错了  转发进来错了----修正
		Log.e(LOGTAG,"can't find user by uid:%d",uid)
		--找不到 通知->AllocServer清掉  --agent
		self.m_pTable:callAllocServer("exit", uid,  self.m_pTable:getTableId())
		return false
	end 
	--
	if self.m_pTable:isGameStart() then 
		self:_rspExit(u, MsgCode.ExitFailed)
		return false
	end 
	--
	self.m_curUserNum = self.m_curUserNum - 1
	--回复该玩家离开成功
	self:_rspExit(u, MsgCode.ExitSuccess)
	--广播通知其他人 玩家离开房间
	self:_broadcastToOthersUserExit(u)
	--清空该玩家
	self.m_users[uid] = nil
	--
	--通知->AllocServer清掉  --agent
	self.m_pTable:callAllocServer("exit", uid,  self.m_pTable:getTableId())
	--
	return true
end

function UserMgr:onReconnectReq(fromNodeIndex, fromAddr, uid)
	local u = self:getUser(uid)
	if not u then 
		self:dump()
		Log.e(LOGTAG,"can't find uid=%d",uid)
		self:_rspJoinFail(fromNodeIndex, fromAddr, MsgCode.ReconnectFailed)
		return false
	end 
	--更新玩家节点信息
	u:setAddr(fromNodeIndex, fromAddr)
	u:setOnline(true)
	--广播玩家重连上线
	self:_broadcastToOthersUserRefresh(u)
	--回复玩家 加入房间成功
	self:_rspJoinSucc(u)
	--发送给该玩家房间信息
	self:_sendMsg(msg.NameToId.RoomInfoPush, self.m_pTable:getTableInfo(), u)
	return true
end

--玩家下线 登出
function UserMgr:onUserLogout(fromNode, fromAddr, uid)
	--Log.i(LOGTAG,"users logout uid = %d %d,%d",uid, fromNode, fromAddr)
	local u = self:getUser(uid)
	if not u then 
		Log.e(LOGTAG,"can't find user by uid:%d",uid)
		return false
	end 
	--
	local curNode,curAddr = u:getAddr()
	if curNode == fromNode and curAddr == fromAddr then 
		u:setAddr(nil, nil)
		u:setOnline(false)
		--广播玩家 上下线状态
		self:_broadcastToOthersUserRefresh(u)
	end 
	--
	return true
end

function UserMgr:onReadyReq( uid , data )
	local u = self:getUser(uid)
	if not u then 
		--出错了  转发进来错了----修正
		Log.e(LOGTAG,"can't find user by uid:%d",uid)
		return false
	end 
	--
	if self.m_pTable:isGamePlay() then 
		Log.i("","Table is already play! can't change ready state!")
		--self:_rspRoomReq(u, data.req_type ,-402)
		return false
	end
	--
	local ready =  data.req_content.ready
	--修改玩家准备状态 
	u:setReady(ready)
	--广播通知suoyou玩家
	self:_broadcastUserRefresh(u)
	--self:_broadcastToOthersUserRefresh(u)
	--回复该玩家成功
	--self:_rspRoomReq(u, data.req_type, 0)	
	--判断游戏是否开始
	if ready then 
		self:_checkGameStart()
	end 
	return true
end


function UserMgr:onRoundBegin()
	-- body
end

return UserMgr
