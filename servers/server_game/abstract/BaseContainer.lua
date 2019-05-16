------------------------------------------------------
---! @file
---! @brief BaseContainer
------------------------------------------------------

local BaseContainer  = class()

--初始化顺序 从上到下
BaseContainer._behavior_cfgs_ = nil

function BaseContainer:ctor(...)
	if not self._behavior_cfgs_ then 
		return 
	end 
	self:_bindBehaviors(...)
end

function BaseContainer:_bindBehaviors(...)
	--
	for _,v in ipairs(self._behavior_cfgs_ or {}) do
		local arr = string.split(v.path,".")
		if not arr or #arr < 1 then
			Log.e("","maybe err! can not split path=%s",path) 
		else
			if v.bArgs then 
				base.bind(self,arr[#arr],path,...)
			else 
				base.bind(self,arr[#arr],path)
			end  			
		end 
	end
	--
end

function BaseContainer:_getBehavior(name)
	return self._behaviors_[name]
end

return BaseContainer