-------------------------------------------------------------
---! @file  LoginService.lua
---! @brief 
--------------------------------------------------------------

local skynet    = require "skynet"
require "skynet.manager"

local queue  = require "skynet.queue"
local cs     = queue()


---! 辅助依赖
local NumSet       = require "NumSet"

---! all users:  k = userid; v = User;
local CacheUserMap      = NumSet.create()
---! all quick login token;  k = token; v = accountId;
local CacheTokenMap     = NumSet.create()

local CacheLimitCount   = 2048

local LOGTAG = "LOGIN"
-----------------------------------------------------------------------------------------
local function _onLoginFalid(tip)
    Log.d(LOGTAG,"failed:",tip)
    return {status = -1;status_tip = tip;}
end

local function _onLoginSuccess(uid)
    Log.d(LOGTAG,"success:%d",uid)
    local user = CacheUserMap:getObject(uid)
    local info = {}
    info.user_id      = user.FUserID
    info.user_name    = user.FUserName
    info.head_img_url = user.FHeadUrl
    info.sex          = user.FSex
    info.diamond      = user.FDiamond
    info.gold         = user.FGold
    --info.vip_level    = user.F
    return {status = 0;user_info = info;}
end

--创建新用户
local function _createNewUser( reqData )
    local args = {}

    args.FPlatformID   = reqData.token or "default"
    args.FPlatformType = reqData.platform or 3
    args.FGameIndex    = reqData.game_index or 0
    args.FSex          = reqData.sex or 1

    args.FUserName     = tostring(args.FPlatformID)
    args.FHeadUrl      = ""
    args.FDiamond      = 10
    args.FGold         = 1000

    return args
end
--缓存用户信息
local function _updateCacheUser(uid ,agent, dbInfo )
    local user = CacheUserMap:getObject(uid)
    if not user then 
        local tmp = {}
        tmp.FUserID        = dbInfo.FUserID
        tmp.FPlatformID    = dbInfo.FPlatformID
        tmp.FUserName      = dbInfo.FUserName
        tmp.FHeadUrl       = dbInfo.FHeadUrl
        tmp.FSex           = dbInfo.FSex
        tmp.FDiamond       = dbInfo.FDiamond
        tmp.FGold          = dbInfo.FGold
        tmp.FPlatformType  = dbInfo.FPlatformType
        tmp.FGameIndex     = dbInfo.FGameIndex

        tmp.agent          = agent

        CacheUserMap:addObject(tmp, uid)
        CacheTokenMap:addObject(tmp.FUserID, tmp.FPlatformID)
    else--已经缓存了 
        --已经有登录的了 --重复登录 t下线
        if user.agent and user.agent ~= agent then 
            -- !!踢错了  提了新的 -_-!!
            --pcall(skynet.call, agent, "lua", "disconnect")
            Log.d(LOGTAG,"repeat login! kick start...")
            pcall(skynet.call, user.agent, "lua", "disconnect")
            Log.d(LOGTAG,"repeat login! kick over!")
        end 
        user.agent = agent
    end 
end

--注册用户
--[[
insert into TUser(FPlatformID,FUserName,FHeadUrl,FSex,FDiamond,FGold,FPlatformType,FGameIndex,FRegDate,FLastLoginTime)
values('tzy','zaintan','','1','10','1000','3','0',NOW(),NOW());
+---------+-------------+-----------+----------+------+----------+-------+---------------+------------+------------+---------------------+
| FUserID | FPlatformID | FUserName | FHeadUrl | FSex | FDiamond | FGold | FPlatformType | FGameIndex | FRegDate   | FLastLoginTime      |
+---------+-------------+-----------+----------+------+----------+-------+---------------+------------+------------+---------------------+
|    1000 | tzy         | zaintan   |          |    1 |       10 |  1000 |             3 |          0 | 2018-11-02 | 2018-11-02 17:18:14 |
+---------+-------------+-----------+----------+------+----------+-------+---------------+------------+------------+---------------------+
]]
local function _registerGuestUser(reqData)
    Log.d(LOGTAG,"register user start...")
    local info = _createNewUser(reqData)
    --插入数据库
    local sqlStr = string.format("insert into TUser(FPlatformID,FUserName,FHeadUrl,FSex,FDiamond,FGold,FPlatformType,FGameIndex,FRegDate,FLastLoginTime) values('%s','%s','%s','%d','%d','%d','%d','%d','%s','%s');", 
            info.FPlatformID,info.FUserName,info.FHeadUrl,info.FSex,info.FDiamond,info.FGold,info.FPlatformType,info.FGameIndex,"NOW()","NOW()");
    
    local pRet   = skynet.call(".DBService", "lua", "execDB", sqlStr)
    Log.d(LOGTAG,"register insert db over...")
    if not pRet then 
        return nil
    end    

    local sqlStr = string.format("select * from TUser where FPlatformID=\"%s\";",info.FPlatformID)
    local pRet   = skynet.call(".DBService", "lua", "execDB", sqlStr)
    Log.d(LOGTAG,"register query db over")
    if pRet and type(pRet) == "table" and #pRet > 0 then 
        info.FUserID        = tonumber(pRet[1].FUserID)
        info.FRegDate       = pRet[1].FRegDate
        info.FLastLoginTime = pRet[1].FLastLoginTime
    else--找不到
        return nil
    end  
    return info
