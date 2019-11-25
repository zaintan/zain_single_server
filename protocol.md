一.消息构成

|2 byte 消息头| + | 消息体内容 |
大端2个字节表示消息大小(1~65536 Byte)(2^16 - 1 = 65535)
消息体内容采用protobuf编解码, 构成:

message ProtoInfo {
    optional int32 msg_id = 1;// 消息ID
    optional bytes msg_body = 2; // 消息内容
};

每一个msg_id对应一条消息，这个映射关系位于文件servers/config/cfg/msg.cfg
为了方便,下面提到的交互协议省略了外层,只提到msg_body这一层

二.协议记录

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
		room_id = 123456;// 如果该玩家在房间 返回房间号,客户端通过主动发送加入房间消息JoinRoomRequest重连
	};

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

4).ReleasePush (推送解散信息) optional 当前处于投票解散等待状态

	msg_body = {
		release_info = { // message ReleaseInfo
			result = 2;//房间解散状态 1失败  2投票中  3成功 
			tip    = "";//
			votes = { // repeated int 投票信息 1未操作 2拒绝 3同意 0发起者
				0,1,3,3 //[seat+1] -> result
			};
			time  = 150;// 倒计时时间，单位秒
			seat_index = 0;// 解散发起人
		};
	};
------------------------------------------------------------------------------------------
4.房间内  准备

客户端请求:
ReadyRequest:

	msg_body = {
		ready = true;// true准备  false取消准备
	};

服务器返回:
ReadyResponse:

	msg_body = {
		status = 1;
		status_tip = "准备成功";
		ready = true;//当前准备状态
	};

推送给其他人
ReadyPush:

	msg_body = {
		ready_infos = { //repeated message PlayerReadyInfo
			{
				seat_index = 0;
				ready = true;
			};
			{
				seat_index = 1;
				ready = false;
			};
			...
		};
	};

如果所有人均准备，牌局开始，推送所有人游戏开始消息
GameStartPush:

	msg_body = {
		game_status = 2;//Free:0 Wait:1 Play:2
		round_room_info = { //message RoundRoomInfo
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
	};

牌局开始后推送所有玩家手牌信息
RoomCardsPush:

	msg_body = {
		cards_infos = {//repeated message PlayerCardsInfo
			{
				has_hands = true;
				has_weaves = true;
				has_discards = true;
				seat_index = 0;
				hands = {1,1,1,2,2,2,3,3,4,4,4,5,5};
				discards = {};
				weaves = {}; //repeated message WeaveItemInfo
			};
			{
				has_hands = true;
				has_weaves = true;
				has_discards = true;
				seat_index = 1;
				hands = {1,1,1,2,2,2,3,3,4,4,4,5,5};
				discards = {};
				weaves = {}; //repeated message WeaveItemInfo
			};
			...
		};
	};

推送抓牌消息 推送给所有人
DispatchCardPush:

	msg_body = {
		dispatch_card = 1; // 抓的牌
		seat_index    = 0; // 抓牌人
		dispatch_type = 1;发牌类型：1：顺序发牌，2：尾部补牌
	};

客户端根据该条推送消息,自行在手牌中添加；每个人收到的推送消息不一样，只有自己才会收到真实dispatch_card，其他人收到的dispatch_card为-1

推送玩家状态信息(每个人推送的不一样， 均只收到自己的状态信息)
PlayerStatusPush:

	msg_body = {
		player_status = 1;// 玩家状态，0：无操作，1：出牌，2：操作牌
		pointed_seat_index = 0;//
		op_info = {} // message OperateInfo
	};
------------------------------------------------------------------------------------------
5.退出房间

客户端请求:(空消息)
PlayerExitRequest:

	msg_body = {
	};

服务器返回:
PlayerExitResponse:

	msg_body = {
		status = 1;// 状态 <0失败  >=0成功  只有在Free状态才能退出房间
	};

离开房间推送(通知其他玩家)
PlayerExitPush:

	msg_body = {
		seat_index = 0;//
	};
------------------------------------------------------------------------------------------
6.出牌

客户端请求:
OutCardRequest:

	msg_body = {
		out_card = 1;
	};

服务器返回:
OutCardResponse:

	msg_body = {
		status = 1;// 状态 <0失败  >=0成功
	};

如果成功 推送所有人消息
OutCardPush:

	msg_body = {
		seat_index = 1;
		out_card   = 1;
	};

客户端根据该条推送消息,自行在手牌中移除，并且在弃牌中添加

------------------------------------------------------------------------------------------
7.操作请求

客户端请求:
OperateCardRequest:

	msg_body = {
		weave_kind  = 1;// 操作类型  左吃 中吃 右吃 碰 杠 胡 
		center_card = 1;//操作的牌
		provide_player = 0;//牌的提供者座位号
		operate_id = 1;//操作序号
	};

服务器返回:
OperateCardResponse:

	msg_body = {
		status = 1;// 状态 <0失败  >=0成功
		status_tip = "操作成功";
	};

如果操作成功,推送所有人
1).广播执行操作
OperateCardPush:

	msg_body = {
		seat_index  = 0；
		weave_kind  = 1;// 操作类型  左吃 中吃 右吃 碰 杠 胡 
		center_card = 1;//操作的牌
		provide_player = 0;//牌的提供者座位号
	};

