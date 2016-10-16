-- Call out to C to get the monotonic time
local ffi = require("ffi")
ffi.cdef[[ double krun_clock_gettime_monotonic(); ]]
local kruntime = ffi.load("kruntime")

local BM_start_time = kruntime.krun_clock_gettime_monotonic()
io.stdout:write(BM_start_time)
io.stdout:write("] }")
