
local Super         = require "base.BaseTable"
local DezhouTable   = class(Super)
local LOGTAG        = "DezhouTable"


function DezhouTable:_createUserMgr()
	self.m_userMgr = new(require("subgame.poke.dezhou.UserMgr"), self, self.m_ruleMgr:getMaxUserNum())
end

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

--开始新的一局
function DezhouTable:onSubGameRoundBegin()
	local round = new(require("subgame.poke.dezhou.Round"),  self)
	self.m_curRound = round
	round:execute()
end

function DezhouTable:getSmallBlind()
	return 1
end


return DezhouTable