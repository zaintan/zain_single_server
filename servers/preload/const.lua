local M = {
	RoundFinishReason = {
		NORMAL       = 1;--正常结束
		DRAW         = 2;--流局、荒庄
		RELEASE      = 3;--被解散的
	};
	GameFinishReason = {
		NORMAL          = 1;--正常打完结束
		RELEASE_SYS     = 2;--系统后台解散
		RELEASE_USER    = 3;--用户申请解散 所有人同意
		RELEASE_TIMEOUT = 4;--申请解散超时
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

	ReleaseVoteVal = {
		AGREE  = 3;
		UNDO   = 1;
		REJECT = 2;
	};

	ReleaseVote = {
		FAILED  = 1;
		VOTING  = 2;
		SUCCESS = 3;
	};
}
return M