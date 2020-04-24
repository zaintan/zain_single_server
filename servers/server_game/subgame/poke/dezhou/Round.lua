--小局
local Round   = class()

function Round:ctor(pTable)
	self.m_pTable    = pTable
	self.m_userMgr   = self.m_pTable.m_userMgr
	
	self.m_userCards   = {}
	self.m_commonCards = {}

	self.m_banker      = -1;
	self.m_xiao_mang   = -1;
	self.m_da_mang     = -1;
end

function Round:execute()
	Log.d("","牌局开始!")
	--检查生效 上局牌局中带入的筹码
	self.m_userMgr:checkEffectBringChips()
	--确定这轮参与玩家
	local seats = self.m_userMgr:makeSurePlayUsers()
	--
	if #seats <= 1 then
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
	self.m_banker = self.m_seats[1]

	self.m_xiao_mang = self:getNextOffsetSeatByBanker(1)
	self.m_da_mang   = self:getNextOffsetSeatByBanker(2)
end

function Round:getNextOffsetSeatByBanker(offset)
	local num = #self.m_seats
	return self.m_seats[(offset + num)%num + 1]
end

function Round:betBlind()
	local blindChip = self.m_pTable:getSmallBlind()
	local smallUser = self.m_userMgr:getUserBySeat(self.m_xiao_mang)
	local bigUser   = self.m_userMgr:getUserBySeat(self.m_da_mang)
	smallUser:bet(blindChip)
	bigUser:bet(blindChip*2)
end


function Round:_initTurns()
	local preflop = new(require("subgame.poke.dezhou.TurnPreFlop"), self)
	self.m_turn = preflop
	self.m_turn:execute()
end

return Round