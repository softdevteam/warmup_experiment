import csv
import sys
import os
from krun.platform import detect_platform
from krun.util import run_shell_cmd_bench

ITERATIONS = 2000
PROCESSES = 10

# broken: batik, eclipse, tomcat
WORKING_BENCHS = ['avrora', 'fop', 'h2', 'jython', 'luindex', 'lusearch',
                  'pmd', 'sunflow', 'tradebeans', 'tradesoap', 'xalan']

JAR = os.path.join(os.path.dirname(__file__), "dacapo-9.12-bach.jar")

def main():
    platform = detect_platform(None, None)
    writer = csv.writer(sys.stdout)
    writer.writerow(['processnum', 'benchmark'] + range(ITERATIONS))
    for benchmark in WORKING_BENCHS:
        for process in range(PROCESSES):
            stdout, stderr, rc = run_shell_cmd_bench(
                    "$JAVA_HOME/bin/java -jar %s %s -n %s" % (
                        JAR, benchmark, ITERATIONS + 1),
                    platform)
            output = []
            for line in stderr.splitlines():
                if not line.startswith("====="):
                    continue
                if "completed warmup" not in line:
                    continue
                assert benchmark in line
                line = line.split()
                index = line.index("in")
                assert line[index + 2] == "msec"
                output.append(float(line[index + 1]))
            assert len(output) == ITERATIONS
            writer.writerow([process, benchmark] + output)


if __name__ == '__main__':
    main()
