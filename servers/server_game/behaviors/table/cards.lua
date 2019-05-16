local Super           = require("behaviors.behavior")
local cards            = class(Super)

cards.EXPORTED_METHODS = {
    
}

function cards:_pre_bind_(...)

end

function cards:_on_bind_()
	-- body
end

function cards:_clear_()
	self.target_  = nil
end



return cards

