local M = {
	UserStatus = {
		Up              = 0; --站起旁观
		DownWait        = 1; --入座 这一小局中途加入 等待中，下局才可以玩
		DownPlayFold    = 2; --入座 牌局中在玩状态  已经弃牌

		DownPlayWait    = 3; --入座 牌局中在玩状态 等待他人决策
		DownPlayOperate = 4; --入座 牌局中在玩状态 自己操作
		DownPlayAllin   = 5; --入座 牌局中在玩状态  已经Allin
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

}




return M