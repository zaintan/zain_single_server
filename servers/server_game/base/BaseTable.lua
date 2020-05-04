------------------------------------------------------
---! @file
---! @brief BaseTable
------------------------------------------------------
local BaseTable     = class()
local skynet        = require "skynet"
local ClusterHelper = require "ClusterHelper"

local LOGTAG        = "BaseTable"


function BaseTable:ctor(tid,userInfo,data)

	self.m_gameBaseInfo = {
		game_id    = data.game_id;--子游戏Id
		game_type  = data.game_type;--子玩法Id
		room_id    = tid;--桌子号
		game_rules = data.game_rules;--玩法规则
	}
	--创建者信息
	self.m_createrInfo = userInfo	
	--桌子状态
	self:_changeGameStatus(const.GameStatus.FREE)
	--初始化模块
	self:onInit()
end

-------------------------------------------from agent-------------------------------------------
--下线 登出  代理服通知
function BaseTable:recvLogout(fromNodeIndex, selfAddr, uid)
	return self.m_userMgr:onUserLogout(fromNodeIndex, selfAddr, uid)
end

-------------------------------------------from alloc-------------------------------------------
--加入房间
function BaseTable:recvJoinReq(node, addr, userinfo)
	return self.m_userMgr:onJoinReq(node, addr, userinfo) 
end

--房间内重连
function BaseTable:recvReconnectReq(fromNodeIndex, fromAddr, uid)
	return self.m_userMgr:onReconnectReq(fromNodeIndex, fromAddr, uid)	
end

--后台系统解散->Alloc->Game
function BaseTable:onSysRelease()
	return self.m_releaseMgr:onSysRelease()
end

-------------------------------------------from [Client->Agent->Game] end-------------------------------------------
BaseTable._COMMAND_MAP_ = {
	[msg.NameToId.ReadyRequest]          = "onReadyReq";
	[msg.NameToId.UserExitRequest]       = "onPlayerExitReq";
	[msg.NameToId.ReleaseRequest]        = "onReleaseReq";
}

--处理消息
function BaseTable:_getCommandHandler( type )
    local func_name = self._COMMAND_MAP_[type]
    if func_name then 
    	return self[func_name]
    end 	
    return nil
end

--收到客户端消息
function BaseTable:on_req(uid, data)
	--异常处理
	if not data or not data.req_type then 
		log.e(LOGTAG,"invalid msg_content, from uid:%d",uid)
		return false
	end 

	if self.m_bWaitDestroy then 
		log.e(LOGTAG,"already destroy! recv uid:%d req_type:%d",uid, data.req_type)
		return false
	end 
	--解析消息
	local ok,decodeData = self:_decodeRoomContentReq(data)
    if not ok then 
        Log.e(LOGTAG,"proto decode error: req_type=%d ", data.req_type )
        return false
    end 
    Log.dump(LOGTAG, decodeData or {})
    --处理消息
    local func = self:_getCommandHandler(data.req_type)
    if func then 
    	return func(self, uid, decodeData)
    else
    	log.w(LOGTAG, "unkown req_type = %d, can't find this command handler!", data.req_type)
    end 
	return false
end

function BaseTable:onPlayerExitReq( uid, data )
	return self.m_userMgr:onExitReq(uid, data)
end

function BaseTable:onReadyReq( uid, data )
	return self.m_userMgr:onReadyReq(uid, data)
end

function BaseTable:onReleaseReq( uid, data )
	return self.m_releaseMgr:onReleaseReq(uid, data)
end

function BaseTable:getTableId()
	return self.m_gameBaseInfo.room_id
end

function BaseTable:getGameBaseInfo()
	return self.m_gameBaseInfo
end

function BaseTable:getTableInfo()
	return {
		game_base_info = self:getGameBaseInfo();
		game_status    = self.m_gameStatus;
		users_base     = self.m_userMgr:getAllUserBaseInfo();
		users_info     = self.m_userMgr:getAllUserInfo();
		progress_info  = self.m_progressMgr:getProgressInfo();
		release_info   = self.m_releaseMgr:getReleaseInfo();
		expand_content = self:_encodeTableInfoExpand();
	};
end

function BaseTable:isGameFree()
	return self.m_gameStatus == const.GameStatus.FREE
end

function BaseTable:isGamePlay()
	return self.m_gameStatus == const.GameStatus.PLAY
end

function BaseTable:isGameWait()
	return self.m_gameStatus == const.GameStatus.WAIT
end

function BaseTable:isGameStart()
	return not self:isGameFree()
end

function BaseTable:_changeGameStatus(status)
	self.m_gameStatus = status
end 

--all ready ->
function BaseTable:changeToGamePlay()
	Log.i(LOGTAG,"tid=%d change to GamePlay State:GamePlay", self:getTableId())
	--
	self:_changeGameStatus(const.GameStatus.PLAY)
	--牌局开始
	--
	self:onSubGameRoundBegin()
