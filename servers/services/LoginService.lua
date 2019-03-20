-------------------------------------------------------------
---! @file  LoginService.lua
---! @brief 
--------------------------------------------------------------

local skynet    = require "skynet"
require "skynet.manager"

---! 辅助依赖
local NumSet       = require "NumSet"

---! all users:  k = userid; v = User;
local CacheUserMap      = NumSet.create()
---! all quick login token;  k = token; v = accountId;
local CacheTokenMap     = NumSet.create()
local CacheLimitCount   = 2048

local dbAddr            = skynet.uniqueservice("DBService")

---! lua commands
local CMD = {}

function CMD.on_login(msg_id, msg_body)
    --if true then
    return true
end

----注意清缓存
function CMD.logout(source, uid)
    return true
end

function CMD.query(source, uid )
    return false
end


local function checkCleanCache()
    local timeout = 3600 --1h -3600s
    while true do 

        skynet.sleep(timeout * 100)
    end 
end

---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            local ret = f(source, ...)
            if ret then
                skynet.ret(skynet.pack(ret))
            end
        else
            Log.e(LOGTAG,"unknown command:%s", cmd)
        end
    end)

    skynet.fork(checkCleanCache)
end)