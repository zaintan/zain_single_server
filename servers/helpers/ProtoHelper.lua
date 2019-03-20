local M = {}
M.IdToName = nil
M.NameToId = nil;

M.ResponseBase = 10000;
function M.init()
	if M.NameToId == nil then
		M.IdToName = {}
		M.NameToId = {}
		for k,v in pairs(const.MsgId) do
			local msgName = k
			local subK = string.sub(k,-3)
			if subK == "Req" then 
				msgName = string.sub(k,1,-4).."Request"
			elseif subK == "Rsp" then 
				msgName = string.sub(k,1,-4).."Response"
			end
			M.IdToName[v] = msgName;
			M.NameToId[msgName] = v
		end
	end 
	return M
end
return M