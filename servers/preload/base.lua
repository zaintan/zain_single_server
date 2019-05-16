base = {}

local bind_ = nil
bind_ = function ( target, name, path, ...  )
    local t = type(target)
    assert(t == "table", string.format("base.bind() - invalid target, expected is object, actual is %s", t))
    
    if not target._behaviors_ then target._behaviors_ = {} end
    assert(type(name) == "string" and name ~= "", string.format("base.bind() - invalid behavior name \"%s\"", name))
    
    if not target._behaviors_[name] then
        local cls = require(path)
        assert(cls ~= nil, string.format("base.bind() - invalid behavior path \"%s\"", path))

        --for __, depend in ipairs(cls.depends or {}) do
        --    if not target._behaviors_[depend[1]] then
        --        bind_(target, depend[1], depend[2])
        --    end
        --end
        local behavior = cls:create()
        target._behaviors_[name] = behavior
        behavior:bind(target,...)
    else
    	Log.w("[WARN]: repeat bind same name behavior to target! name:", name)
    end
    return target
end

base.bind = bind_

function base.unbind(target, ...)
    if not target._behaviors_ then return end

    local names = {...}
    assert(#names > 0, "base.unbind() - invalid package names")

    for _, name in ipairs(names) do
        assert(type(name) == "string" and name ~= "", string.format("base.unbind() - invalid package name \"%s\"", name))
        local behavior = target._behaviors_[name]
        assert(behavior, string.format("base.unbind() - behavior \"%s\" not found", tostring(name)))
        behavior:unbind(target)
        target._behaviors_[name] = nil
    end
    return target
end

function base.setmethods(target, behavior, methods)
    for _, name in ipairs(methods) do
        local method = behavior[name]
        target[name] = function(__, ...)
            return method(behavior, ...)
        end
    end
end

function base.unsetmethods(target, methods)
    for _, name in ipairs(methods) do
        target[name] = nil
    end
end

return base