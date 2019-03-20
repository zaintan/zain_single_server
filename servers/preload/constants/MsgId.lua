local MsgId = {
	LoginReq  = 1;
	LoginRsp  = 10001;
	CreateRoomReq = 2;
	CreateRoomRsp = 10002;
	JoinRoomReq   = 3;
	JoinRoomRsp   = 10003;
	HeartReq  = 4;
	HeartRsp  = 10004;
	ReadyReq  = 5;
	ReadyRsp  = 10005;

	OperateCardReq = 6;
	OperateCardRsp = 10006;
	OutCardReq     = 7;
	OutCardRsp     = 10007;
	
	CommonTipsPush    = 20001;
	PlayerEnterPush   = 20002; 
	ReadyPush         = 20003;
	GameStartPush     = 20004;	
	
	PlayerCardsPush   = 20005;
	PlayerStatusPush  = 20006;
	OutCardPush       = 20007;
	CardTypePush      = 20008;

	GameFinishPush    = 20010;
	OutCardPush       = 20011;
	DispatchCardPush  = 20012;
	RoomCardsPush     = 20013;	
}

return MsgId