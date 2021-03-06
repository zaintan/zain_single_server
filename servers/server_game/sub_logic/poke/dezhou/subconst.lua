local M = {
	UserStatus = {
		Up              = 0; --站起旁观
		DownWait        = 1; --入座 这一小局中途加入 等待中，下局才可以玩
		DownPlayFold    = 2; --入座 牌局中在玩状态  已经弃牌

		DownPlayWait    = 3; --入座 牌局中在玩状态 等待他人决策
		DownPlayOperate = 4; --入座 牌局中在玩状态 自己操作
		DownPlayAllin   = 5; --入座 牌局中在玩状态 已经Allin
	};

	UserOperateKind = {
		Fold  = 1; --弃牌
		Check = 2; --看牌
		Call  = 4; --跟注
		Raise = 8; --加注
	};

	TurnType = {
		PreFlop = 1;--pre-flop
		Flop    = 2;--flop 翻牌
		Turn    = 3;--turn 转牌
		River   = 4;--river 河牌
	};

	StandSitReqType = {--// 1站起 2坐下
		Up   = 1;
		Down = 2;
	};

	UserFlag = {
 		Null       = 0;--无
 		SmallBlind = 1;--小盲注  		
 		BigBlind   = 2;--大盲注
 		Fold       = 3;--弃牌
 		Check      = 4;--看牌
 		BET        = 5;--押注/下注
 		Call       = 6;--跟注
 		Raise      = 7;--加注
 		Allin      = 8;--全下
	};

}




return M