
local Super         = require "base.BaseTable"
local DezhouTable   = class(Super)
local LOGTAG        = "DezhouTable"


--function DezhouTable:_createUserMgr()
--	-- body
--end

--解析RoomReqContent
function DezhouTable:_decodeRoomContentReq(data)
	return false, nil
end
--编码
function DezhouTable:encodeRoomContentRsp(cmd, data)
	-- body
end

function DezhouTable:_encodeTableInfoExpand()
	return nil
end

function DezhouTable:_encodeRoundBeginExpand()
	return nil 
end

function DezhouTable:_encodeRoundEndExpand()
	return nil
end

function DezhouTable:onSubGameRoundBegin()

end

return DezhouTable