------------------------------------------------------
---! @file
---! @brief test_client 的启动文件
------------------------------------------------------



local packetHelper  = (require "PacketHelper").create({"protos/hall.pb","protos/table.pb"})
---! 依赖库
local skynet        = require "skynet"
local socket        = require "skynet.socket"
require "skynet.manager"

local fd  = nil
local recv_server_handler = {}
local console_cmd = {}


local info = {
    uid     = -1;
    room_id = 0;
}

local LOGTAG = "[client]"

local function unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte(1) * 256 + text:byte(2)
    if size < s+2 then
        return nil, text
    end

    return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
    local result
    result, last = unpack_package(last)
    if result then
        return result, last
    end
    local r = socket.read(fd)--socket.recv(fd)
    if not r then
        return nil, last
    end
    if r == "" then
        error "Server closed"
    end
    return unpack_package(last .. r)
end

local function sendPacket( packet )
    local data = string.pack(">s2", packet)
    socket.write(fd, data)

end


local function decode_data(data)
    Log.d(LOGTAG,"recvServerMsg")
    local args    = packetHelper:decodeMsg(msg.Root,data)
    local msgName = msg.IdToName[args.msg_id]
    if not msgName then 
        Log.e(LOGTAG,"recv unknown msg_id:%d",args.msg_id)
        return 
    end 
    local data,err = packetHelper:decodeMsg(msgName, args.msg_body)    
    Log.dump(LOGTAG,data)

    if recv_server_handler[args.msg_id] then 
        recv_server_handler[args.msg_id](data)
    end 
end

local last = ""
local function dispatch_package()
    while true do
        local v
        v, last = recv_package(last)
        if not v then
            break
        end
        decode_data(v)
        skynet.sleep(100)
        --print_package(host:dispatch(v))
    end
end

local function sendMsg(msg_id, data)

        Log.d(LOGTAG,"send msg_id=%d",msg_id)
        Log.dump(LOGTAG,data)

    local protoName = msg.IdToName[msg_id] 
    local body      = packetHelper:encodeMsg(protoName, data)
    local packet    = packetHelper:makeProtoData(msg_id , body)
    sendPacket(packet)
    return true
end


local function sendRoomMsg(msg_id, data)
    Log.d(LOGTAG,"send room: msg_id=%d",msg_id)
    Log.dump(LOGTAG,data)
    local ret = {
        req_type    = msg_id;
        req_content = packetHelper:encodeMsg(msg.IdToName[msg_id] , data);
    }
    return sendMsg(msg.NameToId.RoomContentRequest, ret)
end


recv_server_handler[msg.NameToId.LoginResponse] = function ( data )
    if data.status >= 0 then 
        info.uid = data.user_info.user_id
    end 
end

recv_server_handler[msg.NameToId.CreateRoomResponse] = function ( data )
    if data.status >= 0 then 
        info.room_id = data.room_id
    end 
end


console_cmd.login = function ()
    sendMsg(msg.NameToId.LoginRequest, {
        login_type  = 1;
        token       = skynet.getenv("ClientName");
        platform    = 3;
        client_version = "1.0.0";
        game_index     = 1;
    })
    return true
end

console_cmd.create = function ()
     sendMsg(msg.NameToId.CreateRoomRequest, {
        create_type  = 1;
        game_id      = 1001;
        game_type    = 10001;
        game_rules   = {
            {id = 1;   value = 2;};
            {id = 1002;value = 1;};
            {id = 3;   value = 1;}; 
            {id = 4;   value = 1;};                                   
        };
    })
    return true
end

console_cmd.join = function ( id )
     sendMsg(msg.NameToId.JoinRoomRequest, {
        room_id  = id;
    })
    return true
end
---! 服务的启动函数
skynet.start(function()
    Log.d(LOGTAG, "start...")
    
    skynet.newservice("debug_console", 9999)

    ---! 初始化随机数
    fd = socket.open("127.0.0.1", 8100)

    Log.d(LOGTAG, "connected 127.0.0.1:8100")
    skynet.sleep(200)

    skynet.fork(function ()
        while true do 
            dispatch_package()
            skynet.sleep(1)
        end 
    end)

    skynet.fork(function ()
        while true do 
            sendMsg(msg.NameToId.HeartRequest,{})
            skynet.sleep(10 * 100)
        end 
    end)

    --skynet.sleep(1000)
    --send_login()
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_,_, cmd, ...)
        Log.d(LOGTAG, "recv cmd:%s", cmd)
        local f = console_cmd[cmd]
        if f then
            local ret = f(...)
            if ret then
                skynet.ret(skynet.pack(ret))
            end
        else
            Log.e(LOGTAG,"unknown command:%s", cmd)
        end
    end)

    skynet.register(".client")
end)