
“
ZainCommon.protoZain"ﬂ
	ProtoInfo
	main_type (
sub_type (
msg_id (
msg_body (
reservedn ("@
ProtoMainType
REQUEST
RESPONSE

UPLOAD
PUSH"7
ProtoSubType
GATE
HALL	
ALLOC
ROOM"ò
AccountInfo
user_id (
	user_name (	
head_img_url (	
sex (
diamond (
gold (
	vip_level (
reservedn ("å
RoomUserInfo
user_id (
	user_name (	
head_img_url (	
score (

seat_index (
ready (
reservedn ("?
ChiGroupCard
lou_weave_count (
lou_weave_kind ("Ê
WeaveItemInfo

weave_kind (
center_card (
public_card (
provide_player (
hu_xi (+
chi_group_cards (2.Zain.ChiGroupCard
weave_cards (
client_special_cards (
reservedn ("∫
PlayerCardsInfo
	has_hands (

has_weaves (
has_discards (
hands (
discards (#
weaves (2.Zain.WeaveItemInfo

seat_index (
reservedn ("D
OperateInfo#
weaves (2.Zain.WeaveItemInfo
reservedn ("È
RoundRoomInfo
cur_val (

remain_num (
	total_num (

cur_banker (
pointed_seat_index (
player_statuses (
head_send_count (
tail_send_count (
dice_values	 (
reservedn ("Å
LoginRequest

login_type (
token (	
platform (
client_version (	

game_index (
reservedn ("k
LoginResponse
status (

status_tip (	$
	user_info (2.Zain.AccountInfo
reservedn ("ó
CreateRoomRequest
create_type (
game_id (
	game_type (

game_rules (
	over_type (
over_val (
reservedn ("[
CreateRoomResponse
status (

status_tip (	
room_id (
reservedn ("4
JoinRoomRequest
room_id (
reservedn ("Ó
JoinRoomResponse
status (

status_tip (	
game_id (
	game_type (

game_rules (#
players (2.Zain.RoomUserInfo
game_status (
	over_type	 (
over_val
 (,
round_room_info (2.Zain.RoundRoomInfo"
op_info (2.Zain.OperateInfo*
cards_infos (2.Zain.PlayerCardsInfo
room_id (
reservedn ("/
ReadyRequest
ready (
reservedn ("0
ReadyResponse
ready (
reservedn ("@
	ReadyPush
ready (

seat_index (
reservedn ("d
GameStartPush,
round_room_info (2.Zain.RoundRoomInfo
game_status (
reservedn ("
HeartRequest"
HeartResponse"A
CommonTipsPush
type (
content (	
reservedn ("{
PlayerStatusPush
player_status (
pointed_seat_index ("
op_info (2.Zain.OperateInfo
reservedn ("H
CardTypePush

seat_index (

card_types (
reservedn ("M
RoomCardsPush*
cards_infos (2.Zain.PlayerCardsInfo
reservedn ("Ú
GameFinishPush#
players (2.Zain.RoomUserInfo,
round_room_info (2.Zain.RoundRoomInfo
room_id (*
cards_infos (2.Zain.PlayerCardsInfo
remain_cards (
finish_desc (	
game_status (
reservedn ("O
DispatchCardPush
dispatch_card (

seat_index (
reservedn ("O
PlayerCardsPush*
cards_infos (2.Zain.PlayerCardsInfo
reservedn ("c
OperateCardRequest

seat_index (

weave_kind (
center_card (
reservedn ("K
OperateCardResponse
status (

status_tip (	
reservedn ("K
OperateCardPush

seat_index (

weave_kind (
reservedn ("H
OutCardRequest

seat_index (
out_card (
reservedn ("G
OutCardResponse
status (

status_tip (	
reservedn ("E
OutCardPush

seat_index (
out_card (
reservedn (B
protobuf.cher