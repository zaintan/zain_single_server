------------------------------------------------------
---! @file
---! @brief StatePlay
------------------------------------------------------
local Super     = require("abstract.BaseState")
local StatePlay = class(Super)

--初始化顺序 从上到下
StatePlay._behavior_cfgs_ = {
    { path = "behaviors.state.handles";  bArgs = false; },
    --{ path = "behaviors.state.round";    bArgs = false; },
}

function StatePlay:onInit()
	-- body
end

function StatePlay:onEnter()
	Log.i("","State:%d onEnter",self.m_status)
end

function StatePlay:onExit()
	Log.i("","State:%d onExit",self.m_status)
end


function StatePlay:onOutCardReq(uid, msg_id, data)
	--return _retDefaultMsg(uid, msg_id)
end

function StatePlay:onOperateCardReq(uid, msg_id, data)
	--return _retDefaultMsg(uid, msg_id)
end


return StatePlay