local Super         = require "base.mode.UserMgr"
local UserMgr       = class(Super)

local LOGTAG = "[UserMgr]"

function UserMgr:_createUser()
	return new(require("subgame.poke.dezhou.User"))
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
		return false
	end 



end 

--请求携带筹码
function UserMgr:onBringChipReq(uid,  data)
	-- body
end


function UserMgr:checkEffectBringChips()
	----检查带入筹码
	for _,u in pairs(self.m_users) do
		u:checkEffectBringChips()
	end
end

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