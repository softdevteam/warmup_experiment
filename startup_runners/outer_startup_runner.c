/*
 * Iterations runner for C benchmarks.
 *
 * Code style here is KNF, but with 4 spaces instead of tabs.
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdint.h>
#include <unistd.h>

#include "libkruntime.h"

#define BENCH_FUNC_NAME "run_iter"

int
main(int argc, char **argv)
{
    double start_time = -1;
    int result;

    /* silence gcc */
    argc = argc;
    argv = argv;

    krun_measure(1);
    start_time = krun_get_wallclock(1);
    fprintf(stdout, "[[%f,\n", start_time);
    fflush(stdout);
    result = execv(argv[1], argv + 1);
    if (result) {
        perror("Starting subprocess failed:");
    }
    return (EXIT_SUCCESS);
}
