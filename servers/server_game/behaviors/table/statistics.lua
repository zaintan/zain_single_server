local Super           = require("behaviors.behavior")
local statistics            = class(Super)

statistics.EXPORTED_METHODS = {
    
}

function statistics:_pre_bind_(...)

end

function statistics:_on_bind_()
	-- body
end

function statistics:_clear_()
	self.target_  = nil
end



return statistics
