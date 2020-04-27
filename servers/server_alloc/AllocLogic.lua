------------------------------------------------------
---! @file
---! @brief AllocLogic, 管理GameServer 创建桌子 加入桌子 离开  解散
------------------------------------------------------
local skynet    = require "skynet"
require "skynet.manager"

---! 辅助依赖
local NumSet        = require "NumSet"
local ClusterHelper = require "ClusterHelper"

local AllocUser     = require "AllocUser"

local queue         = require "skynet.queue"
local cs            = queue()

local AllocLogic    = {}
local LOGTAG        = "AllocLogic"

--初始化容器
function AllocLogic:init()
	---! all tables:  k = table_id; v = table;
	self.m_tables = NumSet.create()
	---! all users:  k = user_id; v = table_id;
	self.m_users  = NumSet.create()

	self.m_idPool = new(require("TableIdPool")):init()
end


--玩家登陆后查询是否已经在房间
--!根据uid查询是否已经在房间里面了
function AllocLogic:queryTableId(uid)
	return cs(function ()
		local user = self.m_users:getObject(uid)
		if user then 
			local table_id  = user:getTableId()
			if table_id then 
				return table_id
			end 
		end	
		return -1
	end)
end


--玩家创建房间请求
function AllocLogic:create(data,userInfo)
	return cs(function ()
		local uid = userInfo.user_id

		Log.d(LOGTAG,"recv create req from uid:%d  reqData:",uid)
		Log.dump(LOGTAG, data)
		
		local user = self.m_users:getObject(uid)
		local limit = skynet.call(".NodeInfo", "lua", "getConfig", "createLimit")
		if user and not user:canCreateTable(limit) then 
			Log.i(LOGTAG,"uid=%d开房数量已达上限!",uid)
			return g_createMsg(MsgCode.CreateFailedLimit)
		end	  

		local table_id = self.m_idPool:allocId()
		--没使用 要记得回收房间号
		if not table_id then 
			Log.e(LOGTAG,"分配房间号失败!",uid)
			return g_createMsg(MsgCode.CreateFailedNoID)
		end 

		--call game_server
		--根据appid配置的逻辑服
		local appid = data.game_id or -1
		local server_index = skynet.call(".NodeInfo", "lua", "getConfig", "games", appid)
		if not server_index then 
			Log.e(LOGTAG,"appid=%d,找不到配置的逻辑服!",appid)
			self.m_idPool:recoverId(table_id)
			return g_createMsg(MsgCode.AllocFailedLinkGame)
		end 

        local ok, ret = ClusterHelper.callIndex(server_index, ".GameService","create",table_id,userInfo,data)
        if not ok then 
            Log.e(LOGTAG,"链接逻辑服%s失败!",tostring(server_index))
            self.m_idPool:recoverId(table_id)
            return g_createMsg(MsgCode.AllocFailedLinkGame)
        end  		
		---
		--创建成功
		if ret and ret.tableAddr then 
			if not user then 
				user = new(AllocUser):init(uid)
				self.m_users:addObject(user, uid)
			end 
			user:addCreatedTable(table_id)
			self.m_tables:addObject({addr = ret.tableAddr;index = server_index; creater = uid; uids = {};}, table_id)

			Log.i(LOGTAG, "用户uid=%d在服务器index=%d成功创建房间,tid=%d,gameid=%d",uid,server_index,table_id,appid)
			
			local ret   = g_createMsg(MsgCode.CreateSuccess)
			ret.room_id = table_id
			return ret  --{status = 1;room_id = table_id;}
		else 
			Log.e(LOGTAG,"创建房间失败!原因:%s",tostring(ret.err))
            self.m_idPool:recoverId(table_id)
            return g_createMsg(MsgCode.CreateFailedGameRet)		
		end
	end)
end

