#! /usr/bin/env python

import csv, os, sys, time
from decimal import Decimal
from krun.platform import detect_platform
from krun.util import run_shell_cmd_bench
from krun.vm_defs import find_internal_jvmci_java_home

WARMUP_DIR = os.path.realpath(os.path.dirname(os.path.dirname(__file__)))

ITERATIONS = 2000
PROCESSES = 30

# broken: batik, eclipse, tomcat
WORKING_BENCHS = ['avrora', 'fop', 'h2', 'jython', 'luindex', 'lusearch',
                  'pmd', 'sunflow', 'tradebeans', 'xalan']

JAR = os.path.join(os.path.dirname(__file__), "dacapo-9.12-bach.jar")

JAVA_VMS = {
    "hotspot" : "$JAVA_HOME/bin/java"
}
if os.uname()[0].startswith("Linux"):
    JVMCI_JAVA_HOME = find_internal_jvmci_java_home('%s/work/graal-jvmci-8/' % WARMUP_DIR)
    JAVA_VMS["graal"] = "%s/work/mx/mx --java-home=%s -p %s/work/graal/ vm -XX:+UseJVMCICompiler" % (WARMUP_DIR, JVMCI_JAVA_HOME, WARMUP_DIR)

def main():
    platform = detect_platform(None, None)
    for jvm_name, jvm_cmd in JAVA_VMS.items():
        with open("dacapo.%s.results" % jvm_name, 'wb') as csvf:
            sys.stdout.write("%s:\n" % jvm_name)
            writer = csv.writer(csvf)
            writer.writerow(['processnum', 'benchmark'] + range(ITERATIONS))
            for benchmark in WORKING_BENCHS:
                sys.stdout.write("  %s:" % benchmark)
                for process in range(PROCESSES):
                    sys.stdout.write(" %s" % str(process))
                    sys.stdout.flush()
                    # Flush the CSV writing, and then give the OS some time
                    # to write stuff out to disk before running the next process
                    # execution.
                    csvf.flush()
                    os.fsync(csvf.fileno())
                    time.sleep(3)

                    stdout, stderr, rc = run_shell_cmd_bench(
                        "%s -jar %s %s -n %s" % (jvm_cmd, JAR, benchmark,
                                                 ITERATIONS + 1), platform)
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


if __name__ == '__main__':
    main()
