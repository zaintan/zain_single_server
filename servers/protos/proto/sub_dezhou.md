一.德州自定义消息文档

------------------------------------------------------------------------------------------
1.扩展字段说明

基础数据说明:

--牌(int)
--0x01,0x0D  方片A - 方片K
--0x11,0x1D  梅花
--0x21,0x2D  红桃
--0x31,0x3D  黑桃

--牌型(int)
--01:高牌
--02:一对
--03:两对
--04:三条
--05:顺子
--06:同花
--07:葫芦
--08:四条
--09:同花顺
--10:皇家同花顺

(1).扩展message TableUserInfo.expand_content字段

message TableUserExpandInfo {
	optional int32  bring_chips      = 1; // 累计带入场的总筹码数
	optional int32  effect_chips     = 2; // 当前这一局 可使用的有效筹码
	optional int32  bet_chips        = 3; // 当前这一轮 的已下注筹码
	optional int32  flag             = 4; // 用户标记  1看牌 2加注 3跟注  0无	
} 

(2).扩展message TableInfoPush.expand_content字段

message TableExpandInfo {
	repeated int32 common_cards = 1; // 当前公牌  -1表示牌背  空表示没有
	optional int32 banker       = 2; // 庄家座位号
	optional int32 xiao_mang    = 3; // 小盲座位号
	optional int32 da_mang      = 4; // 大盲座位号
	repeated UserCardInfo user_cards  = 5;//玩家的手牌信息
	repeated ChipsPoolInfo chips_pool = 6;//筹码池分池信息
	optional OpInfo        op_info    = 7;	
}

message UserCardInfo {
	repeated int32 hand_cards  = 1; // 手牌牌值0/2张
	optional int32 brand_type  = 2; // 当前最大牌型
	optional int32 seat        = 3; // 
}

message ChipsPoolInfo {//筹码池信息 多人allin 需分池
	optional int32  chips      = 1; //筹码数
	repeated int32  users      = 2; //参与分池的玩家座位号	
}

message OpInfo{
	optional int32  seat      = 1; // 当前操作玩家座位号
	optional int32  actions   = 2; //位标记 1看牌/过牌   2弃牌  4跟注  8加注
	optional int32  seq       = 3; // 操作序号
	optional int32  last_raise= 4; // 上一次加注的值	
}

------------------------------------------------------------------------------------------
1.请求坐下/站起  

(进房间后默认分配座位号为-1,表示站起状态)
(客户端可以通过用户信息的座位号来区分是否站起坐下状态)

StandSitRequest 10001

	msg_body = {// message RoomContentRequest
		req_type    = 10001; //
		req_content = { // message StandSitRequest
			type   = 2;// // 1站起 2坐下
		}
	};

成功则 服务器推送给所有人UserInfoPush(公共协议参见protocol.md);失败无返回;

2.请求携带筹码(下局才生效)

BringChipsRequest 10004

	msg_body = {// message RoomContentRequest
		req_type    = 10004; //
		req_content = { // message BringChipsRequest
			chip   = 1000;//加筹码
		}
	};

成功则 服务器推送给所有人UserInfoPush(公共协议参见protocol.md);失败无返回;
(TableInfoPush.expand_content.bring_chips)

3.请求操作

OpRequest 10007

	msg_body = {// message RoomContentRequest
		req_type    = 10004; //
		req_content = { // message OpRequest
			type   = 8;   // 1看牌/过牌   2弃牌  4跟注  8加注
			value  = 500; // 跟注或加注的值
			seq    = 68;  // 操作序号
		}
	};

成功/失败 服务器推送给所有人DzTableStatusPush;

4.牌桌状态推送

DzTableStatusPush  10010

	msg_body = { //message RoomContentResponse
		//每一个type对应一条消息 编解码content，这个映射关系有两部分组成 
		//小于10000的通用消息 位于文件servers/preload/msg.lua,
		//大于10000的由子游戏自行约定
		type    = 10010; 
		content = { // message DzTableStatusPush
			info               = {//repeated message UserVoteInfo
				common_cards   = { 0x11, 0x23, 0x08, -1, -1};
				banker         = 0;
				xiao_mang      = 1;
	            da_mang        = 2;
				user_cards     = { //repeated message UserCardInfo  玩家手牌,当前最大牌型信息
					{
						brand_type = 2;
						hand_cards = { 0x31, 0x21 };
						seat       = 0;
					};
					{
						brand_type = 2;
						hand_cards = { 0x35, 0x25 };
						seat       = 0;
					};
					...
				};
				chips_pool     = { //repeated message ChipsPoolInfo  筹码池信息 多人allin 需分池
					{
						chips  = 500;//筹码数
						users  = {0,1,2,3,4};//参与分池的玩家座位号	
					};
					{
						chips  = 112;//筹码数
						users  = {1,2,3,4};//参与分池的玩家座位号	
					}
					...
				};
				op_info        = {// optional message OpInfo 当前操作玩家的 可操作信息
					seat       = 1; // 当前操作玩家座位号
					actions    = 15; // 位标记 1看牌/过牌   2弃牌  4跟注  8加注
					seq        = 68; // 操作序号
					last_raise = 50; // 上一次加注的值
				};
			};

			users_info         = { //repeated message common.TableUserInfo
				{
					user_id = 0;
					seat    = 1;
					ready   = true;
					online  = true;
					status  = 0;
					score   = 0;
					expand_content = { //bytes 子游戏额外扩展信息 message TableUserExpandInfo
						bring_chips  = 0;// 累计带入场的总筹码数
						effect_chips = 0;// 当前这一局 可使用的有效筹码
						bet_chips    = 0;// 当前这一轮 的已下注筹码
						flag         = 0; // 用户标记  1看牌 2加注 3跟注  0无
					}
				}
				...
			}
		}
	};