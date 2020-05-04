local M = {
	--agent server
	["AgentFailedLinkLogin"]  = {-101, "链接登录服失败!"};
	["LoginFailedRetArgs"]    = {-102, "登录服返回参数失败!"};
	["AgentFailedLinkAlloc"]  = {-103, "链接分配服失败!"};
	["AgentFailedLinkGame"]   = {-104, "转发链接逻辑服失败!"};
	--login server

	["LoginFailedArgs"]       = {-201, "缺失必要的登录参数！"};
	["LoginFailedRegister"]   = {-202, "注册失败!"};
	["LoginFailedLinkDB"]     = {-203, "数据库链接失败!"};
	["LoginFailedType"]       = {-204, "暂不支持的登录方式!"};

	["LoginSuccess"]          = {200, "登录成功"};

	--alloc server
	["AllocFailedLinkGame"]   = {-301, "转发链接逻辑服失败!"};
	["JoinFailedReleased"]    = {-302, "分配服查不到该房间号!该房间已解散"};
	["CreateFailedLimit"]     = {-303,"开房数量已达上限!"};
	["CreateFailedNoID"]      = {-304,"分配房间号失败!"};
	["CreateFailedGameRet"]   = {-305,"逻辑服返回错误!"};

	["CreateSuccess"]         = {300, "开房成功"};
	--game server
	["JoinFailedStart"]     = {-401,"游戏已经开始,无法中途加入!"};
	["JoinFailedArgs"]      = {-402,"参数错误!"};	
	["JoinFailedRepeat"]    = {-403,"无法重复添加玩家!"};
	["JoinFailedFull"]      = {-404,"桌子已满!"};	
	["ReconnectFailed"]     = {-405,"重连失败,牌桌找不到该玩家!"};	

	["JoinSuccess"]         = {400,"加入成功!"};

	["ExitFailed"]          = {-406,"牌局已开始!"};
	["ExitSuccess"]         = {401,"退出成功!"};	

	["ReleaseFailedType"]   = {-407, "无效的请求解散类型"};
	["VoteFailed"]          = {-408, "解散投票失败"};
	["ReleaseFailedCount"]  = {-409, "解散次数限制"};
	["ReleaseFailedRepeat"] = {-410, "正在解散投票中"};
}

return M