#!/usr/bin/env python2.7

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

CORR_THRESHOLD = 1.6, 3.4       # threshold for DW analysis
MIN_CORR_SEG_LEN = 50           # shortest seg to apply DW to

# debug bits
DEBUG = False
if os.environ.get("CORR_DEBUG"):
    DEBUG = True
N_LAGS = 40
CORR_PLOT_DIR = "correlated_plots"
NOCORR_PLOT_DIR = "uncorrelated_plots"
SMALL_VARIANCE = 0.0001


def get_steady_segs(cpts, variances, steady_idx, pexec_len):
    """Get a list of steady segments.

    Each steady segment is a tuple (start, end), inclusive of start and
    exlusive of end. Start and end are list indicies.
    """

    assert len(variances) == len(cpts) + 1
    segs = []
    start = 0
    num_cpts_in_steady_state = 0  # used in sanity checks only
    for seg_idx, end in enumerate(cpts):
        if start < steady_idx:
            pass  # not yet steady
        else:
            num_cpts_in_steady_state += 1
            variance = variances[seg_idx]
            segs.append((start, end, variance))
        start = end

    # And add the final segment
    segs.append((start, pexec_len, variances[-1]))

    # Sanity checks
    assert len(segs) >= 1, 'should be at least one steady segment'
    assert len(segs) == num_cpts_in_steady_state + 1, \
        'should be 1 more seg than changepoint'
    assert segs[-1][1] == pexec_len, 'last seg should end with pexec'
    assert segs[0][0] == steady_idx, 'first seg should start at steady_idx'
    num_segs = len(segs)
    for seg_idx in xrange(len(segs)):
        if seg_idx < num_segs - 1:
            assert segs[seg_idx][1] == segs[seg_idx + 1][0], \
                'end seg idx should be start of next'
    return segs


def main(data_dct, classifier):
    total_num_steady = 0
    total_num_corr = 0
    total_num_pexecs = 0
    total_num_steady_segs = 0
    total_num_small_var_steady_segs = 0

    summary_stats = collect_summary_statistics(data_dct, classifier['delta'],
                                               classifier['steady'])
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
            steady_segs = []
            for pexec_idx, classif in enumerate(key_classifications):
                if classif != "no steady state":
                    # pexec does reach a steady state
                    pexec_len = len(machine_data["wallclock_times"][key][pexec_idx])
                    pexec_cpts = machine_data["changepoints"][key][pexec_idx]
                    pexec_steady_iter = raw_steady_idxs[pexec_idx]
                    pexec_vars = machine_data['changepoint_vars'][key][pexec_idx]
                    steady_segs.append(get_steady_segs(pexec_cpts, pexec_vars, pexec_steady_iter, pexec_len))
                else:
                    # pexec does *not* reach a steady state
                    steady_segs.append(None)

            assert len(steady_segs) == len(executions)
            num_steady, num_corr, num_steady_segs, num_small_var_steady_segs = analyse(executions, key, steady_segs, machine)
            total_num_steady += num_steady
            total_num_corr += num_corr
            total_num_pexecs += len(executions)
            total_num_steady_segs += num_steady_segs
            total_num_small_var_steady_segs += num_small_var_steady_segs

    print("\n" + (72 * "-"))
    print("Summary for %s:" % machine)
    print("  Absolute correlation threshold: %s" % str(CORR_THRESHOLD))
    print("  Total num pexecs: %s" % total_num_pexecs)
    print("  Total num steady pexecs: %s" % total_num_steady)
    print("  Total num steady pexecs showing correlation: %s" % total_num_corr)
    print("  Total steady segs: %s" % total_num_steady_segs)
    print("  Total steady segs with variance < %s: %s" % (SMALL_VARIANCE, total_num_small_var_steady_segs))
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


