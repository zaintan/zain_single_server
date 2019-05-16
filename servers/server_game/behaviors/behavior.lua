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

function behavior:bind(target, ...)
    self:_pre_bind_(...)
    base.setmethods(target, self, self.EXPORTED_METHODS)
    self.target_ = target
    self._on_bind_()
end

function behavior:unbind(target)
    base.unsetmethods(target, self.EXPORTED_METHODS)
    self:_clear()
end

return behavior
