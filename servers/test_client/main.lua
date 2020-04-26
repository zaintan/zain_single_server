------------------------------------------------------
---! @file
---! @brief test_client 的启动文件
------------------------------------------------------
local socket = require "client.socket"

local packetHelper  = (require "PacketHelper").create({"protos/hall.pb","protos/table.pb"})
---! 依赖库
local skynet        = require "skynet"

local fd = nil

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
    local r = socket.recv(fd)
    if not r then
        return nil, last
    end
    if r == "" then
        error "Server closed"
    end
    return unpack_package(last .. r)
end


local function decode_data(data)
    local args    = packetHelper:decodeMsg(msg.Root,data)
    local msgName = msg.IdToName[args.msg_id]
    if not msgName then 
        Log.e(LOGTAG,"recv unknown msg_id:%d",args.msg_id)
        return 
    end 
    local data,err = packetHelper:decodeMsg(msgName, args.msg_body)    
    Log.dump(LOGTAG,data)
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

local function sendPacket( packet )
    local data = string.pack(">s2", packet)
    socket.send(fd, data)
end

local function sendMsg(msg_id, data)

    --if msg_id ~= msg.NameToId.HeartResponse then
        Log.d(LOGTAG,"sendClientMsg msg_id=%d",msg_id)
        Log.dump(LOGTAG,data)
    --end 
    local protoName = msg.IdToName[msg_id] 
    local body      = packetHelper:encodeMsg(protoName, data)
    local packet    = packetHelper:makeProtoData(msg_id , body)
    sendPacket(packet)
    return true
end

---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    fd = assert(socket.connect("127.0.0.1", 8100))
    skynet.sleep(100)
    skynet.fork(function ()
        while true do 
            dispatch_package()
            skynet.sleep(1)
        end 
    end)

    skynet.fork(function ()
        while true do 
            sendMsg(msg.NameToId.HeartResponse,{})
            skynet.sleep(10 * 100)
        end 
    end)

    skynet.sleep(1000)
    sendMsg(msg.NameToId.LoginRequest, {
        login_type  = 1;
        token       = skynet.getenv("ClientName");
        platform    = 3;
        client_version = "1.0.0";
        game_index     = 1;
    })

end)