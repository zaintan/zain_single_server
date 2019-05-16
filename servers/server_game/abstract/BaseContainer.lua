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

function BaseContainer:_getBehavior(name)
	return self._behaviors_[name]
end

local _bind_ = nil
_bind_ = function ( target, name, path, ...  )
    local t = type(target)
    assert(t == "table", string.format("_bind_() - invalid target, expected is object, actual is %s", t))
    
    if not target._behaviors_ then target._behaviors_ = {} end
    assert(type(name) == "string" and name ~= "", string.format("_bind_() - invalid behavior name \"%s\"", name))
    
    if not target._behaviors_[name] then
        local cls = require(path)
        assert(cls ~= nil, string.format("_bind_() - invalid behavior path \"%s\"", path))

        local behavior = new(cls)
        target._behaviors_[name] = behavior
        behavior:bind(target,...)
    else
    	Log.w("[WARN]: repeat bind same name behavior to target! name:", name)
    end
    return target
end

function _unbind_(target, ...)
    if not target._behaviors_ then return end

    local names = {...}
    assert(#names > 0, "_unbind_() - invalid behavior names")

    for _, name in ipairs(names) do
        assert(type(name) == "string" and name ~= "", string.format("_unbind_() - invalid behavior name \"%s\"", name))
        local behavior = target._behaviors_[name]
        assert(behavior, string.format("_unbind_() - behavior \"%s\" not found", tostring(name)))
        behavior:unbind(target)
        target._behaviors_[name] = nil
    end
    return target
end

function BaseContainer:_bindBehaviors(...)
	--
	for _,v in ipairs(self._behavior_cfgs_ or {}) do
		local arr = string.split(v.path,".")
		if not arr or #arr < 1 then
			Log.e("","maybe err! can not split path=%s",path) 
		else
			if v.bArgs then 
				_bind_(self,arr[#arr],path,...)
			else 
				_bind_(self,arr[#arr],path)
			end  			
		end 
	end
	--
end

return BaseContainer