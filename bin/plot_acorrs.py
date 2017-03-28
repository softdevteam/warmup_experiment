#!/usr/bin/env python2.7
"""
usage:
    XXX
"""

import sys
import os
import numpy
from statsmodels.tsa.stattools import acf
from terminalplot import plot

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__)))))
from warmup.krun_results import read_krun_results_file

CORR_THRESHOLD = 0.5  # flag correlation coefficients above this value
N_LAGS = 40           # No. of lags to analyse for correlations


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
    keys = sorted(data_dct["wallclock_times"].keys())
    total_num_steady = 0
    total_num_corr = 0
    total_num_pexecs = 0

    for key in keys:
        steady_idxs = get_steady_indexes(data_dct, key)
        executions = data_dct["wallclock_times"][key]
        assert len(steady_idxs) == len(executions)
        num_steady, num_corr = \
            analyse_correlations(executions, key, steady_idxs)
        total_num_steady += num_steady
        total_num_corr += num_corr
        total_num_pexecs += len(executions)

    print("Summary:")
    print("  Correlation threshold: %s" % CORR_THRESHOLD)
    print("  Number of lags: %s" % N_LAGS)
    print("  Total num pexecs: %s" % total_num_pexecs)
    print("  Total num steady pexecs: %s" % total_num_steady)
    print("  Total num steady pexecs showing correlation: %s" % total_num_corr)

    if total_num_steady:
        percent = float(total_num_corr) / total_num_steady * 100
    else:
        percent = "N/A"
    print("  Percent of steady correlated pexecs: %s" % percent)


def analyse_correlations(data, key, steady_idxs):
    """Examine correlations for the pexecs for a single key

    Returns a pair conatining the number of pexecs that were stable, and the
    number of stable pexecs for which one or more lag is correlated above the
    threshold.
    """

    n_execs = len(data)
    num_corr_pexecs = 0
    num_steady_pexecs = 0

    for pnum, execu in enumerate(data):
        steady_iter = steady_idxs[pnum]
        pexec_corr = False

        if steady_iter:
            num_steady_pexecs += 1
            coeffs = acf(numpy.array(execu[steady_iter:]), unbiased=True,
                     nlags=N_LAGS)
            n_coeffs = len(coeffs)
            hdr_done = False
            for lag_num, coef in enumerate(coeffs):
                if lag_num == 0:
                    assert coef == 1.0
                    continue
                if abs(coef) > CORR_THRESHOLD:
                    if not hdr_done:
                        print("")
                        print(78 * "-")
                        print("%s, pexec %s, steady_iter %s" % \
                              (key, pnum, steady_iter + 1))
                        print(78 * "-")
                        plot(xrange(n_coeffs), list(coeffs), rows=10,
                             columns=n_coeffs)
                        print(78 * "-")
                        print("Details:")
                        hdr_done = True
                    print("  pexec=%s, lag=%s, corr=%s" % (pnum, lag_num, coef))
                    pexec_corr = True
            if pexec_corr:
                num_corr_pexecs += 1
    return num_steady_pexecs, num_corr_pexecs


def usage():
    print(__doc__)
    sys.exit(1) # XXX


if __name__ == "__main__":
    try:
        json_file = sys.argv[1]
    except IndexError:
        usage()

    data_dct = read_krun_results_file(json_file)
    main(data_dct)
