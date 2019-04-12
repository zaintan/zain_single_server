local M = {}

local function _parseStringName( name )
	assert(#name>2)
	assert(string.sub(name,1,1) == '"')
	assert(string.sub(name,-1,-1) == '"')
	return string.sub(name,2,-2)
end


local function _parseLine(line)
	if not line or #line == 0 or string.sub(line,1,2) == "//" then 
		return nil
	end 
	local ret   = {}
	local pos      = 1
	while true do 
		local index = string.find(line,",",pos)
		if index then 
			table.insert(ret,  string.sub(line, pos,index-1))
			pos     = index + 1
		else
			table.insert(ret,  string.sub(line, pos))
			break
		end 
	end
	return ret 
end

function M.parseMsg()
	local file_name = "config/cfg/msg.cfg"

	--local buffer = cc.FileUtils:getInstance():getStringFromFile(file_name)

	local msg = {}
	msg.NameToId = {}
	msg.IdToName = {}
	msg.ResponseBase = 10000

	local msgId = {}
	for line in io.lines(file_name) do
		local ret = _parseLine(line)
		if ret then 
			assert(ret and #ret >= 2)
			local name = _parseStringName(ret[1])
			local id   = tonumber(ret[2])
			assert(id and id > 0)
			msg.NameToId[name] = id
			msg.IdToName[id]   = name
		end 
	end 

	return msg
end

function M.parseConsts()
	local file_name = "config/cfg/const.cfg"
	local const = {}

	for line in io.lines(file_name) do
		local ret = _parseLine(line)
		if ret then 
			assert(ret and #ret >= 3)
			local module_name = _parseStringName(ret[1])
			local name        = _parseStringName(ret[2])
			local val         = tonumber(ret[3])
			assert(val)
			if not const[module_name] then 
				const[module_name] = {}
			end 
			const[module_name][name] = val
		end 
	end 
	return const
end

return M