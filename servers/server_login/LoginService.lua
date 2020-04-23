-------------------------------------------------------------
---! @file  LoginService.lua
---! @brief 
--------------------------------------------------------------

local skynet    = require "skynet"
require "skynet.manager"

local queue  = require "skynet.queue"
local cs     = queue()

local ClusterHelper = require "ClusterHelper"

---! 辅助依赖
local NumSet       = require "NumSet"
---! all users:  k = userid; v = User;
local CacheUserMap      = NumSet.create()
---! all quick login token;  k = token; v = accountId;
local CacheTokenMap     = NumSet.create()

local CacheLimitCount   = 10240

local LOGTAG = "LOGIN"
-----------------------------------------------------------------------------------------

local function _onLoginSuccess(uid)
    Log.d(LOGTAG,"login success:%d",uid)

    local ret = g_createMsg(MsgCode.LoginSuccess)

    local user = CacheUserMap:getObject(uid)
    local info = {}
    info.user_id      = user.FUserID
    info.user_name    = user.FUserName
    info.head_img_url = user.FHeadUrl
    info.sex          = user.FSex
    info.diamond      = user.FDiamond
    info.gold         = user.FGold

    ret.user_info = info
    return ret--{status = 0;user_info = info;}
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
local function _updateCacheUser(uid ,agentNode,agentAddr, dbInfo )
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

        tmp.agentNode      = agentNode
        tmp.agentAddr      = agentAddr

        CacheUserMap:addObject(tmp, uid)
        CacheTokenMap:addObject(tmp.FUserID, tmp.FPlatformID)
    else--已经缓存了 
        --已经有登录的了 --重复登录 t下线
        if user.agentNode and user.agentNode ~= agentNode and user.agentAddr ~= agentAddr then 
            -- !!踢错了  提了新的 -_-!!
            Log.i(LOGTAG,"重复登录! t掉之前的登录...")
            local ok,_ = ClusterHelper.callIndex( user.agentNode, user.agentAddr, "disconnect", uid)
            if not ok then 
                Log.e(LOGTAG,"maybe err!重复登录!kick失败!")
            end 
        end 
        user.agentNode = agentNode
        user.agentAddr = agentAddr
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
    local info = _createNewUser(reqData)

    local curDate = os.date("%Y-%m-%d %H:%M:%S")
    --插入数据库
    local sqlStr = string.format("insert into TUser(FPlatformID,FUserName,FHeadUrl,FSex,FDiamond,FGold,FPlatformType,FGameIndex,FRegDate,FLastLoginTime) values('%s','%s','%s','%d','%d','%d','%d','%d','%s','%s');", 
            info.FPlatformID,info.FUserName,info.FHeadUrl,info.FSex,info.FDiamond,info.FGold,info.FPlatformType,info.FGameIndex,curDate,curDate);
    Log.i(LOGTAG,sqlStr)
    local pRet   = skynet.call(".DBService", "lua", "execDB", sqlStr)
    if not pRet then 
        return nil
    end    

    local sqlStr = string.format("select * from TUser where FPlatformID=\"%s\";",info.FPlatformID)
    Log.i(LOGTAG,sqlStr)
    local pRet   = skynet.call(".DBService", "lua", "execDB", sqlStr)
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

local function _seq_on_login(reqData,agentNode,agentAddr)
    Log.d(LOGTAG,"recv login req from node=%s addr=%s",tostring(agentNode), tostring(agentAddr))
    Log.dump(LOGTAG,reqData)

    if not reqData.login_type or not reqData.token then 
        return g_createMsg(MsgCode.LoginFailedArgs)
    end 

    if reqData.login_type == const.LoginType.USER then --游客登录
        local userid = CacheTokenMap:getObject(reqData.token)
        if userid then --缓存里查到了
            _updateCacheUser(userid,agentNode,agentAddr)
            return _onLoginSuccess(userid)
        else--缓存里面没有  需要去查数据库

            local sqlStr = string.format("select * from TUser where FPlatformID=\"%s\";",reqData.token)
            local pRet   = skynet.call(".DBService", "lua", "execDB", sqlStr)
            if pRet and type(pRet) == "table" then 
                if #pRet <= 0 then --数据库查询不到
                    --register
                    local registerRet = _registerGuestUser(reqData)
                    if registerRet then 
                        _updateCacheUser(registerRet.FUserID ,agentNode,agentAddr, registerRet)
                        return _onLoginSuccess(registerRet.FUserID)
                    else
                        return g_createMsg(MsgCode.LoginFailedRegister)
                    end  
                else--数据库查询到了
                    _updateCacheUser(pRet[1].FUserID, agentNode,agentAddr, pRet[1])
                    return _onLoginSuccess(pRet[1].FUserID)
                end
            else--找不到
                return g_createMsg(MsgCode.LoginFailedLinkDB)
            end 
        end 
    end 
    return g_createMsg(MsgCode.LoginFailedType)
end

----注意清缓存
local function _seq_logout(uid,agentNode,agentAddr)
    local user = CacheUserMap:getObject(uid)
    if user then 
        if user.agentNode == agentNode and user.agentAddr == agentAddr then 
            user.agentNode      = nil
            user.agentAddr      = nil
            user.logoutTime     = os.time()
        else 
            Log.i(LOGTAG,"logout maybe err! uid:%d loginNode=%s loginAddr=%s logoutNode=%s logoutAddr=%s",uid,tostring(user.agentNode),tostring(user.agentAddr),tostring(agentNode),tostring(agentAddr))
        end 
    else 
        Log.e(LOGTAG,"logout failed!缓存里找不到该玩家uid:%d",uid)
    end 
    return true
end


--local cs  = queue()--data, nodeName, skynet.self()
function CMD.login(reqData,agentNode,agentAddr)
    return cs(function()
        return _seq_on_login(reqData,agentNode,agentAddr)
    end)
end

function CMD.logout(uid,agentNode,agentAddr)
    return cs(function()
        return _seq_logout(uid,agentNode,agentAddr)
    end)
end

local function clearExpireUser()
    cs(function ()
        local ExpireTime = 3600*24
        local curTime    = os.time()

        local removeUserKeys = {}
        local removeTokenKeys = {}
        CacheUserMap:forEach(function (user)
            if user.agentNode == nil and user.logoutTime ~= nil then
                if curTime - user.logoutTime > ExpireTime then 
                    table.insert(removeUserKeys,  user.FUserID)
                    table.insert(removeTokenKeys, user.FPlatformID)
                end 
            end 
        end)
        CacheUserMap:removeObjects(removeUserKeys)
        CacheTokenMap:removeObjects(removeTokenKeys)
    end)
end


local function checkCleanCache()
    local timeout = 3600 --1h -3600s
    --24小时没登录就清掉 
    local ExpireTime = 3600*24
    while true do 
        local startTime = os.time()
        clearExpireUser()
        local stopTime  = os.time()
        Log.i(LOGTAG,"清理缓存耗时:%d", stopTime-startTime)
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
            local ret = f(...)
            if ret then
                skynet.ret(skynet.pack(ret))
            end
        else
            Log.e(LOGTAG,"unknown command:%s", cmd)
        end
    end)

    skynet.fork(checkCleanCache)
end)