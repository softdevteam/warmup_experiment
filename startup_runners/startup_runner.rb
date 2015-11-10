if RUBY_PLATFORM == "java" then
    # "java" means JRuby.
    def clock_gettime_monotonic()
        # JRuby does not (yet) provide access to the (raw) monotonic clock, and
        # adding support is non-trivial (not as simple as adding the C
        # constant).  For now we patch JRuby/Truffle to expose our libkruntime
        # function.
        Truffle::Primitive.clock_gettime_monotonic()
    end
elsif /linux/ =~ RUBY_PLATFORM then
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
    STDOUT.write "]"
end
