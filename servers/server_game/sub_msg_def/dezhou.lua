local M = {
	NameToId = {
	    StandSitRequest   = 10001;--站起坐下
	    BringChipsRequest = 10004;--加筹码 下局生效
	    OpRequest         = 10007;--操作请求  加注 跟注  弃牌
	    DzTableStatusPush = 10010;--牌桌信息推送		
	};
	IdToName = {
		[10001] = "sub_dezhou.StandSitRequest";
		[10004] = "sub_dezhou.BringChipsRequest";
		[10007] = "sub_dezhou.OpRequest";
		[10010] = "sub_dezhou.DzTableStatusPush";
	};   
};
return M