--管理玩家的手牌
local Super           = require("behaviors.behavior")
local cards            = class(Super)

cards.EXPORTED_METHODS = {
    "resetCards",

    "updateHandCards"
}

function cards:_pre_bind_(...)

end

function cards:_on_bind_()
	-- body
end

function cards:_clear_()
	self.target_  = nil
end

function cards:reconnectPush()
	--local data = {}
	--[[
	data.cards_infos = {
		has_hands = true;
		has_weaves = true;
		has_discards = true;
		hands = {};
		weaves = {};
		discards = {};
	}
	]]
	--self.target_:sendMsg(msg.NameToId.PlayerCardsPush,data,uid)
end

function cards:resetCards()
	-- body
end

function cards:updateHandCards(seat, values)
	-- body
end


return cards

