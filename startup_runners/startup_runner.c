/*
 * Iterations runner for C benchmarks.
 *
 * Code style here is KNF, but with 4 spaces instead of tabs.
 */

/* To correctly expose asprintf() on Linux */
#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <dlfcn.h>
#include <err.h>
#include <stdint.h>
#include <unistd.h>

#include "libkruntime.h"

#define BENCH_FUNC_NAME "run_iter"

int
main(void)
{
    double start_time = -1;
    start_time = krun_clock_gettime_monotonic();
    fprintf(stdout, "%f ] }\n", start_time);
    return (EXIT_SUCCESS);
}
