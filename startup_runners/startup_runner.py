"""
Iterations runner for Python VMs.
Derived from iterations_runner.php.

Executes a benchmark many times within a single process.

In Kalibera terms, this script represents one executions level run.
"""

import cffi, sys, imp, os

ffi = cffi.FFI()
ffi.cdef("double clock_gettime_monotonic();")
libkruntime = ffi.dlopen("libkruntime.so")

clock_gettime_monotonic = libkruntime.clock_gettime_monotonic

print clock_gettime_monotonic(), "], [-1.0, -1.0]]"
