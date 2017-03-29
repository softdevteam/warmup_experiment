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
from warmup.krun_results import parse_krun_file_with_changepoints

CORR_THRESHOLD = 0.5  # flag correlation coefficients above this value
N_LAGS = 40           # No. of lags to analyse for correlations

KURT_THRESHOLD = 1.0
SKEW_THRESHOLD = 1.0


# XXX put in warmup lib
def get_steady_segment(segment_means, segment_vars, delta):
    """Gets the steady segment and iteration number taking into account
    "equivalent" consecutive segments.

    Arguments:
        segment_means: list of segment means
        segment_vars: list of segment variances
        delta: tolerance for segment equivalence

    Returns:
        A pair:

        * The index of the first steady segment or "equivalent" consecutive
          earlier segment.

        * The number of steady segments.
    """

    num_segments = len(segment_means)

    last_segment_mean = segment_means[-1]
    last_segment_var = segment_vars[-1]
    lower_bound = min(last_segment_mean - last_segment_var,
                      last_segment_mean - delta)
    upper_bound = max(last_segment_mean + last_segment_var,
                      last_segment_mean + delta)

    first_steady_segment = num_segments - 1
    print("init steady seg: %s" % first_steady_segment)
    num_steady_segments = 1
    for index in xrange(num_segments - 2, -1, -1):
        current_segment_mean = segment_means[index]
        current_segment_var = segment_vars[index]
        if (current_segment_mean + current_segment_var >= lower_bound and
                current_segment_mean - current_segment_var <= upper_bound):
            first_steady_segment -= 1
            num_steady_segments += 1
        else:
            break
    return first_steady_segment, num_steady_segments


# XXX put in warmup lib?
def get_steady_indices(data_dct, key, delta):
    ret = []
    for pexec_idx, cls in enumerate(data_dct["classifications"][key]):
        if cls != "no steady state":
            cps = data_dct["changepoints"][key][pexec_idx]
            if not cps:
                assert cls == "flat"
                ret.append(0)
            else:
                segment_means = data_dct['changepoint_means'][key][pexec_idx]
                segment_vars = data_dct['changepoint_vars'][key][pexec_idx]
                steady_seg_idx, _ = get_steady_segment(segment_means, segment_vars, delta)
                # minus one, because seg_n starts at cpt_{n-1}
                ret.append(cps[steady_seg_idx - 1])
        else:
            ret.append(None)
    return ret


def main(data_dct, delta):
    keys = sorted(data_dct["wallclock_times"].keys())
    total_num_steady = 0
    total_num_corr = 0
    total_num_pexecs = 0
    total_num_normal = 0

    for key in keys:
        steady_idxs = get_steady_indices(data_dct, key, delta)
        executions = data_dct["wallclock_times"][key]
        assert len(steady_idxs) == len(executions)
        num_steady, num_corr, num_normal = \
            analyse(executions, key, steady_idxs)
        total_num_steady += num_steady
        total_num_corr += num_corr
        total_num_normal += num_normal
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


    print("  Skew threshold: +/-%s" % SKEW_THRESHOLD)
    print("  Kurtosis threshold: +/-%s" % KURT_THRESHOLD)
    print("  Total num steady pexecs approximately normal: %s" % total_num_normal)
    if total_num_normal:
        percent = float(total_num_normal) / total_num_steady * 100
    else:
        percent = "N/A"
    print("  Percent of steady pexecs also normal: %s" % percent)


def analyse(data, key, steady_idxs):
    """Examine correlations for the pexecs for a single key

    Returns a pair conatining the number of pexecs that were stable, and the
    number of stable pexecs for which one or more lag is correlated above the
    threshold.
    """

    n_execs = len(data)
    num_corr_pexecs = 0
    num_steady_pexecs = 0
    num_normal_pexecs = 0

    for pnum, execu in enumerate(data):
        steady_iter = steady_idxs[pnum]
        pexec_corr = False

        if steady_iter:
            num_steady_pexecs += 1
            steady_seg = execu[steady_iter:]
            steady_seg_np = numpy.array(steady_seg)

            # Correlation analysis
            coeffs = acf(steady_seg_np, unbiased=True, nlags=N_LAGS)
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
                    #print("  pexec=%s, lag=%s, corr=%s" % (pnum, lag_num, coef))
                    pexec_corr = True
            if pexec_corr:
                num_corr_pexecs += 1

            # Normality Analysis
            # XXX prints all for now
            if len(steady_seg) < 8:
                continue  # test fails with this few samples

            from scipy.stats.mstats import normaltest
            import math
            n_bins = 30
            _, pval = normaltest(steady_seg_np)
            hist = numpy.histogram(steady_seg_np, bins=n_bins)

            print(n_bins * "-")
            plot(xrange(n_bins), list(hist[0]), rows=10, columns=n_bins)
            print(n_bins * "-")

            # p < 0.01 rejects the null hypothesis, meaning that the value
            # isn't likely from the normal distribution.
            print("pval=%s" % pval)
            if pval >= 0.05:
                # Likely normally distributed
                num_normal_pexecs += 1

    return num_steady_pexecs, num_corr_pexecs, num_normal_pexecs


def usage():
    print(__doc__)
    sys.exit(1) # XXX


if __name__ == "__main__":
    try:
        json_file = sys.argv[1]
    except IndexError:
        usage()

    # XXX check existence of keys
    # This script deals with only one file at a time
    classifier, data_dcts = parse_krun_file_with_changepoints([json_file])
    assert len(data_dcts) == 1
    data_dct = data_dcts[data_dcts.keys()[0]]

    main(data_dct, classifier['delta'])
