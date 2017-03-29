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
from warmup.summary_statistics import collect_summary_statistics
from scipy.stats.mstats import normaltest

CORR_THRESHOLD = 0.5  # flag correlation coefficients above this value
N_LAGS = 40           # No. of lags to analyse for correlations
NORMAL_P_THRESHOLD = 0.01   # upper bound on p-value to reject null hypothesis


def main(data_dct, classifier):
    total_num_steady = 0
    total_num_corr = 0
    total_num_pexecs = 0
    total_num_normal = 0

    summary_stats = collect_summary_statistics(data_dct, classifier['delta'],
                                               classifier['steady'])
    for machine, machine_data in data_dct.iteritems():
        for key in machine_data['wallclock_times'].keys():
            bench, vm, _ = key.split(":")
            key_classifications = data_dct[machine]['classifications'][key]
            executions = data_dct[machine]['wallclock_times'][key]

            if not executions:
                print("warning: skipping %s:%s: no executions" % (machine, key))
                continue  # skipped benchmark

            # find summary stats for the machine/vm/benchmark
            vm_summary_stats = summary_stats[machine][vm]
            for bench_summary in vm_summary_stats:
                if bench_summary["benchmark_name"] == bench:
                    break
            else:
                assert False  # unreachable
            raw_steady_idxs = bench_summary['steady_state_iteration_list']

            # Build a list of steady indices (or None if it didn't stabilize)
            steady_idxs = []
            for pexec_idx, classif in enumerate(key_classifications):
                if classif != "no steady state":
                    steady_idxs.append(raw_steady_idxs[pexec_idx])
                else:
                    steady_idxs.append(None)

            assert len(steady_idxs) == len(executions)
            num_steady, num_corr, num_normal = \
                analyse(executions, key, steady_idxs, machine)
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

    print("  Normality p-value threshold: %s" % NORMAL_P_THRESHOLD)
    print("  Total num steady pexecs approximately normal: %s" % total_num_normal)
    if total_num_normal:
        percent = float(total_num_normal) / total_num_steady * 100
    else:
        percent = "N/A"
    print("  Percent of steady pexecs approximately normal: %s" % percent)


def analyse(data, key, steady_idxs, machine):
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
            steady_iters = execu[steady_iter:]
            steady_iters_np = numpy.array(steady_iters)

            # Correlation analysis
            coeffs = acf(steady_iters_np, unbiased=True, nlags=N_LAGS)
            n_coeffs = len(coeffs)
            hdr_done = False
            for lag_num, coef in enumerate(coeffs):
                if lag_num == 0:
                    assert coef == 1.0
                    continue
                if abs(coef) > CORR_THRESHOLD:
                    if not hdr_done:
                        # XXX commented until we decide if we want to keep
                        #print("")
                        #print(78 * "-")
                        #print("%s, pexec %s, steady_iter %s" % \
                        #      (key, pnum, steady_iter + 1))
                        #print(78 * "-")
                        #plot(xrange(n_coeffs), list(coeffs), rows=10,
                        #     columns=n_coeffs)
                        #print(78 * "-")
                        #print("Details:")
                        hdr_done = True
                    #print("  pexec=%s, lag=%s, corr=%s" % (pnum, lag_num, coef))
                    pexec_corr = True
            if pexec_corr:
                num_corr_pexecs += 1

            # Normality Analysis
            # XXX prints all for now

            # cut off bottom and top 25% to "zoom in" on histogram
            n_bins = 30
            chop = int(float(n_bins/4))
            n_bins -= chop * 2
            _, pval = normaltest(steady_iters_np)
            hist = numpy.histogram(sorted(steady_iters_np)[chop:-chop], bins=n_bins)

            print("machine=%s, key=%s, pexec=%s, steady_iter=%s" % (machine, key, pnum, steady_iter))
            print(n_bins * "-")
            plot(xrange(n_bins), list(hist[0]), rows=10, columns=n_bins)
            print(n_bins * "-")

            # p < NORMAL_P_THRESHOLD rejects the null hypothesis, meaning that
            # the value isn't likely from the normal distribution.
            print("pval=%s" % pval)
            if pval >= NORMAL_P_THRESHOLD:
                # Likely normally distributed
                print("^^^ IS NORMAL")
                num_normal_pexecs += 1
            else:
                print("^^^ IS NOT NORMAL")
            print("\n")

    return num_steady_pexecs, num_corr_pexecs, num_normal_pexecs


def usage():
    print(__doc__)
    sys.exit(1) # XXX


if __name__ == "__main__":
    # XXX check existence of keys
    # XXX check args
    classifier, data_dcts = parse_krun_file_with_changepoints(sys.argv[1:])
    main(data_dcts, classifier)
