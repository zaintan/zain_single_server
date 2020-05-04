
local Super         = require "base.data.BaseUser"
local User          = class(Super)
local LOGTAG        = "DezhouUser"

local subconst      = require "sub_logic.poke.dezhou.subconst"

function User:ctor(pTable)
	self.m_pTable = pTable

	self.m_totalBringChips = 0;--累计带入筹码
	self.m_bringWaitChips  = 0;--中途带入筹码  必须下轮才生效
	self.m_curChips        = 0;--当前实际可用筹码
	--当前这轮下注金额
	self.m_curTurnBetChips = 0;

	self.m_status          = subconst.UserStatus.Up--重写
	self.m_flag            = subconst.UserFlag.Null;
end

function User:_encodeExpand()
	local data = {
		bring_chips     = self.m_totalBringChips;
		cur_chips       = self.m_curChips;
		bet_chips       = self.m_curTurnBetChips;--// 当前这一轮 已下注筹码
		flag            = self.m_flag;--// 用户标记  1看牌 2加注 3跟注  0无
	};
	return self.m_pTable:getPacketHelper():encodeMsg("sub_dezhou.TableUserExpandInfo", data);
end

--带入筹码  
function User:bringChips( num )
	assert(num > 0)
	self.m_bringWaitChips  = self.m_bringWaitChips + num
	self.m_totalBringChips = self.m_totalBringChips + num
end

--检查 生效 之前带入的筹码 (每轮开始之前)
function User:checkEffectBringChips()
	if self.m_bringWaitChips > 0 then 
		self.m_curChips       = self.m_curChips + self.m_bringWaitChips
		self.m_bringWaitChips = 0
	end 
end

function User:onRoundBegin()
	self:checkEffectBringChips()
	--情况当前下注
	self:cleanCurTurnBet()
	self.m_flag            = subconst.UserFlag.Null
end

function User:betBigBlind( num )
	self.m_flag = subconst.UserFlag.BigBlind
	self.m_status = subconst.UserStatus.DownPlayWait
	self:_bet(num)	
end

function User:betSmallBlind( num )
	self.m_flag = subconst.UserFlag.SmallBlind
	self.m_status = subconst.UserStatus.DownPlayWait
	self:_bet(num)	
end

function User:check()
	self.m_flag = subconst.UserFlag.Check
	self.m_status = subconst.UserStatus.DownPlayWait 
	self:cleanCurTurnBet()
end

function User:fold()
	self.m_flag   = subconst.UserFlag.Fold
	self.m_status = subconst.UserStatus.DownPlayFold 
	self:cleanCurTurnBet()
end

function User:raise( num )
	self.m_flag   = subconst.UserFlag.Raise
	self.m_status = subconst.UserStatus.DownPlayWait 
	self:_bet(num)
	self:_checkAllin()
end

function User:call( num )
	self.m_flag   = subconst.UserFlag.Call
	self.m_status = subconst.UserStatus.DownPlayWait 
	self:_bet(num)
	self:_checkAllin()
end

function User:allin()
	self.m_flag   = subconst.UserFlag.Allin
	self.m_status = subconst.UserStatus.DownPlayAllin 
	self:_bet(self.m_curChips)
end

--下注
function User:_bet( num  )
	local real_num = num > self.m_curChips ? self.m_curChips:num
	self.m_curChips        = self.m_curChips - real_num
	self.m_curTurnBetChips = self.m_curTurnBetChips + real_num 
end

function User:_checkAllin()
	if self.m_curChips == 0 then 
		self.m_flag   = subconst.UserFlag.Allin
		self.m_status = subconst.UserStatus.DownPlayAllin 		
	end 
end

function User:cleanCurTurnBet()
	self.m_curTurnBetChips = 0
end

--结算筹码
function User:settleChip( num )
	assert(num >= 0)
	self.m_curChips = self.m_curChips + num
	--清空下注
	self:cleanCurTurnBet()
end

function User:getCurChip()
	return self.m_curChips
end

function User:getCurTurnBetChips()
	return self.m_curTurnBetChips
end


function User:canUp()
	return self.m_status ~= subconst.UserStatus.DownPlayWait
		and self.m_status ~= subconst.UserStatus.DownPlayOperate
		and self.m_status ~= subconst.UserStatus.DownPlayAllin
end

return User