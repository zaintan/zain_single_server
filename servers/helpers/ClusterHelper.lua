---------------------------------------------------
---! @file
---! @brief 配置解析
---------------------------------------------------

---! 依赖库
local skynet    = require "skynet"
local cluster   = require "skynet.cluster"

local cfgHelper = require "ConfigHelper"

local M = {}

function M.call(...)
--    local ok,ret = pcall(cluster.call,...)
--    if not ok then 
--        Log.e("","消息发送失败!to server_index=%d reason=%s",server_index, tostring(status))
--    	return false
--    end 
    return pcall(cluster.call,...)
end

function M.callIndex(server_index, ... )
    return M.call(cfgHelper.getCluserName(server_index),...)
end

return M

