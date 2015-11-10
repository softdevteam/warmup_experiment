/*
 * Iterations runner for C benchmarks.
 *
 * Code style here is KNF, but with 4 spaces instead of tabs.
 */

/* To correctly expose asprintf() on Linux */
#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

#define BENCH_FUNC_NAME "run_iter"

/* from libkruntime */
double clock_gettime_monotonic();

int
main(int argc, char **argv)
{
    double start_time = -1;
    int result;

    start_time = clock_gettime_monotonic();
    fprintf(stdout, "[%f,\n", start_time);
    fflush(stdout);
    result = execv(argv[1], argv + 1);
    if (result) {
        perror("Starting subprocess failed:");
    }
    return (EXIT_SUCCESS);
}
