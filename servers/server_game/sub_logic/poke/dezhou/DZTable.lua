
local Super         = require "base.BaseTable"
local DezhouTable   = class(Super)
local LOGTAG        = "[DZTable]"

local subMsg        = require("sub_msg_def.dezhou")


--function DZTable:onInit()
--	Super.onInit(self)
--	self.m_commonCards = {}
--	self.m_banker      = -1;
--	self.m_BigBlind    = -1;
--	self.m_smallBlind  = -1;
--	self.m_userCards   = {};
--	self.m_chipsPool   = {};
--	self.m_opInfo      = {};
--end


function DZTable:_createUserMgr()
	self.m_userMgr = new(require("sub_logic.poke.dezhou.UserMgr"), self, self.m_ruleMgr:getMaxUserNum())
end

function DZTable:_getProtos()
	return {"protos/hall.pb","protos/table.pb", "protos/sub_dezhou.pb"}
end

function DZTable:_getMsgName( cmd )
	if subMsg.IdToName[cmd] then 
		return subMsg.IdToName[cmd]
	end 
	return msg.IdToName[cmd]
end

DZTable._COMMAND_MAP_ = {
	[msg.NameToId.ReadyRequest]          = "onReadyReq";
	[msg.NameToId.UserExitRequest]       = "onPlayerExitReq";
	[msg.NameToId.ReleaseRequest]        = "onReleaseReq";

	[subMsg.NameToId.StandSitRequest]    = "onStandSitReq";
	[subMsg.NameToId.BringChipsRequest]  = "onBringChipsReq";
	[subMsg.NameToId.OpRequest]          = "onOpReq";			
}

function DZTable:onStandSitReq( uid, data )
	return self.m_userMgr:onStandSitReq(uid, data)
end

function DZTable:onBringChipsReq( uid, data )
	return self.m_userMgr:onBringChipsReq(uid, data)
end

--操作请求
function DZTable:onOpReq( uid, data )
	if not self:isGamePlay() then 
		return false 
	end 
	return false
	--return self.m_userMgr:onReadyReq(uid, data)
end

function DZTable:onSubGameRoundBegin()
	self.m_curRound = new(require("sub_logic.poke.dezhou.Round"),  self)
	self.m_curRound:execute()--self:broadcastGameRoundBegin()		
end


function DZTable:_encodeTableInfoExpand()
	if self.m_curRound then 
		return self:getPacketHelper():encodeMsg("sub_dezhou.TableExpandInfo", self.m_curRound:getInfo() );
	end 
	return nil 
end

function DZTable:_encodeRoundBeginExpand()
	return self:_encodeTableInfoExpand()
end

function DZTable:_encodeRoundEndExpand()
	return self:_encodeTableInfoExpand()
end

function DZTable:getSmallBlind()
	return 1
end

return DZTable