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
import scipy
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ABS_CORR_THRESHOLD = 0.5  # flag correlation coefficients above this value
N_LAGS = 40           # No. of lags to analyse for correlations
PLOT_DIR = "correlated_plots"


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
    print("  Absolute correlation threshold: %s" % ABS_CORR_THRESHOLD)
    print("  Number of lags: %s" % N_LAGS)
    print("  Total num pexecs: %s" % total_num_pexecs)
    print("  Total num steady pexecs: %s" % total_num_steady)
    print("  Total num steady pexecs showing correlation: %s" % total_num_corr)

    if total_num_steady:
        percent = float(total_num_corr) / total_num_steady * 100
    else:
        percent = "N/A"
    print("  Percent of steady correlated pexecs: %s" % percent)


def analyse(data, key, steady_idxs, machine):
    """Examine correlations for the pexecs for a single key

    Returns a pair containing the number of pexecs that were stable, and the
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
        corrs = []

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
                abs_coef = abs(coef)
                if abs_coef > ABS_CORR_THRESHOLD:
                    corrs.append((lag_num, coef))
                    if not hdr_done:
                        print("\n%s, pexec %s, steady_iter %s" % \
                              (key, pnum, steady_iter + 1))
                        hdr_done = True
                    print("  pexec=%s, lag=%s, corr=%s" % (pnum, lag_num, coef))
                    pexec_corr = True
            if pexec_corr:
                plot_steady(key, pnum, machine, steady_iter, corrs, steady_iters_np)
                num_corr_pexecs += 1
    return num_steady_pexecs, num_corr_pexecs, num_normal_pexecs


def plot_steady(key, pnum, machine, steady_iter, corrs, steady_iters_np):
    xs = xrange(steady_iter + 1, steady_iter + len(steady_iters_np) + 1)

    corrs_elems = []
    for lag, val in corrs:
        title = str(corrs[:3])
        corrs_elems.append("%s=%.02f" % (lag, val))
        if len(corrs) == 3:
            break
    title = " ".join(corrs_elems)

    f, axarr = plt.subplots(5, sharex=False)
    plt.tight_layout()
    f.suptitle(title)
    axarr[0].plot(xs, steady_iters_np, color="red")

    from warmup.plotting import zoom_y_min, zoom_y_max
    def subplot(sub_idx, data, start_idx):
        ymin = zoom_y_min(data, [], 0)
        ymax = zoom_y_max(data, [], 0)
        axarr[sub_idx].set_ylim(ymin, ymax)
        xs = xrange(start_idx + 1, start_idx + len(data) + 1)
        axarr[sub_idx].plot(xs, data)

    slices = 200, 100, 50, 25
    for sp_idx, end in enumerate(slices):
        subplot(sp_idx + 1, steady_iters_np[:end], steady_iter)

    filename = "%s_%s_%s.pdf" % (machine, key.replace(":", "_"), pnum)
    path = os.path.join(PLOT_DIR, filename)
    gcf = matplotlib.pyplot.gcf()
    gcf.set_size_inches(5, 8)
    f.savefig(path)

    plt.clf()
    plt.close()

def usage():
    print(__doc__)
    sys.exit(1) # XXX


if __name__ == "__main__":
    if os.path.exists(PLOT_DIR):
        print("%s already exists" % PLOT_DIR)
        sys.exit(1)
    os.mkdir(PLOT_DIR)

    # XXX check existence of keys
    # XXX check args
    classifier, data_dcts = parse_krun_file_with_changepoints(sys.argv[1:])
    main(data_dcts, classifier)
