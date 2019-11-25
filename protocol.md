一.消息构成
|2 byte 消息头| + | 消息体内容 |

消息体内容采用protobuf编解码, 构成:
message ProtoInfo {
    optional int32 msg_id = 1; // 消息ID
    optional bytes msg_body = 2; // 消息内容
    repeated int32 reserved = 110; // 消除Warning的预留值
}
每一个msg_id对应一条消息，这个映射关系位于文件servers/config/cfg/msg.cfg
为了方便,下面提到的交互协议省略了外层,只提到msg_body这一层

二.协议记录
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
1.登陆

客户端请求:
LoginRequest:

	msg_body = {//
		login_type = 1;// 登录类型 1游客登陆  2微信登陆
		token      = "zdkfjmxmkdEbxFBMz";// 游客登陆时为 机器唯一码;微信登陆时为 微信token
		platform   = 3;// 终端类型，1=android，2=ios，3=pc
		client_version = "1.0.0";// 客户端版本
		game_index = 1;// APP平台类型  标识哪个游戏
	};

服务器返回:
LoginResponse:

	msg_body = {
		status = 1;// >=0 成功  <0 失败
		status_tip      = "";// 登陆失败提示
		user_info = { //message AccountInfo
			user_id = 12345678;
			user_name = "tzy";
			head_img_url = "";
			sex = 0;
			diamond = 10;
			gold    = 1000;
			vip_level = 0;
		};
		room_id = 123456;// 如果该玩家在房间 房间号
	};

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
2.创建房间

客户端请求:
CreateRoomRequest:

	msg_body = {
		create_type = 1;//创建类型 普通创建 代开房 茶馆开房
		game_id = 1;//子游戏ID
		game_type = 1;//子玩法ID
		game_rules = { //repeated message GameRuleInfo
			{
				id = 1;
				value = 1;
			};
			{
				id = 1;
				value = 1;
			};
			...			
		};
	};

服务器返回:
CreateRoomResponse:

	msg_body = {
		status = 1;
		status_tip = "创建成功";
		room_id    = 123456;
	};

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
3.加入房间

客户端请求:
JoinRoomRequest:

	msg_body = {
		room_id = 123456;
	};

服务器返回:
1). JoinRoomResponse:  required

	msg_body = {
		status = 1;
		status_tip = "加入成功";
		game_id = 1;
		game_type = 1;
	};

如果已经在房间里面(重连) 还会触发推送通知其他玩家 玩家xxxxx上线

2).RoomInfoPush：(推送房间信息) required

	msg_body = {
		info = { //message GameRoomInfo
			game_id = 1;
			game_type = 1;
			game_rules = { //repeated message GameRuleInfo
				{
					id = 1;
					value = 1;
				};
				{
					id = 1;
					value = 1;
				};
				...			
			};
			room_id = 123456;
			game_status = 0;//Free:0 Wait:1 Play:2
		};
		round_info = { //message RoundRoomInfo
			cur_val = 1;//当前局数或当前圈数或当前分数
			cur_banker = 0;//庄家座位号
			pointed_seat_index = 0;//当前指向玩家座位号
			dice_values = {1,2};//骰子
			player_statuses = {0,0,0,0};// 玩家状态，0：无操作，1：出牌，2：操作牌
			remain_num = 108;// 剩余牌数
			total_num  = 108;//总牌数
			head_send_count = 0;// 牌墩顺序发牌张数
			tail_send_count = 0;// 牌墩尾部发牌张数
		};
		players = { //repeated message RoomUserInfo
			{
				user_id = 10001;
				user_name = "tzy1";
				head_img_url = "";
				seat_index = 0;
				ready = false;
				creator = false;
			};
			{
				user_id = 10002;
				user_name = "tzy2";
				head_img_url = "";
				seat_index = 1;
				ready = false;
				creator = false;
			};
		};
	};

2).RoomCardsPush：(推送房间信息) optional 房间内所有玩家的牌数据推送
牌局未开始不会推送该消息

	msg_body = {
		cards_infos = {//repeated message PlayerCardsInfo
			{
				has_hands = true;
				has_weaves = true;
				has_discards = true;
				seat_index = 0;
				hands = {1,1,1,2,2,2,3,3,4,4,4,5,5};
				discards = {};
				weaves = { //repeated message WeaveItemInfo
					{
						weave_kind = 1;
						center_card = 1;
						public_card = 1;
						provide_player = 0;
					};
					...
				};
			};
			{
				has_hands = true;
				has_weaves = true;
				has_discards = true;
				seat_index = 1;
				hands = {1,1,1,2,2,2,3,3,4,4,4,5,5};
				discards = {};
				weaves = { //repeated message WeaveItemInfo
					{
						weave_kind = 1;
						center_card = 1;
						public_card = 1;
						provide_player = 0;
					};
					...
				};
			};
			...
		};
	};

3).PlayerStatusPush (推送操作信息) optional 牌局中Play状态 且该玩家当前有操作 未操作过才会推送

	msg_body = {
		player_status = 2;// 玩家状态，0：无操作，1：出牌，2：操作牌
		pointed_seat_index = 0;//
		op_info = { // message OperateInfo
			operate_id = 1;//操作序号  避免这轮回复上轮消息
			weaves = { // repeated message WeaveItemInfo
					{
						weave_kind = 1;
						center_card = 1;
						public_card = 1;
						provide_player = 0;
					};
					...
			};
		};
	};

4).PlayerStatusPush (推送解散信息) optional 
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
3.加入房间

客户端请求:
JoinRoomRequest:

	msg_body = {
		status = 1;
		status_tip = "创建成功";

	};

服务器返回:
JoinRoomResponse:

	msg_body = {
		status = 1;
		status_tip = "创建成功";

	};


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
3.加入房间

客户端请求:
JoinRoomRequest:

	msg_body = {
		status = 1;
		status_tip = "创建成功";

	};

服务器返回:
JoinRoomResponse:

	msg_body = {
		status = 1;
		status_tip = "创建成功";

	};

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
3.加入房间

客户端请求:
JoinRoomRequest:

	msg_body = {
		status = 1;
		status_tip = "创建成功";

	};

服务器返回:
JoinRoomResponse:

	msg_body = {
		status = 1;
		status_tip = "创建成功";

	};