/*
 * Copyright (c) 2017 King's College London
 * created by the Software Development Team <http://soft-dev.org/>
 *
 * The Universal Permissive License (UPL), Version 1.0
 *
 * Subject to the condition set forth below, permission is hereby granted to
 * any person obtaining a copy of this software, associated documentation
 * and/or data (collectively the "Software"), free of charge and under any and
 * all copyright rights in the Software, and any and all patent rights owned or
 * freely licensable by each licensor hereunder covering either (i) the
 * unmodified Software as contributed to or provided by such licensor, or (ii)
 * the Larger Works (as defined below), to deal in both
 *
 * (a) the Software, and
 * (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
 * one is included with the Software (each a "Larger Work" to which the
 * Software is contributed by such licensors),
 *
 * without restriction, including without limitation the rights to copy, create
 * derivative works of, display, perform, and distribute the Software and make,
 * use, sell, offer for sale, import, export, have made, and have sold the
 * Software and the Larger Work(s), and to sublicense the foregoing rights on
 * either these or other terms.
 *
 * This license is subject to the following condition: The above copyright
 * notice and either this complete permission notice or at a minimum a
 * reference to the UPL must be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

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

    /*
     * This startup runner needs one argument. Under normal operation, krun
     * passes some other flags, which can safely be ignored.
     */
    if (argc < 2) {
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
