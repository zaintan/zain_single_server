local M = {
	HeartRequest   = 1;
	HeartResponse  = 2;

	LoginRequest   = 3;
	LoginResponse  = 4;

	CreateRoomRequest  = 5;
	CreateRoomResponse = 6;

	JoinRoomRequest  = 7;
	JoinRoomResponse = 8;

	RoomContentRequest  = 9;
	RoomContentResponse = 10;
    
    UserExitRequest  = 1001;
    UserExitResponse = 1002;
    UserExitPush     = 1003;

    ReadyRequest     = 1004;

    ReleaseRequest  = 1007;
    ReleaseResponse = 1008;
    ReleasePush     = 1009;

    UserEnterPush   = 1010;
    TableInfoPush   = 1011;

    RoundBeginPush  = 1012;
    RoundEndPush    = 1013;
}

return M