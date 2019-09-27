--behaviors.users
--管理玩家个人信息  准备状态
local Super           = require("behaviors.behavior")
local users           = class(Super)

local ClusterHelper   = require "ClusterHelper"
local LOGTAG = "users"

users.EXPORTED_METHODS = {
	"setReadyState",
	"resetAllReadyState",
	"isAllReady",
	"playerNumCanStart",
	"tidySeat",--整理座位 第一把开始前
	--
    "setMaxPlayerNum",
    "getMaxPlayerNum",

    "getCurPlayerNum",
    "parseUserInfo",
    "addPlayer",
    "delPlayer",
    "getPlayerBySeat",
    "getPlayerByUid",
    "sendMsgBySeat",
    "sendMsg",
    "broadcastMsgBySeat",
    "broadcastMsg",

    "getPlayersInfo",

    "playerReconnect",
    "logout",      
}

function users:_pre_bind_(...)
    self.m_players      = {}
    self.m_curPlayerNum = 0
    self.m_maxPlayerNum = 1
end

function users:_clear_()
    self.target_    = nil
    self.m_players  = nil
end

--少人模式需特殊处理
function users:playerNumCanStart()
	return self.m_curPlayerNum == self.m_maxPlayerNum
end

function users:setMaxPlayerNum(num)
	Log.i(LOGTAG,"users:setMaxPlayerNum = %d",num)
	self.m_maxPlayerNum = num
end


function users:getMaxPlayerNum()
	assert(self.m_maxPlayerNum ~= nil)
	return self.m_maxPlayerNum
end


function users:getCurPlayerNum()
	return self.m_curPlayerNum
end

function users:parseUserInfo( userInfo )
	local ret = {}
	ret.user_id      = userInfo.user_id
	ret.user_name    = userInfo.user_name
	ret.head_img_url = userInfo.head_img_url

	ret.ready        = false
	return ret
end


function users:_getEmptySeat()
	for i=0,self.m_maxPlayerNum-1 do
		local bUsed = false
		for _,v in pairs(self.m_players) do
			if v.seat == i then
				bUsed = true
				break
			end 
		end
		if not bUsed then 
			return i 
		end 
	end
	return nil
end


function users:_isNeedTidySeat()
	for _,v in pairs(self.m_players) do
		if v.seat >= self.m_curPlayerNum then 
			return true
		end 
	end
	return false
end

function users:tidySeat()
	local bNeedTidy = self:_isNeedTidySeat()
	if not bNeedTidy then 
		return self.target_
	end 
	--需要调整
	local players = {}
	for _,v in pairs(self.m_players) do
		table.insert(players,v)
	end
	table.sort(players,function (a,b)
		return a.seat < b.seat
	end)
	for i,v in ipairs(players) do
		v.seat = i-1
	end
	--调整完通知客户端
	self:_notifyAllPlayersSeat()
	return self.target_
end


function users:addPlayer(agentNode, agentAddr, uid , data)
	local player = self.m_players[uid]
	if player then 
		Log.i(LOGTAG,"重复添加玩家uid = %d",uid)
		return -1
	end 

	if self.m_curPlayerNum >= self.m_maxPlayerNum then 
		Log.i(LOGTAG,"桌子已满! %d/%d",self.m_curPlayerNum,self.m_maxPlayerNum)
		return -2
	end 

	local seat = self:_getEmptySeat()
	if not seat then 
		Log.i(LOGTAG,"获取不到空的座位号!")
		return -3
	end 

	Log.i(LOGTAG,"users addPlayer uid = %s",tostring(uid))

	local p     = self:parseUserInfo(data)
	p.agentNode = agentNode
	p.agentAddr = agentAddr
	p.seat      = seat
	p.online    = true
	self.m_players[uid] = p
	Log.dump(LOGTAG,p)
	--广播通知其他人 玩家加入房间
	self:_notifyPlayerEnter(p)
	--
	return 0
end

--	self.m_pTable:sendMsg(uid,msg_id+msg.ResponseBase, {status = 1;})

function users:delPlayer(uid)
	local player = self.m_players[uid]
	if not player then 
		Log.i(LOGTAG,"无法移除,找不到该玩家uid = %d",uid)
		return -1
	end 
	--回复该玩家离开成功
	self:sendMsg(msg.NameToId.PlayerExitResponse,{status = 1;}, uid)
	--广播通知其他人 玩家离开房间
	self:_notifyPlayerExit(player)
	--清空该玩家
	self.m_players[uid] = nil
end

function users:getPlayerBySeat(seat_index)
	for _,v in pairs(self.m_players) do
		if v.seat == seat_index then 
			return v
		end 
	end
	return nil
end

function users:getPlayerByUid(uid)
	return self.m_players[uid]
end


--待优化处理 --发送失败后重置agentNode agentAddr 
--并通知代理服下线 =.= 好像无法通知
function users:_send(player, msg_id, msg_data)
	if player.agentNode and player.agentAddr then 
		local ok = ClusterHelper.callIndex(player.agentNode, player.agentAddr, "sendMsg", msg_id, msg_data)
		if not ok then 
			Log.e(LOGTAG,"maybe err!发送消息失败!uid=%s,agentNode=%s,agentAddr=%s",tostring(player.user_id),tostring(player.agentNode),tostring(player.agentAddr)) 
			player.agentAddr = nil
			player.agentNode = nil
			player.online    = false
		end 
	end
