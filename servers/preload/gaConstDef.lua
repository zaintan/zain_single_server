local M = {
	RoundFinishReason = {
		NORMAL       = 1;--正常结束
		DRAW         = 2;--流局、荒庄
		RELEASE_SYS  = 3;--系统解散
		RELEASE_USER = 4;--用户申请解散
	};

	GameStatus = {
		FREE = 0;
		WAIT = 1;
		PLAY = 2;
	};

	PlayerStatus = {
		NONE         = 0;
		OUT_CARD     = 1;
		OPERATE_CARD = 2;
	};

	Sex = {
		MAN    = 1;
		WOMAN  = 2;
		UNKOWN = 3;
	};

	LoginType = {
		USER   = 1;
		WECHAT = 2;
	};

	PlatformType = {
		ANDROID = 1;
		IOS = 2;
		PC = 3;
	};

	ReleaseReqType = {
		RELEASE = 1;
		VOTE = 2;
	};

	ReleaseVote = {
		FAILED = 1;
		VOTING = 2;
		SUCCESS = 3;
	};
}
return M