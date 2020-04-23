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
function BaseTable:recvSysRelease()
	self:changeToGameOver(const.GameFinishReason.SYSTEM_BACK)
end

-------------------------------------------from [Client->Agent->Game] end-------------------------------------------
local _COMMAND_MAP_ = {
	[msg.NameToId.ReadyRequest]          = "onReadyReq";
	[msg.NameToId.UserExitRequest]       = "onPlayerExitReq";
	[msg.NameToId.ReleaseRequest]        = "onReleaseReq";
}

--处理消息
function BaseTable:_getCommandHandler( type )
    local func_name = _COMMAND_MAP_[type]
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
	Log.i("","tid=%d change to GamePlay State", self:getTableId())
	--
	self:_changeGameStatus(const.GameStatus.PLAY)
	--初始化玩家操作
	self.m_userMgr:onRoundBegin()
	--牌局开始
	self:_broadcastGameRoundBegin()
	--
	self:onSubGameRoundBegin()
end

-->round over
function BaseTable:changeToGameWait()
	Log.i("","tid=%d change to GameWait State", self:getTableId())
	self:_changeGameStatus(const.GameStatus.WAIT)
	--牌局结束
	self:_broadcastGameRoundEnd()
end

-->game over
function BaseTable:changeToGameOver(reason)
	--广播通知客户端结算信息
	--清理桌子
	local notifyAlloc = reason ~= const.GameFinishReason.SYSTEM_BACK
	self:onCleanup( notifyAlloc )
end

--清理桌子
function BaseTable:onCleanup(notifyAlloc)
	--
	if notifyAlloc then 
		--GameServer主动结束的解散,  不用再通知GameServer
		local bNotifiGame = false		
		self:callAllocServer("release", self:getTableId(),  bNotifiGame)
	end 
	--标记即将销毁  不再处理消息
	self.m_bWaitDestroy = true
	--延时退出exit  防止队列阻塞不返回
	skynet.timeout(1,function()
		skynet.exit()
	end)	
end

--
function BaseTable:onInit()
	self:_createRuleMgr()	
	self:_createUserMgr()
	self:_createReleaseMgr()
	self:_createProgressMgr()
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
	local msgName = msg.IdToName[data.req_type]
	if msgName then 
		local data,err = self:_getPacketHelper():decodeMsg(msgName, data.req_content)
        if not data or err ~= nil then 
            Log.e(LOGTAG,"proto decode RoomReq error: req_type=%d name=%s !", data.req_type, msgName)
            return false,nil
        end 
        return true,data		
	end 
	return false, nil
end

function BaseTable:_getPacketHelper()
	if not self._packet then 
		self._packet = (require "PacketHelper").create(self:_getProtos())
	end 
	return self._packet
end

function BaseTable:_getProtos()
	return {"protos/hall.pb","protos/table.pb"}
end
--编码 
function BaseTable:encodeRoomContentRsp(cmd, data)
	local msgName = msg.NameToId[cmd]
	Log.d(LOGTAG, "encodeRoomContentRsp cmd=%d, msgName=%s", cmd, msgName)
	Log.dump(LOGTAG, data)
	local ret = {
		status  = 0;
		type    = cmd;
		content = self:_getPacketHelper():encodeMsg(msgName, data);
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
		is_game_over   = false;
		
		expand_content = self:_encodeRoundEndExpand()
	}
	self.m_userMgr:broadcastMsg(msg.NameToId.RoundEndPush, data)
end

function BaseTable:_broadcastGameRoundBegin()
	local data = {
		game_status    = self.m_gameStatus;
		progress_info  = self.m_progressMgr:getProgressInfo();
		users_info     = self.m_userMgr:getAllUserInfo();
		expand_content = self:_encodeRoundBeginExpand()
	}
	self.m_userMgr:broadcastMsg(msg.NameToId.RoundBeginPush, data)
end


function BaseTable:callAllocServer(...)
	ClusterHelper.callIndex(skynet.getenv("server_alloc"),".AllocService", ... )	
end 

return BaseTable