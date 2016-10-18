"""
Iterations runner for Python VMs.
Derived from iterations_runner.php.

Executes a benchmark many times within a single process.

In Kalibera terms, this script represents one executions level run.
"""

import cffi

ffi = cffi.FFI()
ffi.cdef("""double krun_clock_gettime_monotonic(); """)
libkruntime = ffi.dlopen("libkruntime.so")

print libkruntime.krun_clock_gettime_monotonic(), "] }"
