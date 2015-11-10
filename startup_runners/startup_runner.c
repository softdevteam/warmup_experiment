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
#include <unistd.h>

#define BENCH_FUNC_NAME "run_iter"

/* from libkruntime */
double clock_gettime_monotonic();

int
main(int argc, char **argv)
{
    double    start_time = -1;

    start_time = clock_gettime_monotonic();
    fprintf(stdout, "%f]\n", start_time);
    return (EXIT_SUCCESS);
}
