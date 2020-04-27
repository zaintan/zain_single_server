local BaseUser = class()

function BaseUser:ctor()
    
    self.m_base = {
    	user_id      = 0;
    	user_name    = "";
    	head_img_url = "";
    };
    
    self.m_seat           = -1
    self.m_ready          = false
    self.m_online         = true
    self.m_status         = 0
    self.m_score          = 0
    self.m_fromNode       = nil
    self.m_fromAddr       = nil
end

function BaseUser:parse( tblBaseInfo )
	self.m_base.user_id      = tblBaseInfo.user_id
	self.m_base.user_name    = tblBaseInfo.user_name
	self.m_base.head_img_url = tblBaseInfo.head_img_url
end

function BaseUser:setAddr( node , addr )
	self.m_fromNode = node
	self.m_fromAddr = addr
end

function BaseUser:getAddr()
	return self.m_fromNode, self.m_fromAddr
end

function BaseUser:setReady( bState )
	self.m_ready = bState and true or false
end

function BaseUser:isReady()
	return self.m_ready
end

function BaseUser:setSeat( seat )
	assert(seat and type(seat) == "number")
	self.m_seat = seat
end

function BaseUser:getSeat()
	return self.m_seat
end

function BaseUser:setStatus( status )
	self.m_status = status
end

function BaseUser:getStatus()
	return self.m_status
end

function BaseUser:setScore( score )
	self.m_score = score
end

function BaseUser:addScore( score )
	self.m_score = self.m_score + score
end

function BaseUser:getScore()
	return self.m_score
end

function BaseUser:setOnline( bState )
	self.m_online = bState and true or false
end

function BaseUser:isOnline()
	return self.m_online
end

function BaseUser:getId()
	return self.m_base.user_id
end

function BaseUser:encodeBase()
	return self.m_base
end

function BaseUser:encode()
	local data = {
		user_id        = self:getId();
		seat           = self.m_seat;
		ready          = self.m_ready;
		online         = self.m_online;
		status         = self.m_status;
		score          = self.m_score;		
		expand_content = self:_encodeExpand();
	}
	return data	
end

function BaseUser:_encodeExpand()
	return nil
end

return BaseUser