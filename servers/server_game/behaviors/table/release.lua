local Super           = require("behaviors.behavior")
local release            = class(Super)

release.EXPORTED_METHODS = {
    
}

function release:_pre_bind_(...)

end

function release:_on_bind_()
	-- body
end

function release:_clear_()
	self.target_  = nil
end



return release
