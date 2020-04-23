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

function table.clone( tbl )
    
    local lookup_table = {}  

    local function _copy(target)  
        if type(target) ~= "table" then  
            return target   
        end  

        if lookup_table[target] then 
            return lookup_table[target]
        end 

        local new_table = {}  
        lookup_table[target] = new_table  

        for index, value in pairs(target) do  
            new_table[_copy(index)] = _copy(value)  
        end   
        
        return setmetatable(new_table, getmetatable(target))      
    end     

    return _copy(tbl) 
end