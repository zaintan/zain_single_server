------------------------------------------------------
---! @file
---! @brief TableUserInfo
------------------------------------------------------

local TableUserInfo = class()

function TableUserInfo:ctor()
	self.score = 0
	self.ready = false
end


function TableUserInfo:init(agent,data,seat_index)
	if seat_index then 
		self.seat_index = seat_index
	end 
	self.agent            = agent

	self.user_id          = data.FUserID
	self.user_name        = data.FUserName
	self.head_img_url     = data.FHeadUrl
end

function TableUserInfo:getProtoInfo()
	return {
		user_id      = self.user_id;
		user_name    = self.user_name;
		head_img_url = self.head_img_url;
		seat_index   = self.seat_index;
		score        = self.score;
		ready        = self.ready;
	}
end


return TableUserInfo