一.消息构成

|2 byte 消息头| + | 消息体内容 |
大端2个字节表示消息大小(1~65536 Byte)(2^16 - 1 = 65535)
消息体内容采用protobuf编解码, 构成:

	message ProtoInfo {
	    optional int32 msg_id = 1;// 消息ID
	    optional bytes msg_body = 2; // 消息内容
	};

每一个msg_id对应一条消息，这个映射关系位于文件servers/preload/gaMsgDef.lua
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
		status = 1;//>=0 成功  <0 失败
		status_tip = "创建成功";
		room_id    = 123456;
	};

------------------------------------------------------------------------------------------
3.加入房间

客户端请求:
JoinRoomRequest:

	msg_body = {
		room_id = 123456;// 房间号
	};

服务器返回:
1). JoinRoomResponse:  required

	msg_body = {
		status         = 1; //>=0 成功  <0 失败
		status_tip     = "加入成功";
		game_base_info = {//message GameBaseInfo
    		game_id     = 1; // 子游戏ID
    		game_type   = 1; // 子玩法ID 
    		room_id     = 123456; // 房间号 
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
	};

如果已经在房间里面(重连) 还会触发推送通知其他玩家 玩家xxxxx上线

2).TableInfoPush：(推送房间信息) required

	msg_body = {//message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 10; 
		content = { // message TableInfoPush
			game_base_info = {//message GameBaseInfo
	    		game_id     = 1; // 子游戏ID
	    		game_type   = 1; // 子玩法ID 
	    		room_id     = 123456; // 房间号 
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
			progress_info = {//message TableProgressInfo
				over_type     = 1;//结束条件类型 1:局数 2:圈数 3:分数(胡息)  4：固定时间
				over_value    = 2;//结束值
				current_value = 3;//当前值
			};
			game_status  = 0;//当前房间状态  Free, Play, Wait
			users_base   = {repeated message TableUserBaseInfo
				{
					user_id      = 0;
					user_name    = ""; 
					head_img_url = "";
				};
				{
					user_id      = 0;
					user_name    = ""; 
					head_img_url = "";
				};
				...				
			};
			users_info  = {//repeated message TableUserInfo
				{
					user_id = 0;
					seat    = 1;
					ready   = true;
					online  = true;
					status  = 0;
					score   = 0;
					expand_content = ... //bytes 子游戏额外扩展信息
				}
				...
			}
			expand_content = ... //bytes 子游戏额外扩展信息
		};
	};

------------------------------------------------------------------------------------------
4.房间内  准备

客户端请求:
ReadyRequest:

	msg_body = {// message RoomContentRequest
		req_type    = 1004; //
		req_content = { // message ReadyRequest
			ready   = true;// true准备  false取消准备
		}
	};

成功则 服务器返回给所有人
UserInfoPush:
	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 1006; 
		content = { // message UserInfoPush
			user_info = { //repeated message TableUserInfo
				{
					user_id = 0;
					seat    = 1;
					ready   = true;
					online  = true;
					status  = 0;
					score   = 0;
					expand_content = ... //bytes 子游戏额外扩展信息
				}
				...
			}
		}
	};




如果所有人均准备，牌局开始，推送所有人游戏开始消息
RoundBeginPush:

	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 1012; 
		content = { // message RoundBeginPush
			game_status = 0;
			progress_info = {//message TableProgressInfo
				over_type     = 1;//结束条件类型 1:局数 2:圈数 3:分数(胡息)  4：固定时间
				over_value    = 2;//结束值
				current_value = 3;//当前值
			};	
			users_info  = {//repeated message TableUserInfo
				{
					user_id = 0;
					seat    = 1;
					ready   = true;
					online  = true;
					status  = 0;
					score   = 0;
					expand_content = ... //bytes 子游戏额外扩展信息
				}
				...
			}
			expand_content = ... //bytes 子游戏额外扩展信息					
		}
	};

------------------------------------------------------------------------------------------
5.退出房间

客户端请求:(空消息)
UserExitRequest:

	msg_body = {// message RoomContentRequest
		req_type    = 1001; //
		req_content = { // message UserExitRequest
		}
	};
服务器返回:
UserExitResponse:

	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 1002; 
		content = { // message UserExitResponse
			status     = 1;//>=0 成功  <0 失败
			status_tip = "退出成功";
		}
	};

离开房间推送(通知其他玩家)
UserExitPush:

	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 1003; 
		content = { // message UserExitPush
			user_id = 1;//退出玩家id
		}
	};
------------------------------------------------------------------------------------------


如果是胡操作,游戏结束
广播推送 小结算
RoundEndPush:
	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 1013; 
		content = { // message RoundEndPush
			//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
			//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
			//大于10000的由子游戏自行约定
			game_status = 0;// 游戏状态 
			progress_info = {//message TableProgressInfo
				over_type     = 1;//结束条件类型 1:局数 2:圈数 3:分数(胡息)  4：固定时间
				over_value    = 2;//结束值
				current_value = 3;//当前值
			};	
			users_info  = {//repeated message TableUserInfo
				{
					user_id = 0;
					seat    = 1;
					ready   = true;
					online  = true;
					status  = 0;
					score   = 0;
					expand_content = ... //bytes 子游戏额外扩展信息
				}
				...
			}
			over_time    = 0;// 结束时间
			reason       = 0;// 小局结束原因
			is_game_over = false;//是否大结算
			expand_content = ... //bytes 子游戏额外扩展信息								
		}
	};


------------------------------------------------------------------------------------------
6.申请解散

客户端请求:
ReleaseRequest:

	msg_body = {// message RoomContentRequest
		req_type    = 1007; //
		req_content = { // message ReleaseRequest
			type   = 1;// 1发起解散  2投票
			value  = 3;// 投票结果 2拒绝  3同意
		}
	};
服务器返回:
ReleaseResponse: //可能失败  可能有时间间隔限制，次数限制

	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 1008; 
		content = { // message ReleaseResponse
			status = 0;
			status_tip = "发起成功";
		}
	};

推送信息: 通知所有人
ReleasePush (推送解散信息) optional 当前处于投票解散等待状态

	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/gaMsgDef.lua,
		//大于10000的由子游戏自行约定
		type    = 1009; 
		content = { // message ReleasePush
			user_id            = 1;// 解散发起人
			cur_release_count  = 1;//当前解散发起请求次数
			max_realease_limit = 3;//最大次数限制
			cur_seconds        = 34;
			max_seconds        = 90;
			status             = 2;////房间解散状态 1失败  2投票中  3成功
			votes              = {//repeated message UserVoteInfo
				{
					vote    = 1;// 投票信息 1未操作 2拒绝 3同意
					user_id = 1;
				};
				...
			}
		}
	};