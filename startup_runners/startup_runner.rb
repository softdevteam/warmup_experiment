# defined this way so we don't measure the conditional platform check.
if /linux/ =~ RUBY_PLATFORM then
    def clock_gettime_monotonic()
        Process.clock_gettime(Process::CLOCK_MONOTONIC_RAW)
    end
else
    def clock_gettime_monotonic()
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
end

if __FILE__ == $0
    start_time = clock_gettime_monotonic()
    STDOUT.write String(start_time)
    STDOUT.write "], [-1.0, -1.0]]"
end