2).刷新提供者的弃牌   推送所有人
RoomCardsPush:

	msg_body = {
		cards_infos = {//repeated message PlayerCardsInfo
			{
				has_hands = false;
				has_weaves = false;
				has_discards = true;
				seat_index = 0;
				discards = {};
			};
		};
	};

3).刷新操作者的手牌 组合牌， 推送所有人
RoomCardsPush:

	msg_body = {
		cards_infos = {//repeated message PlayerCardsInfo
			{
				has_hands = true;
				has_weaves = true;
				has_discards = false;
				seat_index = 1;
				hands = {1,1,2,3,3,2,3};
				weaves = { //repeated message WeaveItemInfo
					{
						weave_kind = 1;
						center_card = 1;
						public_card = 1;
						provide_player = 0;
					};
				};
			};
		};
	};

如果是胡操作,游戏结束
广播推送 小结算
RoundFinishPush:

	msg_body = {
		game_status = 1;//Free:0 Wait:1 Play:2
		round_finish_reason = 0; //int 小局结束原因
		win_types    = {};//repeated int32  胡类型
		finish_desc  = {};//repeated string 小结算文字描述信息
		final_scores = {};//repeated int32 小局分数统计
		cards_infos  = { //repeated  message PlayerCardsInfo
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

玩家根据该消息重置所有准备状态

------------------------------------------------------------------------------------------
6.申请解散

客户端请求:
ReleaseRequest:

	msg_body = {
		type = 1;// 解散类型 1申请解散 2投票
	};

服务器返回:
ReleaseResponse:

	msg_body = {
		status = 1;// 状态
		status_tip = "请求成功";// 状态提示信息

	};

推送信息: 通知所有人
ReleasePush (推送解散信息) optional 当前处于投票解散等待状态

	msg_body = {
		release_info = { // message ReleaseInfo
			result = 2;//房间解散状态 1失败  2投票中  3成功 
			tip    = "";//
			votes = { // repeated int 投票信息 1未操作 2拒绝 3同意 0发起者
				0,1,1,1 //[seat+1] -> result
			};
			time  = 150;// 倒计时时间，单位秒
			seat_index = 0;// 解散发起人
		};
	};

7.投票解散
客户端请求:
ReleaseRequest:

	msg_body = {
		type = 2;// 解散类型 1申请解散 2投票
		vote_value = 2; //投票信息 2拒绝 3同意
	};

服务器返回:
ReleaseResponse:

	msg_body = {
		status = 1;// 状态
		status_tip = "请求成功";// 状态提示信息

	};

推送信息: 通知所有人
ReleasePush (推送解散信息) optional 当前处于投票解散等待状态

	msg_body = {
		release_info = { // message ReleaseInfo
			result = 1;//房间解散状态 1失败  2投票中  3成功 
			tip    = "xxx拒绝了";//
			votes = { // repeated int 投票信息 1未操作 2拒绝 3同意 0发起者
				0,2,1,1 //[seat+1] -> result
			};
			time  = 63;// 倒计时时间，单位秒
			seat_index = 0;// 解散发起人
		};
	};