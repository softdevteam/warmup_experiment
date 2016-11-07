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

void emit_dummy_per_core_data(char *, int);

void
emit_dummy_per_core_data(char *name, int num_per_core_data)
{
    int i;

    printf("\"%s\": [", name);
    for (i = 0; i < num_per_core_data; i++) {
        printf("[0, 0]");
        if (i < num_per_core_data - 1) {
            printf(", ");
        }
    }
    printf("], ");
}

int
main(int argc, char **argv)
{
    int result, num_per_core_data;

    if (argc != 2) {
        printf("usage: ./outer_startup_runner_c <inner-runner>\n");
        exit(EXIT_FAILURE);
    }

    krun_init();
    num_per_core_data = krun_get_num_cores();

    printf("{");
    emit_dummy_per_core_data("core_cycle_counts", num_per_core_data);
    emit_dummy_per_core_data("aperf_counts", num_per_core_data);
    emit_dummy_per_core_data("mperf_counts", num_per_core_data);
    printf("\"wallclock_times\" : [ %f, ", krun_clock_gettime_monotonic());
    fflush(stdout);

    result = execv(argv[1], argv + 1);
    if (result) {
        perror("Starting subprocess failed:");
        exit(EXIT_FAILURE);
    }
    return (EXIT_SUCCESS);
}
