#!/usr/bin/env python2.7
"""
usage:
    chart_results.py <json results file>
"""

import bz2
import sys
import json
import os
import matplotlib
matplotlib.use("TkAgg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from warmup.krun_results import read_krun_results_file

# Set figure size for plots
#plt.figure(tight_layout=True)

# Set font size
font = {
    'family' : 'sans',
    'weight' : 'regular',
    'size'   : '12',
}
matplotlib.rc('font', **font)


# put in warmup lib if we decide to use this XXX
def get_steady_indexes(data_dct, key):
    ret = []
    for idx, cls in enumerate(data_dct["classifications"][key]):
        if cls != "no steady state":
            cps = data_dct["changepoints"][key][idx]
            if not cps:
                ret.append(0)
            else:
                ret.append(cps[-1])
        else:
            ret.append(None)
    return ret

def main(data_dct):
    # Iterate over keys in the json file drawing some graphs
    keys = sorted(data_dct["wallclock_times"].keys())
    n = 4 # XXX hack see below.
    with PdfPages("out.pdf") as pdf:
        for key in keys:
            sys.stdout.write(key)
            steady_idxs = get_steady_indexes(data_dct, key)
            executions = data_dct["wallclock_times"][key]
            assert len(steady_idxs) == len(executions)
            draw_acrs(pdf, executions, key, steady_idxs)
            print("")
            # stop after 4 XXX
            n -= 1
            if n < 0:
                break


def draw_acrs(pdf, data, key, steady_idxs):
    n_execs = len(data)
    n_rows, n_cols = n_execs / 2, 2
    fig = plt.figure(figsize=(20, 45))

    for num, execu in enumerate(data):
        mean = float(sum(execu)) / len(execu)
        steady_iter = steady_idxs[num]
        vals = [v - mean for v in execu][steady_iter:]

        p = fig.add_subplot(n_rows, n_cols, num + 1)
        p.set_title("%s, Proc. Exec. #%s" % (key, num + 1))
        p.set_xlabel("Lag")
        p.set_ylabel("Correlation")
        if steady_iter is not None:
            p.acorr(vals)
        sys.stdout.write(".")
        sys.stdout.flush()
    pdf.savefig()


if __name__ == "__main__":
    try:
        json_file = sys.argv[1]
    except IndexError:
        usage()

    data_dct = read_krun_results_file(json_file)
    plt.close() # avoid extra blank window
    main(data_dct)
