
local Super             = require "base.BaseTable"
local ZZTable           = class(Super)
local LOGTAG            = "ZZTable"

--编码
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