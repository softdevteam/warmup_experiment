#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int
run_iter(int param)
{
    sleep(param);
    return (EXIT_SUCCESS);
}
