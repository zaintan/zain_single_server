local Super           = require("behaviors.behavior")
local actions         = class(Super)

actions.EXPORTED_METHODS = {
    
}

function actions:_pre_bind_(...)

end

function actions:_on_bind_()
	-- body
end

function actions:_clear_()
	self.target_  = nil
end



return actions
