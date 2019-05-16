function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end


function table.union(...)
    local ret = nil
    local arg = {...}
    for _,v in ipairs(arg) do
        if v then
            if ret then 
                for key,val in pairs(v) do
                    ret[key] = val
                end
            else 
                ret = v
            end 
        end 
    end    
    return ret
end