def analyse(data, key, steady_segs, machine):
    """Look for the correlations for the pexecs of a single key.

    Returns a pair containing the number of pexecs that were stable, and the
    number of stable pexecs for which correlation was detected.
    """

    num_corr_pexecs = 0
    num_steady_pexecs = 0
    num_steady_segs = 0
    num_small_var_steady_segs = 0

    for pexec_idx, execu in enumerate(data):
        pexec_steady_segs = steady_segs[pexec_idx]

        if pexec_steady_segs is None:
            continue  # pexec did not reach a steady state
        num_steady_pexecs += 1

        # Do the correlation analysis on each seg in isolation.
        #
        # If one seg is correlated, then we say the steady segment is too.
        one_seg_correlated = False
        num_steady_segs += len(pexec_steady_segs)
        for seg_idx, seg in enumerate(pexec_steady_segs):
            seg_start, seg_end, seg_var = seg

            if seg_var < SMALL_VARIANCE:
                num_small_var_steady_segs += 1

            # The independent variable is the steady iterations
            seg_iters_np = np.array(execu[seg_start:seg_end])

            # filter out "too short" segments
            seg_len = len(seg_iters_np)
            if seg_len < MIN_CORR_SEG_LEN:
                print("segment too short: %s" % seg_len)
                continue
            elif seg_var < SMALL_VARIANCE:
                print("segment variance too low: %s" % seg_var)
                continue

            # Perform the Durbin-Watson test on this segment and flag the
            # pexec if it fails the test.
            dw_res = dw(seg_iters_np)
            if dw_res < CORR_THRESHOLD[0] or dw_res > CORR_THRESHOLD[1]:
                if DEBUG:
                    print("key=%s, pexec_idx=%s, steady_seg_idx=%s, dw=%.3f" %
                          (key, pexec_idx, seg_idx, dw_res))
                one_seg_correlated = True
                direc = CORR_PLOT_DIR
            else:
                direc = NOCORR_PLOT_DIR

            if DEBUG:
                plot_steady(key, pexec_idx, machine, seg, seg_idx, dw_res,
                            seg_iters_np, direc)
        if one_seg_correlated:
            num_corr_pexecs += 1
    return num_steady_pexecs, num_corr_pexecs, num_steady_segs, num_small_var_steady_segs


def plot_steady(key, pexec_idx, machine, seg, steady_seg_idx, dw_res,
                seg_iters_np, direc):
    seg_len = len(seg_iters_np)
    zoom_slices = seg_len, seg_len / 2, seg_len / 4, 50, 25

    f, axarr = plt.subplots(len(zoom_slices) + 1, sharex=False)
    plt.tight_layout()
    title = "%s <= %s <= %s" % (CORR_THRESHOLD[0], dw_res, CORR_THRESHOLD[1])
    f.suptitle(title)

    def subplot(sub_idx, data, start_idx):
        ymin = zoom_y_min(data, [], 0)
        ymax = zoom_y_max(data, [], 0)
        axarr[sub_idx].set_ylim(ymin, ymax)
        xs = xrange(start_idx + 1, start_idx + len(data) + 1)
        axarr[sub_idx].plot(xs, data)

    for sp_idx, end in enumerate(zoom_slices):
        subplot(sp_idx, seg_iters_np[:end], seg[0])

    acf_coefs = acf(np.array(seg_iters_np), nlags=N_LAGS + 1, unbiased=True)
    axarr[len(zoom_slices)].bar(xrange(len(acf_coefs)), acf_coefs)

    filename = "%s_%s_%s_steadyseg%s.pdf" % (machine, key.replace(":", "_"),
                                             pexec_idx, steady_seg_idx)
    path = os.path.join(direc, filename)
    gcf = matplotlib.pyplot.gcf()
    gcf.set_size_inches(10, 10)
    print("saving out: %s" % path)
    f.savefig(path)

    plt.clf()
    plt.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: find_corrs annotated_results_file")
        sys.exit(1)

    if DEBUG:
        for direc in CORR_PLOT_DIR, NOCORR_PLOT_DIR:
            if os.path.exists(direc):
                print("%s already exists" % direc)
                sys.exit(1)
            os.mkdir(direc)

    classifier, data_dcts = parse_krun_file_with_changepoints(sys.argv[1:])
    assert len(data_dcts) == 1
    main(data_dcts, classifier)
