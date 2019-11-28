
≥&
protos/proto/common.protoBase"?
	ProtoInfo
msg_id (
msg_body (
reservedn ("ò
AccountInfo
user_id (
	user_name (	
head_img_url (	
sex (
diamond (
gold (
	vip_level (
reservedn ("ù
RoomUserInfo
user_id (
	user_name (	
head_img_url (	
score (

seat_index (
ready (
creator (
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
chi_group_cards (2.Base.ChiGroupCard
weave_cards (
client_special_cards (
reservedn ("∫
PlayerCardsInfo
	has_hands (

has_weaves (
has_discards (
hands (
discards (#
weaves (2.Base.WeaveItemInfo

seat_index (
reservedn ("X
OperateInfo#
weaves (2.Base.WeaveItemInfo

operate_id (
reservedn ("í
GameRoomInfo
game_id (
	game_type (&

game_rules (2.Base.GameRuleInfo
game_status (
room_id (
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
reservedn ("|
LoginResponse
status (

status_tip (	$
	user_info (2.Base.AccountInfo
room_id (
reservedn ("Ü
CreateRoomRequest
create_type (
game_id (
	game_type (&

game_rules (2.Base.GameRuleInfo
reservedn ("[
CreateRoomResponse
status (

status_tip (	
room_id (
reservedn ("I
JoinRoomRequest
room_id (
random_join (
reservedn ("l
JoinRoomResponse
status (

status_tip (	
game_id (
	game_type (
reservedn (";
GameRuleInfo

id (
value (
reservedn ("G
PlayerEnterPush"
player (2.Base.RoomUserInfo
reservedn ("/
ReadyRequest
ready (
reservedn ("T
ReadyResponse
status (

status_tip (	
ready (
reservedn ("F
PlayerReadyInfo

seat_index (
ready (
reservedn ("I
	ReadyPush*
ready_infos (2.Base.PlayerReadyInfo
reservedn ("d
GameStartPush,
round_room_info (2.Base.RoundRoomInfo
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
op_info (2.Base.OperateInfo
reservedn ("H
CardTypePush

seat_index (

card_types (
reservedn ("M
RoomCardsPush*
cards_infos (2.Base.PlayerCardsInfo
reservedn ("ø
RoundFinishPush*
cards_infos (2.Base.PlayerCardsInfo
finish_desc (	
game_status (
	win_types (
final_scores (
round_finish_reason (
reservedn ("f
DispatchCardPush
dispatch_card (

seat_index (
dispatch_type (
reservedn ("O
PlayerCardsPush*
cards_infos (2.Base.PlayerCardsInfo
reservedn ("{
OperateCardRequest

weave_kind (
center_card (
provide_player (

operate_id (
reservedn ("K
OperateCardResponse
status (

status_tip (	
reservedn ("x
OperateCardPush

seat_index (

weave_kind (
provide_player (
center_card (
reservedn ("4
OutCardRequest
out_card (
reservedn ("G
OutCardResponse
status (

status_tip (	
reservedn ("E
OutCardPush

seat_index (
out_card (
reservedn ("9
RemoveDiscardPush

seat_index (
reservedn ("l
GameFinishPush,
player_infos (2.Base.PlayerResultInfo
game_finish_reason (
reservedn ("j
PlayerResultInfo
total_scores (.
special_counts (2.Base.SpecialCountInfo
reservedn ("?
SpecialCountInfo

id (
count (
reservedn ("m
ReleaseInfo
result (
tip (	
votes (
time (

seat_index (
reservedn ("H
ReleasePush'
release_info (2.Base.ReleaseInfo
reservedn ("D
ReleaseRequest
type (

vote_value (
reservedn ("G
ReleaseResponse
status (

status_tip (	
reservedn ("
PlayerExitRequest"J
PlayerExitResponse
status (

status_tip (	
reservedn ("6
PlayerExitPush

seat_index (
reservedn ("Q
ShowHandCardsPush*
cards_infos (2.Base.PlayerCardsInfo
reservedn ("ê
RoomInfoPush 
info (2.Base.GameRoomInfo'

round_info (2.Base.RoundRoomInfo#
players (2.Base.RoomUserInfo
reservedn (B
protobuf.cher