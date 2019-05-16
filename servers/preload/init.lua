log_level = 4
Log       = Log or (require "LogHelper")
----------------------------------------------
local cp = require "config_parse"
const    = cp.parseConsts()
msg      = cp.parseMsg()
----------------------------------------------
base = require "base"

require "expand"
require "functions"

--require "bit"