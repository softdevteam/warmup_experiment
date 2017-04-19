#! /usr/bin/env python

import csv, os, socket, sys, time
from decimal import Decimal
from krun.platform import detect_platform
from krun.config import Config
from krun.util import run_shell_cmd_bench
from krun.vm_defs import find_internal_jvmci_java_home
from collections import OrderedDict

WARMUP_DIR = os.path.realpath(os.path.dirname(os.path.dirname(__file__)))

ITERATIONS = 2000
PROCESSES = 30

# broken: batik, eclipse, tomcat
WORKING_BENCHS   = ['avrora', 'fop', 'h2', 'jython', 'luindex', 'lusearch',
                    'pmd', 'sunflow', 'tradebeans', 'tradesoap', 'xalan']

# These fail with a socket error on OpenBSD/JVM, even with the firewall off.
# This seems to have happened with the upgrade to jdk8-u121 and OpenBSD-6.1.
DISABLE_ON_OPENBSD  = ['tradebeans', 'tradesoap']
# This gives checksum errors on OpenBSD/JVM with longer iteration counts. e.g.:
#   Digest validation failed for stderr.log,
#   expecting 0xda39a3ee5e6b4b0d3255bfef95601890afd80709
#   found     0xdd01309ada1e7d2c11398dd6b880bf21214a8ddb
#   ===== DaCapo 9.12 avrora FAILED =====
DISABLE_ON_OPENBSD.append('avrora')

DISABLE_ON_GRAAL = set([])

JAR = os.path.join(os.path.dirname(__file__), "dacapo-9.12-bach.jar")

JAVA_VMS = OrderedDict()
JAVA_VMS["hotspot"] = "$JAVA_HOME/bin/java"

if os.uname()[0].startswith("Linux"):
    JVMCI_JAVA_HOME = find_internal_jvmci_java_home('%s/work/graal-jvmci-8/' % WARMUP_DIR)
    JAVA_VMS["graal"] = "%s/work/mx/mx --java-home=%s -p %s/work/graal/ vm -XX:+UseJVMCICompiler" % (WARMUP_DIR, JVMCI_JAVA_HOME, WARMUP_DIR)
if os.getenv("SSH_DO_COPY"):
    SSH_KEY = "~kruninit/warmup_experiment/id_rsa"
    SSH_HOST = "bencher2.soft-dev.org"
    SSH_USER = "vext01"
    SSH_COPY_DIR = "research/krun_results"
    SSH_DO_COPY = True
else:
    SSH_DO_COPY = False

def main():
    platform = detect_platform(None, Config())
    platform.check_preliminaries()
    platform.sanity_checks()
    for jvm_name, jvm_cmd in JAVA_VMS.items():
        csvp = "dacapo.%s.results" % jvm_name
        with open(csvp, 'wb') as csvf:
            sys.stdout.write("%s:\n" % jvm_name)
            writer = csv.writer(csvf)
            writer.writerow(['processnum', 'benchmark'] + range(ITERATIONS))
            for benchmark in WORKING_BENCHS:
                if jvm_name == "graal" and benchmark in DISABLE_ON_GRAAL:
                    continue
                if sys.platform.startswith("openbsd") and benchmark in DISABLE_ON_OPENBSD:
                    continue
                sys.stdout.write("  %s:" % benchmark)
                for process in range(PROCESSES):
                    sys.stdout.write(" %s" % str(process))
                    sys.stdout.flush()
                    # Flush the CSV writing, and then give the OS some time
                    # to write stuff out to disk before running the next process
                    # execution.
                    csvf.flush()
                    os.fsync(csvf.fileno())
                    if SSH_DO_COPY:
                        os.system("cat %s | ssh -o 'BatchMode yes' -i %s %s@%s 'cat > %s/%s.dacapo.%s.results'" \
                                  % (csvp, SSH_KEY, SSH_USER, SSH_HOST, \
                                     SSH_COPY_DIR, socket.gethostname(), jvm_name))
                    time.sleep(3)

                    stdout, stderr, rc = run_shell_cmd_bench(
                        "%s -jar %s %s -n %s" % (jvm_cmd, JAR, benchmark,
                                                 ITERATIONS + 1), platform, failure_fatal=False)
                    if rc != 0:
                        sys.stderr.write("\nWARNING: process exec crashed\n")
                        sys.stderr.write("stdout:\n")
                        sys.stderr.write(stdout + "\n")
                        sys.stderr.write("\nstderr:\n")
                        sys.stderr.write(stderr + "\n")
                        sys.stderr.flush()
                        writer.writerow([process, benchmark, "crash"])
                        continue
                    output = []
                    for line in stderr.splitlines():
                        if not line.startswith("====="):
                            continue
                        if "completed warmup" not in line:
                            continue
                        assert benchmark in line
                        line = line.split()
                        index = line.index("in")
                        assert line[index + 2] == "nsec"
                        output.append(str(Decimal(line[index + 1]) / 1000000000))
                    assert len(output) == ITERATIONS
                    writer.writerow([process, benchmark] + output)
                sys.stdout.write("\n")
    platform.save_power()


if __name__ == '__main__':
    main()
