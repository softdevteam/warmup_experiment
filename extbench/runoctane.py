#! /usr/bin/env python2.7

import csv, os, socket, sys, time
from decimal import Decimal
from krun.platform import detect_platform
from krun.config import Config
from krun.util import run_shell_cmd_bench

WARMUP_DIR = os.path.realpath(os.path.dirname(os.path.dirname(__file__)))
LD_LIBRARY_PATH=os.environ.get("LD_LIBRARY_PATH", "")

JAVASCRIPT_VMS = {
    "v8": "sh -c 'cd %s/extbench/octane && LD_LIBRARY_PATH=%s %s/work/v8/out/native/d8 run_we.js'"
          % (WARMUP_DIR, LD_LIBRARY_PATH, WARMUP_DIR),
}

# We only run spidermonkey/octane on Linux. It appears to be broken on OpenBSD (hangs on start).
if sys.platform.startswith("linux"):
    JAVASCRIPT_VMS["spidermonkey"] = (
	"sh -c 'cd %s/extbench/octane && LD_LIBRARY_PATH=%s "
	"%s/work/spidermonkey/js/src/build_OPT.OBJ/dist/bin/js run_we.js'") % \
	    (WARMUP_DIR, LD_LIBRARY_PATH, WARMUP_DIR)
if os.getenv("SSH_DO_COPY"):
    SSH_KEY = "~kruninit/warmup_experiment/id_rsa"
    SSH_HOST = "bencher2.soft-dev.org"
    SSH_USER = "vext01"
    SSH_COPY_DIR = "research/krun_results"
    SSH_DO_COPY = True
else:
    SSH_DO_COPY = False

# Note that the iteration count is duplicated in octane/run_we.js and must
# match the value here.
ITERATIONS = 2000
PROCESSES = 30

def main():
    platform = detect_platform(None, Config())
    platform.check_preliminaries()
    platform.sanity_checks()
    for jsvm_name, jsvm_cmd in JAVASCRIPT_VMS.items():
        csvp = "octane.%s.results" % jsvm_name
        with open(csvp, 'wb') as csvf:
            sys.stdout.write("%s:" % jsvm_name)
            writer = csv.writer(csvf)
            writer.writerow(['processnum', 'benchmark'] + range(ITERATIONS))
            for process in range(PROCESSES):
                sys.stdout.write(" %s" % str(process))
                sys.stdout.flush()
                # Flush the CSV writing, and then give the OS some time
                # to write stuff out to disk before running the next process
                # execution.
                csvf.flush()
                os.fsync(csvf.fileno())
                if SSH_DO_COPY:
                    os.system("cat %s | ssh -o 'BatchMode yes' -i %s %s@%s 'cat > %s/%s.octane.%s.results'" \
                              % (csvp, SSH_KEY, SSH_USER, SSH_HOST, \
                                 SSH_COPY_DIR, socket.gethostname(), jsvm_name))
                time.sleep(3)

                stdout, stderr, rc = run_shell_cmd_bench(jsvm_cmd, platform)
                if rc != 0:
                    sys.stderr.write(stderr)
                    sys.exit(rc)
                times = None
                for line in stdout.splitlines():
                    assert len(line) > 0
                    # Lines beginning with something other than a space are the
                    # name of the next benchmark to run. Lines beginning with a
                    # space are the timings of an iteration
                    if line[0] == " ":
                        # Times are in ms, so convert to seconds (without any
                        # loss of precision).
                        times.append(str(Decimal(line.strip()) / 1000))
                    else:
                        assert times is None or len(times) == ITERATIONS
                        if times is not None:
                            writer.writerow([process, bench_name] + times)
                        bench_name = line.strip()
                        times = []
                assert len(times) == ITERATIONS
                writer.writerow([process, bench_name] + times)
            sys.stdout.write("\n")
    platform.save_power()


if __name__ == '__main__':
    main()
