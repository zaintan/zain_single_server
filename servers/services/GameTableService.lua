local skynet = require "skynet"

local GameTableLogic = require("game_logic.GameTableLogic")

skynet.start(function()
	--注册消息处理函数
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local func = GameTableLogic[cmd]
		if func then
			skynet.ret(skynet.pack(func(GameTableLogic, subcmd, ...)))
		else
			Log.e("TableSvr", "unknown cmd = %s", cmd)
		end
	end)
end)
