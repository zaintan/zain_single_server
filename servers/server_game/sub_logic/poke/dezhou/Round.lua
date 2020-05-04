--小局
local Round   = class()

function Round:ctor(pTable)
	self.m_pTable    = pTable
	self.m_userMgr   = self.m_pTable.m_userMgr
	
	self.m_userCards   = {}
	self.m_commonCards = {}
	self.m_chipsPool   = {}

	self.m_banker      = -1;
	self.m_xiao_mang   = -1;
	self.m_da_mang     = -1;
end

function Round:execute()
	Log.d("","牌局开始!")
	--检查生效 上局牌局中带入的筹码
	self.m_userMgr:onRoundBegin()
	--确定这轮参与玩家
	local seats = self.m_userMgr:makeSurePlayUsers()
	self.m_playNum = #seats
	--
	if self.m_playNum <= 1 then
		--牌局进入等待状态  等待玩家补充筹码
		self.m_pTable:changeToGameWait() 
		return false
	end 
	--定庄
	self:makeBanker(seats)
	--下盲注
	self:betBlind()
	--进入pre-flop	
	self:_initTurns()
	--广播牌局开始
	self.m_pTable:broadcastGameRoundBegin()
	--
	return self
end

function Round:getPlayNum()
	return self.m_playNum
end

function Round:makeBanker(seats)
	if not self.m_banker or self.m_banker == -1 then 
		self.m_seats  = seats
		self.m_banker = self.m_seats[1]
		return 
	end 

	self.m_seats = {}
	for i=1,#seats do
		if seats[i] > lastBanker then
			table.insert(self.m_seats, seats[i])
		end 
	end
	for i=1,#seats do 
		if seats[i] <= lastBanker then 
			table.insert(self.m_seats, seats[i])
		end 
	end 
	self.m_banker    = self.m_seats[1]
	self.m_xiao_mang = self:getNextOffsetSeatByIndex(1,1)
	self.m_da_mang   = self:getNextOffsetSeatByIndex(2,1)
end



function Round:getSeatIndex( seat )
	for index,vseat in ipairs(self.m_seats) do
		if seat == vseat then 
			return index
		end
	end
end

function Round:getNextOffsetSeatBySeat( offset, seat )
	local index = self:getSeatIndex(seat)
	if not index then 
		return nil 
	end 
	return self:getNextOffsetSeatByIndex(index)
end

function Round:getNextOffsetSeatByIndex( offset, index )
	local len = self:getPlayNum()	
	assert(index > 0 and index < len )
	local i = (offset + index + len)%len
	local result = i == 0 and len or i
	return self.m_seats[result]
end


function Round:betBlind()
	local blindChip = self.m_pTable:getSmallBlind()
	local smallUser = self.m_userMgr:getUserBySeat(self.m_xiao_mang)
	local bigUser   = self.m_userMgr:getUserBySeat(self.m_da_mang)
	smallUser:betSmallBlind(blindChip)
	bigUser:betBigBlind(blindChip*2)
end


function Round:_initTurns()
	local preflop = new(require("sub_logic.poke.dezhou.TurnPreFlop"),self)
	self.m_turn = preflop
	self.m_turn:execute()
end

function Round:getInfo()
	-- body
end

return Round