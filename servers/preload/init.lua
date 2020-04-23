log_level = 4
Log       = Log or (require "LogHelper")
----------------------------------------------
MsgCode     = require "gaCodeDef"
const       = require "gaConstDef"
msg         = {
	NameToId = require "gaMsgDef";
	IdToName = {};
	Root     = "common.ProtoInfo";
}
for k,v in pairs(msg.NameToId) do
	msg.IdToName[v] = "common."..k;
end

----------------------------------------------
require "expand"
require "functions"

--require "bit"