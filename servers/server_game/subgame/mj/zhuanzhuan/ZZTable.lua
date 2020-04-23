
local Super             = require "base.BaseTable"
local ZZTable   = class(Super)
local LOGTAG            = "ZZTable"


--function DezhouTable:_createUserMgr()
--	-- body
--end

--解析RoomReqContent
function ZZTable:_decodeRoomContentReq(data)
	return false, nil
end
--编码
function ZZTable:encodeRoomContentRsp(cmd, data)
	-- body
end

function ZZTable:_encodeTableInfoExpand()
	return nil
end

function ZZTable:_encodeRoundBeginExpand()
	return nil 
end

function ZZTable:_encodeRoundEndExpand()
	return nil
end

function ZZTable:onSubGameRoundBegin()

end

return ZZTable