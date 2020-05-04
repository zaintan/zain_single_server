local Super         = require "base.mode.UserMgr"
local UserMgr       = class(Super)

local LOGTAG        = "[UserMgr]"
local subconst      = require("sub_logic.poke.dezhou.subconst")

function UserMgr:_createUser()
	return new(require("sub_logic.poke.dezhou.User"), self.m_pTable)
end

--userinfo.user_id
function UserMgr:onJoinReq( node, addr ,userinfo)
	Log.i(LOGTAG,"UserMgr:onJoinReq node=%s",tostring(node))
	
	if self.m_curUserNum >= self.m_maxUserNum then 
		Log.w(LOGTAG,"table is full![%d/%d]", self.m_curUserNum, self.m_maxUserNum)
		self:_rspJoinFail(node, addr, g_createMsg(MsgCode.JoinFailedFull))
		return false
	end 

	if not userinfo or not userinfo.user_id then 
		Log.e(LOGTAG,"invalid args: userinfo")
		self:_rspJoinFail(node, addr, g_createMsg(MsgCode.JoinFailedArgs))
		return false
	end 

	local u = self:getUser(userinfo.user_id)
	if u then 
		Log.e(LOGTAG,"repeated add user")
		self:_rspJoinFail(node, addr, g_createMsg(MsgCode.JoinFailedRepeat))
		return false
	end 

	Log.i(LOGTAG,"add user uid:%d name:%s",userinfo.user_id, userinfo.user_name)
	self.m_curUserNum = self.m_curUserNum + 1

	local u = self:_createUser()
	u:parse(userinfo)
	u:setStatus(subconst.UserStatus.Up)
	u:setSeat(-1)--先旁观状态
	u:setAddr(node, addr)
	u:setOnline(true)	
	self.m_users[userinfo.user_id] = u
	--广播通知其他人 玩家加入房间
	self:_broadcastToOthersUserEnter(u)
	--回复该玩家成功加入
	self:_rspJoinSucc(u)
	--发送给该玩家房间信息
	self:_sendRoomContentMsg(msg.NameToId.TableInfoPush, self.m_pTable:getTableInfo(), u)
	return true
end


--请求站起/坐下
function UserMgr:onStandSitReq( uid, data )
	local u = self:getUser(uid)
	if not u then 
		Log.e(LOGTAG,"can't find user by uid:%d",uid)
		return false
	end 

	if data.type ~= subconst.StandSitReqType.Up and data.type ~= subconst.StandSitReqType.Down then 
		Log.w(LOGTAG,"invalid standsitreq type:%d from uid:%d", data.type, uid)
		return false
	end 

	local curStatus = u:getStatus()
	if data.type == subconst.StandSitReqType.Up then --弃牌才可以站起
		--已经开始 还没有弃牌 无法站起
		if self.m_pTable:isGamePlay() and not u:canUp() then 
			Log.w(LOGTAG,"is already playing! the status:%d cann't stand up!", curStatus)
			return false
		end 	
		u:setStatus(subconst.UserStatus.Up)
		u:setSeat(-1)
		u:setReady(false)
		self:_broadcastUserRefresh(u)
	else--坐下
		if curStatus ~= subconst.UserStatus.Up then 
			Log.w(LOGTAG,"cann't sit down! curStatus isn't up status!")
			return false
		end 
		u:setStatus(subconst.UserStatus.DownWait)
		local seat = self:_getEmptySeat()
		if not seat then 
			Log.w(LOGTAG,"maybe error! can't find empty seat to sit down!")
			return false
		end 		
		u:setSeat(seat)
		u:setReady(true)
		self:_broadcastUserRefresh(u)
		self:_checkGameStart()
	end 	
	return true
end 

--请求携带筹码
function UserMgr:onBringChipsReq(uid,  data)
	local u = self:getUser(uid)
	if not u then 
		Log.e(LOGTAG,"can't find user by uid:%d",uid)
		return false
	end 	
	--data.chip
	u:bringChips(data.chip)
	-- body
	self:_broadcastUserRefresh(u)
	return true
end

function UserMgr:_canGameStart()--full and all readyed 
	return self.m_curUserNum == self.m_maxUserNum and self.m_curUserNum > 2 and self:_isAllReady()
end

--检查生效 上局牌局中带入的筹码
--function UserMgr:checkEffectBringChips()
--	----检查带入筹码
--	for _,u in pairs(self.m_users) do
--		u:checkEffectBringChips()
--	end
--end

function UserMgr:onRoundBegin()
	for _,u in pairs(self.m_users) do
		u:onRoundBegin()
	end
end

--确定这轮参与玩家
function UserMgr:makeSurePlayUsers()
	local allPlaySeats = {}
	for _,u in pairs(self.m_users) do
		--重置玩家状态
		if u:getSeat() == -1 then -- up
			u:setStatus(subconst.UserStatus.Up)
		else --down
			if u:getCurChip() > 0 then 
				u:setStatus(subconst.UserStatus.DownPlayWait)
				table.insert(allPlaySeats, u:getSeat())
			else --无筹码 无法参与
				u:setStatus(subconst.UserStatus.DownWait)
			end 
		end 
	end
	table.sort(ret, function ( a, b )
		return a < b
	end)	
	return allPlaySeats
end

return UserMgr