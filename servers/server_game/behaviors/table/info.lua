--管理桌子的静态信息
local Super           = require("behaviors.behavior")
local info            = class(Super)

info.EXPORTED_METHODS = {
    "getRule",
    "getTableId",
    "getAppInfo",
    "getTableCreaterInfo",
}

local LOGTAG = "info"
--data.game_id,data.game_type,data.game_rules
--data.over_type, data.over_val
function info:_pre_bind_(tid,userInfo,data)
	self.m_tid       = tid
	self.m_creater   = userInfo
	self.m_gameRules = data.game_rules--玩法规则
	self.m_appId     = data.game_id--子游戏
	self.m_gameType  = data.game_type--子玩法
	--结束条件
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
	Log.i(LOGTAG,"info:_on_bind_")
	Log.dump(LOGTAG, self.m_gameRules)
	--固定人数玩法
	local rule = nil 
	for i = const.GameRule.RULE_PLAYER_FIXED_COUNT_BASE,const.GameRule.RULE_PLAYER_FIXED_COUNT_MAX do
		rule = self:getRule(i)
		if rule then 
			break
		end 
	end
	--
	if rule then 
		Log.i(LOGTAG,"rule id:%d  value:%d", rule.id, rule.value)
		self.target_:setMaxPlayerNum(rule.id - const.GameRule.RULE_PLAYER_FIXED_COUNT_BASE)
	end
end

function info:_clear_()
	self.m_tid       = nil 
	self.m_creater   = nil 
	self.m_gameRules = nil 
	self.m_appId     = nil 
	self.m_gameType  = nil 
end

function info:reconnectPush(uid, game_status)
	local data = {}
	data.info  = {
	    game_id     = self.m_appId;
	    game_type   = self.m_gameType;
	    game_rules  = self.m_gameRules;
	    room_id     = self.m_tid;
	    game_status = game_status;
	};--GameRoomInfo
	--behaviors.round
	data.round_info = self.target_:getRoundInfo()
	--behaviors.users
	data.players    = self.target_:getPlayersInfo()
	--push
	self.target_:sendMsg(msg.NameToId.RoomInfoPush,data,uid)
end

function info:getTableCreaterInfo()
	return self.m_creater
end

function info:getAppInfo()
	return {
		game_id = self.m_appId;
		game_type = self.m_gameType;
	}
end

return info
