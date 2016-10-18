/*
 * Iterations runner for C benchmarks.
 *
 * Code style here is KNF, but with 4 spaces instead of tabs.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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
    char fake_datum[] = "[0, 0], ";
    char end_datum[] = "[0, 0] ";
    int datum_size = (int)strlen(fake_datum);
    krun_init();
    char* fake_data = malloc(1);

    if (krun_get_num_cores() > 1) {
        memcpy(fake_data, fake_datum, datum_size);
    }
    if (krun_get_num_cores() > 2) {
        for(int i=0; i < krun_get_num_cores() - 2; i++) {
            memcpy(fake_data + datum_size * (i + 1), fake_datum, datum_size);
        }
    }
    memcpy(fake_data + datum_size * (krun_get_num_cores() - 1), end_datum, datum_size - 1);
    fake_data[datum_size * krun_get_num_cores() - 1] = '\0';

    /* silence gcc */
    argc = argc;
    argv = argv;

    start_time = krun_clock_gettime_monotonic();
    fprintf(stdout, "{ \"core_cycle_counts\": [ %s ],", fake_data);
    fprintf(stdout, " \"mperf_counts\" : [ %s ],", fake_data);
    fprintf(stdout, " \"aperf_counts\" : [ %s ],", fake_data);
    fprintf(stdout, " \"wallclock_times\" : [ %f, ", start_time);
    fflush(stdout);
    result = execv(argv[1], argv + 1);
    if (result) {
        perror("Starting subprocess failed:");
    }
    free(fake_data);
    return (EXIT_SUCCESS);
}