end

-->round over
function BaseTable:changeToGameWait()
	Log.i(LOGTAG,"tid=%d change to GameWait State:GameWait", self:getTableId())
	self:_changeGameStatus(const.GameStatus.WAIT)
	--牌局结束
	self:_broadcastGameRoundEnd()
end

-->game over
function BaseTable:changeToGameOver(reason)
	Log.i(LOGTAG,"tid=%d changeToGameOver reason:%d", self:getTableId(), reason)
	Log.i(LOGTAG,"table = %d will destroy after 100ms, in this range no longer access request!", self:getTableId() )
	--标记即将销毁  不再处理消息
	self.m_bWaitDestroy = true
	self.m_timer:registerOnceNow(function ()
		-- body
		--小结算
		--大结算
		--
		local notifyAlloc = reason ~= const.GameFinishReason.RELEASE_SYS
		if notifyAlloc then 
			local bNotifiGame = false --GameServer主动结束的解散,  不用再通知GameServer
			self:callAllocServer("release", self:getTableId(),  bNotifiGame)
		end 
		--
		skynet.exit()
	end, 100)--100ms后结束
end

--
function BaseTable:onInit()
	self:_createTimer()
	self:_createRuleMgr()	
	self:_createUserMgr()
	self:_createReleaseMgr()
	self:_createProgressMgr()
end

function BaseTable:_createTimer()
	self.m_timer = new(require('schedulerMgr'))
	self.m_timer:init()
end

function BaseTable:_createRuleMgr()
	self.m_ruleMgr = new(require("base.mod.RuleMgr"), self)
end

function BaseTable:_createUserMgr()
	self.m_userMgr = new(require("base.mod.UserMgr"), self, self.m_ruleMgr:getMaxUserNum())
end

function BaseTable:_createReleaseMgr()
	self.m_releaseMgr = new(require("base.mod.ReleaseMgr"), self)
end

function BaseTable:_createProgressMgr()
	self.m_progressMgr = new(require("base.mod.ProgressMgr"), self, self.m_ruleMgr:getOverType(), self.m_ruleMgr:getOverValue())
end

--解析RoomReqContent
function BaseTable:_decodeRoomContentReq(data)
	local msgName = self:_getMsgName(data.req_type)
	--msg.IdToName[data.req_type]
	if msgName then 
		local data,err = self:getPacketHelper():decodeMsg(msgName, data.req_content)
        if not data or err ~= nil then 
            Log.e(LOGTAG,"proto decode RoomReq error: req_type=%d name=%s !", data.req_type, msgName)
            return false,nil
        end 
        return true,data		
	end 
	return false, nil
end

function BaseTable:getPacketHelper()
	if not self._packet then 
		self._packet = (require "PacketHelper").create(self:_getProtos())
	end 
	return self._packet
end

function BaseTable:_getProtos()
	return {"protos/hall.pb","protos/table.pb"}
end

function BaseTable:_getMsgName( cmd )
	return msg.IdToName[cmd]
end
--编码 
function BaseTable:encodeRoomContentRsp(cmd, data)
	local msgName = self:_getMsgName(cmd)
	-- msg.IdToName[cmd]
	Log.d(LOGTAG, "encodeRoomContentRsp cmd=%d, msgName=%s", cmd, msgName)
	Log.dump(LOGTAG, data)
	local ret = {
		status  = 0;
		type    = cmd;
		content = self:getPacketHelper():encodeMsg(msgName, data);
	}
	return ret
end

function BaseTable:_encodeTableInfoExpand()
	return nil
end

function BaseTable:_encodeRoundBeginExpand()
	return nil 
end

function BaseTable:_encodeRoundEndExpand()
	return nil
end

function BaseTable:_broadcastGameRoundEnd()
	local data = {
		game_status    = self.m_gameStatus;
		progress_info  = self.m_progressMgr:getProgressInfo();
		users_info     = self.m_userMgr:getAllUserInfo();
		
		over_time      = os.time();
		reason         = 0;
		--is_game_over   = false;
		
		expand_content = self:_encodeRoundEndExpand()
	}
	self.m_userMgr:broadcastMsg(msg.NameToId.GameEndPush, data)
end

function BaseTable:broadcastGameRoundBegin()
	local data = {
		game_status    = self.m_gameStatus;
		progress_info  = self.m_progressMgr:getProgressInfo();
		users_info     = self.m_userMgr:getAllUserInfo();
		expand_content = self:_encodeRoundBeginExpand()
	}
	self.m_userMgr:broadcastMsg(msg.NameToId.GameBeginPush, data)
end


function BaseTable:callAllocServer(...)
	ClusterHelper.callIndex(skynet.getenv("server_alloc"),".AllocService", ... )	
end 

function BaseTable:onSubGameRoundBegin()
	-- body
	self:broadcastGameRoundBegin()
end
return BaseTable