--管理小局信息
local Super           = require("behaviors.behavior")
local round           = class(Super)

round.EXPORTED_METHODS = {
    "getRoundInfo",
    "startRound",

    "resetStatuses",
    "changePlayerStatus",
    "getPlayerStatus",

    "setBanker",
    "turnSeat",
}

function round:_pre_bind_(...)

end

function round:_on_bind_()
	-- body
	self.m_round = 0

	--self.m_statuses = {}
	--self.m_seat  = 0
end

function round:_clear_()
	self.target_    = nil
	self.m_bStart   = nil

	self.m_statuses = nil
end


function round:getRoundInfo()
	if not self.m_bStart then 
		return nil
	end 

	local info = {}

	info.cur_val            = self.m_round;
	info.cur_banker         = self.m_banker;
	info.pointed_seat_index = self.m_seat;
	info.dice_values        = self.m_dices;
	info.player_statuses    = self.m_statuses;

	info.remain_num         = self.m_pTable:getRemainCardNum();
	info.total_num          = self.m_pTable:getTotalCardNum();
	info.head_send_count    = self.m_pTable:getUsedCardHeadCount();
	info.tail_send_count    = self.m_pTable:getUsedCardTailCount();

	return info 
end

function round:setBanker(seat)
	self.m_banker = seat
end

function round:startRound()
	self.m_bStart = true
	--
	self.m_round = self.m_round + 1
	--定庄家 --第一把随机庄家
	if self.m_round == 1 then 
		self.m_banker = self:_getRandomBanker()
	end 
	self.m_seat  = self.m_banker
	--摇骰子
	self.m_dices = {math.random(6),math.random(6)}
	--牌局开始
	self:_broadcastGameStart()
end

function round:resetStatuses()
	local num = self.target_:getCurPlayerNum()
	for seat = 0,num-1 do
		self.m_statuses[seat + 1] = const.PlayerStatus.NONE
	end
end

function round:changePlayerStatus(seat, toStatus)
	self.m_statuses[seat + 1] = toStatus
end

function round:getPlayerStatus(seat)
	return self.m_statuses[seat + 1]
end

function round:_getRandomBanker()
	local num = #self.m_statuses
	local r   = math.random(num) - 1
	
	if r < 0 then 
		r = 0
	elseif r >= num then 
		r = num-1
	end 

	return r
end

function round:_broadcastGameStart()
	local data = {
		game_status     = self.m_pTable:getCurState():getStatus();
		round_room_info = self:getRoundInfo();
	}
	self.m_pTable:broadcastMsg(msg.NameToId.GameStartPush, data)
end

function round:turnSeat(nextSeat)
	if nextSeat then 
		self.m_seat = nextSeat
	else 
		self.m_seat = (self.m_seat + 1)%(#self.m_statuses)
	end 
end

return round
