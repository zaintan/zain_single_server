local Super           = require("behaviors.behavior")
local info            = class(Super)

info.EXPORTED_METHODS = {
    "getRule",
    "getTableId",
    "getTableInfo",
}
--data.game_id,data.game_type,data.game_rules
--data.over_type, data.over_val
function info:_pre_bind_(tid,userInfo,data)
	self.m_tid       = tid
	self.m_creater   = userInfo
	self.m_gameRules = data.game_rules--玩法规则
	self.m_appId     = data.game_id--子游戏
	self.m_gameType  = data.game_type--子玩法
	--结束条件
	self.m_overType  = data.over_type
	self.m_overVal   = data.over_val
end

function info:getTableId()
	return self.m_tid
end

function info:getRule(id)
	for _,v in ipairs(self.m_gameRules) do
		if v.id == id then
			return v
		end 
	end
	return nil
end

function info:_on_bind_()
	local ret      = self.target_:parseUserInfo(self.m_creater)
	self.m_creater = ret

	--固定人数玩法
	local rule = self:getRule(const.GameRule.RULE_PLAYER_COUNT)
	if rule then 
		self.target_:setMaxPlayerNum(rule.value)
	end
end

function info:_clear_()
	self.m_tid       = nil 
	self.m_creater   = nil 
	self.m_gameRules = nil 
	self.m_appId     = nil 
	self.m_gameType  = nil 
	self.m_overType  = nil 
	self.m_overVal   = nil 
end

function info:getTableInfo()
	local ret = {}
	info.game_id     = self.m_appId
	info.game_type   = self.m_gameType
	info.game_rules  = self.m_gameRules
	info.over_type   = self.m_overType	
	info.over_val    = self.m_overVal				
	info.room_id     = self.m_tid
	return ret
end

return info
