#!/usr/bin/env python2.7
"""
usage:
    XXX
"""

import sys
import os
import numpy as np
from statsmodels.tsa.stattools import acf
from statsmodels.regression.linear_model import OLS
from statsmodels.stats.stattools import durbin_watson
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__)))))
from warmup.krun_results import parse_krun_file_with_changepoints
from warmup.summary_statistics import collect_summary_statistics
from warmup.plotting import zoom_y_min, zoom_y_max

CORR_THRESHOLD = 1.1, 2.9
CORR_PLOT_DIR = "correlated_plots"
NOCORR_PLOT_DIR = "uncorrelated_plots"

# debug bits
DEBUG = False
if os.environ.get("CORR_DEBUG"):
    DEBUG = True
N_LAGS = 40


def main(data_dct, classifier):
    total_num_steady = 0
    total_num_corr = 0
    total_num_pexecs = 0

    summary_stats = collect_summary_statistics(data_dct, classifier['delta'],
                                               classifier['steady'])
    # XXX print per-machine summaries
    # XXX check all segs in steady state
    for machine, machine_data in data_dct.iteritems():
        for key in machine_data['wallclock_times'].keys():
            bench, vm, _ = key.split(":")
            key_classifications = data_dct[machine]['classifications'][key]
            key_cpts = data_dct[machine]['changepoints'][key]
            executions = data_dct[machine]['wallclock_times'][key]

            if not executions:
                print("warning: skipping %s:%s: no executions" %
                      (machine, key))
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
            num_steady, num_corr = \
                analyse(executions, key, steady_idxs, machine, key_cpts)
            total_num_steady += num_steady
            total_num_corr += num_corr
            total_num_pexecs += len(executions)

    print("\n" + (72 * "-"))
    print("Summary:")
    print("  Absolute correlation threshold: %s" % str(CORR_THRESHOLD))
    print("  Total num pexecs: %s" % total_num_pexecs)
    print("  Total num steady pexecs: %s" % total_num_steady)
    print("  Total num steady pexecs showing correlation: %s" % total_num_corr)
    if total_num_steady:
        percent = float(total_num_corr) / total_num_steady * 100
    else:
        percent = "N/A"
    print("  Percent of steady correlated pexecs: %s" % percent)
    print(72 * "-")


def dw(data_np):
    """Compute the Durbin-Watson statistic for 1-dimensional numpy array"""

    # The only "dependent" variable is only the "intercept", since we
    # are correlating the data with itself.
    ones_np = np.ones(len(data_np))

    # Perform ordinary least squares (OLS) to get residuals
    ols_res = OLS(data_np, ones_np).fit()

    # Return the Durbin-Watson value
    dw_res = durbin_watson(ols_res.resid)
    assert 0 <= dw_res <= 4
    return dw_res


def analyse(data, key, steady_idxs, machine, cpts):
    """Look for the correlations for the pexecs of a single key.

    Returns a pair containing the number of pexecs that were stable, and the
    number of stable pexecs for which correlation was detected.
    """

    num_corr_pexecs = 0
    num_steady_pexecs = 0

    for pexec_idx, execu in enumerate(data):
        steady_iter = steady_idxs[pexec_idx]
        if len(cpts[pexec_idx]) > 0:
            last_change = cpts[pexec_idx][-1]
        else:
            last_change = 0
        pexec_corr = False

        if steady_iter is not None:
            num_steady_pexecs += 1

            # The independent variable is the steady iterations
            steady_iters_np = np.array(execu[last_change:])
            dw_res = dw(steady_iters_np)

            if dw_res < CORR_THRESHOLD[0] or dw_res > CORR_THRESHOLD[1]:
                if DEBUG:
                    print("[!] %s, pexec=%s, steady_iter=%s, dw=%.3f" %
                          (key, pexec_idx, steady_iter + 1, dw_res))
                num_corr_pexecs += 1
                pexec_corr = True

            if DEBUG:
                if pexec_corr:
                    direc = CORR_PLOT_DIR
                else:
                    direc = NOCORR_PLOT_DIR
                plot_steady(key, pexec_idx, machine, steady_iter, dw_res,
                            steady_iters_np, direc)
    return num_steady_pexecs, num_corr_pexecs


def plot_steady(key, pexec_idx, machine, steady_iter, corr, steady_iters_np,
                direc):
    slices = len(steady_iters_np), 200, 100, 50, 25
    f, axarr = plt.subplots(len(slices) + 1, sharex=False)
    plt.tight_layout()
    title = "%s <= %s <= %s" % (CORR_THRESHOLD[0], corr, CORR_THRESHOLD[1])
    f.suptitle(title)

    def subplot(sub_idx, data, start_idx):
        ymin = zoom_y_min(data, [], 0)
        ymax = zoom_y_max(data, [], 0)
        axarr[sub_idx].set_ylim(ymin, ymax)
        xs = xrange(start_idx + 1, start_idx + len(data) + 1)
        axarr[sub_idx].plot(xs, data)

    for sp_idx, end in enumerate(slices):
        subplot(sp_idx, steady_iters_np[:end], steady_iter)

    acf_coefs = acf(np.array(steady_iters_np), nlags=N_LAGS + 1, unbiased=True)
    axarr[len(slices)].bar(xrange(len(acf_coefs)), acf_coefs)

    filename = "%s_%s_%s.pdf" % (machine, key.replace(":", "_"), pexec_idx)
    path = os.path.join(direc, filename)
    gcf = matplotlib.pyplot.gcf()
    gcf.set_size_inches(10, 10)
    print("saving out: %s" % path)
    f.savefig(path)

    plt.clf()
    plt.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: find_corrs file1, [... fileN]")
        sys.exit(1)

    if DEBUG:
        for direc in CORR_PLOT_DIR, NOCORR_PLOT_DIR:
            if os.path.exists(direc):
                print("%s already exists" % direc)
                sys.exit(1)
            os.mkdir(direc)

    classifier, data_dcts = parse_krun_file_with_changepoints(sys.argv[1:])
    main(data_dcts, classifier)