--玩家加入房间请求
function AllocLogic:join(data,fromNode,fromAddr,userinfo)
	return cs(function ()
		local uid = userinfo.user_id
		--判断用户是否已经加入过房间了  
		local user = self.m_users:getObject(uid)
		if user and not user:canJoinTable() then 
			--已经在房间里面了 返回重连消息
			local table_id  = user:getTableId()
			local tblInfo   = self.m_tables:getObject(table_id)

			--通知逻辑服重连
			local ok,ret = ClusterHelper.callIndex(tblInfo.index, tblInfo.addr,"reconnect",fromNode, fromAddr, uid)
			if not ok then 
				Log.i(LOGTAG,"uid=%d重连房间tid=%d逻辑服%d失败!",uid,table_id,tblInfo.index)
				ClusterHelper.callIndex(fromNode,fromAddr,"sendMsg",msg.NameToId.JoinRoomResponse,g_createMsg(MsgCode.AllocFailedLinkGame))
			end 

			Log.i(LOGTAG,"AllocServer join reconnect ret: {gameSvr=%s,tableAddr=%s}",tostring(tblInfo.index),tostring(tblInfo.addr))
			return { gameSvr = tblInfo.index; tableAddr = tblInfo.addr;}
			--return false
		end	

		--判断房间号存不存在
		local tblInfo = self.m_tables:getObject(data.room_id)
		if not tblInfo then 
			Log.e(LOGTAG,"AllocServer查不到该房间号%d!该房间已解散",data.room_id)
			ClusterHelper.callIndex(fromNode,fromAddr,"sendMsg",msg.NameToId.JoinRoomResponse,g_createMsg(MsgCode.JoinFailedReleased))
			return false
		end 

		--加入房间
		local callSucc,joinSucc = ClusterHelper.callIndex(tblInfo.index,tblInfo.addr, "join", fromNode,fromAddr, userinfo)
		if not callSucc then
			Log.d(LOGTAG,"链接逻辑服%d失败%s",tblInfo.index, tostring(joinSucc))
			ClusterHelper.callIndex(fromNode,fromAddr,"sendMsg",msg.NameToId.JoinRoomResponse,g_createMsg(MsgCode.AllocFailedLinkGame))
			return false
		end 

		if joinSucc then 
			if not user then 
				user = new(AllocUser):init(uid)
				self.m_users:addObject(user, uid)
			end 
			user:joinTable(data.room_id)
			table.insert(tblInfo.uids, uid)
			--成功加入房间  由逻辑服去回复消息给client
			Log.i(LOGTAG,"AllocServer join ret: {gameSvr=%s,tableAddr=%s}",tostring(tblInfo.index),tostring(tblInfo.addr))
			return { gameSvr = tblInfo.index; tableAddr = tblInfo.addr;}
		end 
		return false
	end)
end


--退出房间
--optional req_uid
function AllocLogic:exit(uid, tid)
	return cs(function ()
		local ret = true
		--
		local user = self.m_users:getObject(uid)
		if user then 
			user:joinTable(nil)
		else
			Log.d(LOGTAG,"maybe err!分配服找不到该玩家%d!",uid)
			ret = false
		end 
		local tblInfo = self.m_tables:getObject(tid)
		if tblInfo then 
			----------------------------------------------
			local findIndex = -1
			for i,v in ipairs(tblInfo.uids) do
				if v == tid then 
					findIndex = i 
					break
				end 
			end
			if findIndex == -1 then 
				Log.d(LOGTAG,"maybe err!tableInfo.uids找不到该玩家")
				ret = false			
			else
				table.remove(tblInfo.uids, findIndex) 	
			end 
			----------------------------------------------
			--[[不能强制逻辑服退出  会有问题  牌局开始后
			if bNotiGame then 
				local callSucc,err = ClusterHelper.callIndex(tblInfo.index, tblInfo.addr, "out_exit", uid)
				if not callSucc then
					Log.d(LOGTAG,"无法通知逻辑服,链接逻辑服%d失败%s",tblInfo.index, tostring(err))
					ret = false
				end	
			end 
			]]

		else
			Log.d(LOGTAG,"maybe err!分配服找不到该房间%d!",tid)
			ret = false			
		end 
		return ret
	end)
end
--解散房间
--optional req_uid
function AllocLogic:release(tid, bNotiGame)
	return cs(function ()
		--------------------
		local tblInfo = self.m_tables:getObject(tid)
		if tblInfo then 
			----------------------------------------------
			--清掉加入信息
			for _,v in ipairs(tblInfo.uids) do
				local user = self.m_users:getObject(v)
				if user then 
					user:joinTable(nil)
				else
					Log.d(LOGTAG,"maybe err!分配服找不到该玩家%d!",v)
				end 
			end
			--清掉创建信息
			local userCreater = self.m_users:getObject(tblInfo.creater)
			if not (userCreater and userCreater:removeCreatedTable(tid)) then 
				Log.e(LOGTAG,"maybe err! 清楚创建者信息失败")
			end
			--
			local gameIndex,gameAddr = tblInfo.index,tblInfo.addr
			----回收id
			self.m_idPool:recoverId(tid)
			--清掉桌子信息
			self.m_tables:removeObject(tid)
			----------------------------------------------
			if bNotiGame then 
				local callSucc,err = ClusterHelper.callIndex(gameIndex,gameAddr,"release")
				if not callSucc then
					Log.d(LOGTAG,"无法通知逻辑服,链接逻辑服%d失败%s",tblInfo.index, tostring(err))
					return false
				end	
			end 
		else
			Log.d(LOGTAG,"maybe err!分配服找不到该房间%d!",tid)
			return false	
		end 
	end)
end

return AllocLogic