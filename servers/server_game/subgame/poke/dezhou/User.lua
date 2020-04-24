
local Super         = require "base.data.BaseUser"
local User          = class(Super)
local LOGTAG        = "DezhouUser"

local subconst      = require "subgame.poke.dezhou.subconst"

function User:ctor()

	self.m_totalBringChips = 0;--累计带入筹码
	self.m_bringWaitChips  = 0;--中途带入筹码  必须下轮才生效
	self.m_curChips        = 0;--当前实际可用筹码
	--当前这轮下注金额
	self.m_curTurnBetChips = 0;

	self.m_status          = subconst.UserStatus.Up
end

function User:_encodeExpand()
	return {
		bring_chips     = self.m_totalBringChips;
		cur_chips       = self.m_curChips;
	}
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

--下注
function User:bet( num )
	assert(self.m_curChips > num)
	self.m_curChips = self.m_curChips - num

	self.m_curTurnBetChips = self.m_curTurnBetChips + num
end

function User:cleanBet()
	self.m_curTurnBetChips = 0
end

--结算筹码
function User:settleChip( num )
	assert(num >= 0)
	self.m_curChips = self.m_curChips + num
	--清空下注
	self:cleanBet()
end

function User:getCurChip()
	return self.m_curChips
end

return User