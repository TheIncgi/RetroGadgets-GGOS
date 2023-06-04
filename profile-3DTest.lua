require"RG_Emulate"

local Profiler = require"Profiler"
local profiler = Profiler:new()
PROFILER = profiler
_G.PROFILER = PROFILER

-- function test3()
--     profiler:onHook("return")
-- end
-- function test2()
--     profiler:onHook("call")
--     test3()
-- end
-- function test()
--   test2()
--   test2()
-- end

-- test()

require"Run3DTest"
profiler:stop()
profiler:save("profiler.json")
profiler:show()