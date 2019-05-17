--管理玩家的操作信息
local Super           = require("behaviors.behavior")
local operates        = class(Super)

operates.EXPORTED_METHODS = {
    "resetOperates",
}

function operates:_pre_bind_(...)

end

function operates:_on_bind_()
	-- body
end

function operates:_clear_()
	self.target_  = nil
end

function operates:resetOperates()
	-- body
end


return operates
