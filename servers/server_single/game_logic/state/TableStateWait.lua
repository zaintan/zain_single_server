------------------------------------------------------
---! @file
---! @brief TableStateWait
------------------------------------------------------
local Super = require("game_logic.state.BaseTableState")
local TableStateWait = class(Super)

function TableStateWait:ctor(pTable)
	self.m_status = const.GameStatus.WAIT
end

function TableStateWait:onEnter()
	--取消所有玩家的准备状态
	local players     = self.m_pTable:getPlayers()	
	for id,player in pairs(players) do
		player.ready  = false
		self.m_pTable:broadcastMsg(const.MsgId.ReadyPush, {seat_index = player.seat_index;ready = false;})	
	end
end

function TableStateWait:onExit()
	-- body
end

--return true,JoinRoomResponse
--return false,"reason"
function TableStateWait:join(agent, uid)
	return false,"无法加入,牌局已开始!"
end

--return JoinRoomResponse
function TableStateWait:reconnect(agent, uid)
	Super.reconnect(self, agent, uid)
end


function TableStateWait:_onReadyReq(msg_id, uid, data)
	local player = self.m_pTable:getPlayer(uid)
	if not player then 
		self.m_pTable:sendMsg(uid, const.MsgId.ReadyRsp, {status = -1;})
		return false
	end 

	player.ready = data.ready
	self.m_pTable:sendMsg(uid, const.MsgId.ReadyRsp, {status = 0;ready = data.ready;})
	self.m_pTable:broadcastMsg(const.MsgId.ReadyPush, {seat_index = player.seat_index;ready = data.ready;}, uid)
	
	if self.m_pTable:isAllReady() then 
		self.m_pTable:changePlay()
	end 
	return true	
end

function TableStateWait:_onOutCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip = "牌局还未开始,无法出牌!";})
end

function TableStateWait:_onOperateCardReq(msg_id, uid, data)
	self.m_pTable:sendMsg(uid,msg_id+const.MsgId.BaseResponse, {status = -1;status_tip = "牌局还未开始,无法操作牌!";})
end


return TableStateWait