end



-----------------------------------------------------------------------------------------
---! lua commands
local CMD = {}

local function _seq_on_login(agent, reqData)
    Log.d(LOGTAG,"recv cmd on_login")
    if not reqData.login_type or not reqData.token then 
        return _onLoginFalid("缺失必要的登录参数！")
    end 

    if reqData.login_type == const.LoginType.USER then --游客登录
        local userid = CacheTokenMap:getObject(reqData.token)
        if userid then --缓存里查到了
            _updateCacheUser(userid,agent)
            return _onLoginSuccess(userid)
        else--缓存里面没有  需要去查数据库
            Log.d(LOGTAG,"query db start...")
            local sqlStr = string.format("select * from TUser where FPlatformID=\"%s\";",reqData.token)
            local pRet   = skynet.call(".DBService", "lua", "execDB", sqlStr)
            Log.d(LOGTAG,"query db over!")
            if pRet and type(pRet) == "table" then 
                if #pRet <= 0 then --数据库查询不到
                    --register
                    local registerRet = _registerGuestUser(reqData)
                    if registerRet then 
                        _updateCacheUser(registerRet.FUserID ,agent, registerRet)
                        return _onLoginSuccess(registerRet.FUserID)
                    else
                        return _onLoginFalid("注册失败!")
                    end  
                else--数据库查询到了
                    _updateCacheUser(pRet[1].FUserID, agent, pRet[1])
                    return _onLoginSuccess(pRet[1].FUserID)
                end
            else--找不到
                return _onLoginFalid("数据库链接失败!")
            end 
        end 
    end 
    return _onLoginFalid("暂不支持的登录方式！")
end

----注意清缓存
local function _seq_logout(source,uid)
    Log.d(LOGTAG,"recv cmd logout uid:",uid)
    local user = CacheUserMap:getObject(uid)
    if user then 
        user.agent = nil
        user.logoutTime = os.time()
    end 
    return true
end

--function CMD.query(source,uid )
local function _seq_query( source,uid )
    --Log.d(LOGTAG,"recv cmd query")
    local obj = CacheUserMap:getObject(uid)
    if not obj then 
        return false
    end 

    return {
        FUserID   = obj.FUserID;
        FUserName = obj.FUserName;
        FHeadUrl  = obj.FHeadUrl;
    };
end
--local cs  = queue()
function CMD.on_login(agent,reqData)
    return cs(function()
        return _seq_on_login(agent,reqData)
    end)
end

function CMD.logout(source,uid)
    return cs(function()
        return _seq_logout(source,uid)
    end)
end

function CMD.query(source,uid)
    return cs(function()
        return _seq_query(source,uid)
    end)
end


local function checkCleanCache()
    local timeout = 3600 --1h -3600s

    local ExpireTime = 3600*24

    while true do 
        local curTime = os.time()

        local removeUserKeys = {}
        local removeTokenKeys = {}
        CacheUserMap:forEach(function (user)
            if user.agent == nil and user.logoutTime ~= nil then
                if curTime - user.logoutTime > ExpireTime then 
                    table.insert(removeUserKeys,  user.FUserID)
                    table.insert(removeTokenKeys, user.FPlatformID)
                end 
            end 
        end)
        CacheUserMap:removeObjects(removeUserKeys)
        CacheTokenMap:removeObjects(removeTokenKeys)

        skynet.sleep(timeout * 100)
    end 
end

---! 服务的启动函数
skynet.start(function()
    ---! 初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

    skynet.register(".LoginService")
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            local ret = f(source,...)
            if ret then
                skynet.ret(skynet.pack(ret))
            end
        else
            Log.e(LOGTAG,"unknown command:%s", cmd)
        end
    end)

    skynet.newservice("DBService")
    skynet.fork(checkCleanCache)
end)