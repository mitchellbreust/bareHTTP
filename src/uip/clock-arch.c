// clock-arch.c
#include <time.h>
#include "clock-arch.h"

clock_time_t clock_time(void) {
    return (clock_time_t)(clock() / (CLOCKS_PER_SEC / 1000)); // returns time in ms
}
