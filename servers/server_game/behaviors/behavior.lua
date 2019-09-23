local behavior = class()

behavior.EXPORTED_METHODS = {
    
}

function behavior:_pre_bind_(...)

end

function behavior:_on_bind_()
	-- body
end

function behavior:_clear_()
	self.target_  = nil
end


local function _setmethods(target, behavior_, methods)
    for _, name in ipairs(methods) do
        local method = behavior_[name]
        target[name] = function(__, ...)
            return method(behavior_, ...)
        end
    end
end

local function _unsetmethods(target, methods)
    for _, name in ipairs(methods) do
        target[name] = nil
    end
end

function behavior:bind(target, ...)
    self:_pre_bind_(...)
    _setmethods(target, self, self.EXPORTED_METHODS)
    self.target_ = target
    self:_on_bind_()
end

function behavior:unbind(target)
    _unsetmethods(target, self.EXPORTED_METHODS)
    self:_clear()
end

return behavior