end
--
function users:sendMsgBySeat(msg_id, msg_data, seat)
	local player = self:getPlayerBySeat(seat)
	if player then 
 	    self:_send(player, msg_id, msg_data)
	else
		Log.e(LOGTAG,"maybe err!发送消息失败!seat=%d不存在玩家",seat) 
	end 
end

function users:broadcastMsgBySeat(msg_id, msg_data, except_seat)
	for _,player in pairs(self.m_players) do
		if not(except_seat and except_seat == player.seat) then
			self:_send(player, msg_id, msg_data)
		end   
	end
end

function users:sendMsg(msg_id, msg_data, uid)
	local player = self:getPlayerByUid(uid)
	if player then 
 	    self:_send(player, msg_id, msg_data)
	else
		Log.e(LOGTAG,"maybe err!发送消息失败!uid=%s不存在玩家",tostring(uid)) 
	end 
end

function users:broadcastMsg(msg_id, msg_data, except_uid)
	for uid,player in pairs(self.m_players) do
		if not(except_uid and except_uid == uid) then
			self:_send(player, msg_id, msg_data)
		end   
	end
end


function users:setReadyState(uid, bReady)
	local player = self:getPlayerByUid(uid)
	if player then 
		player.ready = bReady and true or false
		--
		self:sendMsg(msg.NameToId.ReadyResponse, {status = 0; ready = bReady;}, uid)
		--通知其他玩家
        self:_notifyPlayerReady(player)
	else 
		Log.e(LOGTAG,"maybe err! uid=%d not in table!",uid)
	end 
end

function users:resetAllReadyState(bValue, bBroadcast)
	for _,v in pairs(self.m_players) do
		v.ready = bValue
	end

	if bBroadcast then 
		self:_notifyAllPlayersReady()
	end 
end

function users:isAllReady()
	for v in pairs(self.m_players) do
		if not v.ready then 
			return false
		end 
	end
	return true
end

function users:logout(fromNodeIndex, selfAddr, uid)
	Log.i(LOGTAG,"users logout uid = %s %s,%s",tostring(uid), tostring(fromNodeIndex), tostring(selfAddr))
	local player = self.m_players[uid]
	if player then 
		if player.agentNode == fromNodeIndex and player.agentAddr == selfAddr then
			player.agentAddr = nil 
			player.agentNode = nil 
			player.online    = false

			
			self:_notifyOnOffLine(player)
		end 
	end
	return true
end

function users:playerReconnect(fromNodeIndex, fromAddr, uid)
	Log.i(LOGTAG,"users playerReconnect uid = %s  fromAddr:%s,%s",tostring(uid),tostring(fromNodeIndex),tostring(fromAddr))
	local player = self.m_players[uid]
	if player then 
		player.agentAddr = fromAddr
		player.agentNode = fromNodeIndex
		player.online    = true
		--广播其他玩家
		self:_notifyOnOffLine(player)
		Log.dump(LOGTAG,self.m_players)
		return true
	end
	return false
end

function users:getPlayersInfo()
	local data = {}
	for _, player in pairs(self.m_players) do 
		table.insert(data, self:_encodePlayer(player))
	end 
	return data
end

--[[
	player.ready = data.ready
	self.m_pTable:sendMsg(uid, msg.NameToId.ReadyResponse, {status = 0;ready = data.ready;})
	
	local push_data = {
		ready_infos = {{seat_index = player.seat_index;ready = data.ready;}}
	}
	self.m_pTable:broadcastMsg(msg.NameToId.ReadyPush, push_data, uid)
	

]]
--广播其他玩家  玩家准备
function users:_notifyPlayerReady(player)
	-- body
	local data = {
		ready_infos = {
			{
				seat_index = player.seat_index;
				ready      = player.ready;
			};
		};
	};
	self:broadcastMsg(msg.NameToId.ReadyPush, data, player.user_id)
end

--广播其他玩家  玩家上下线
function users:_notifyOnOffLine(player)
	-- body
end

--刷新所有玩家座位信息
function users:_notifyAllPlayersSeat()
	local data = {
		ready_infos = {}
	}

	local info = {}
	for uid, player in pairs(self.m_players) do 
		local item = {}
		item.seat_index = player.seat
		item.ready      = player.ready
		table.insert(info, item)
	end 
	local data = {}
	data.ready_infos = info
	self:broadcastMsg(msg.NameToId.ReadyPush, data)
end

--刷新所有玩家准备状态
function users:_notifyAllPlayersReady()
	-- body
end

--广播通知其他玩家  玩家进入
function users:_notifyPlayerEnter(player)
	local data = {}
	data.player = self:_encodePlayer(player)
	self:broadcastMsg(msg.NameToId.PlayerEnterPush,data,player.user_id)
end

--广播通知其他玩家  玩家离开
function users:_notifyPlayerExit(player)
	local data = {
		seat_index = player.seat;
	}
	self:broadcastMsg(msg.NameToId.PlayerExitPush,data,player.user_id)
end

function users:_encodePlayer(player)
	local data = {}
	data.user_id      = player.user_id
	data.user_name    = player.user_name
	data.head_img_url = player.head_img_url
	data.seat_index   = player.seat
	data.ready        = player.ready
	data.score        = self.target_:getCurScoreBySeat(player.seat)
	--player.score or 0
	return data
end

return users
