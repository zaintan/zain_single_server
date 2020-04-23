----------------------------------
---! @file
---! @brief server_single 的启动配置文件
----------------------------------
local _root		= "./"
local _skynet	= _root.."../skynet/"

---! server_single 用到的参数 从 命令行传的参数
ServerIndex    =  "$ServerIndex"
StartTime      =  "$StartTime"
ServerKind     =  "server_game"

----------------------------------
---!  自定义参数
----------------------------------
app_root       = _root.. ServerKind .."/"

----------------------------------
---!  skynet用到的六个参数
----------------------------------
---!  工作线程数
thread      = 4
---!  服务模块路径（.so)
cpath       = _skynet.."cservice/?.so"
---!  港湾ID，用于分布式系统，0表示没有分布
harbor      = 0
---!  后台运行用到的 pid 文件
daemon      = ServerKind.."_"..ServerIndex..".pid"
---!  日志文件
-- logger      = nil
logger      = "logs/"..ServerKind.."_"..ServerIndex.."_"..StartTime..".log"
--logpath     = "./logs/"
---!  初始启动的模块
bootstrap   = "snlua bootstrap"

---!  snlua用到的参数
lua_path    = _skynet.."lualib/?.lua;"..app_root.."?.lua;".._root .."algos/?.lua;".._root.."helpers/?.lua;".._root.."services/?.lua;".._root.."preload/?.lua"
lua_cpath   = _skynet.."luaclib/?.so;"..app_root.."cservice/?.so"
luaservice  = _skynet.."service/?.lua;".. app_root .. "?.lua;" .._root.."services/?.lua;"
lualoader   = _skynet.."lualib/loader.lua"
preload     = _root.."preload/".."init.lua"--..app_root.."preload/?.lua;"	-- run preload.lua before every lua service run

start       = "main"

---!  snax用到的参数
snax    = _skynet.."service/?.lua;".. app_root .. "?.lua;" .._root.."services/?.lua"


