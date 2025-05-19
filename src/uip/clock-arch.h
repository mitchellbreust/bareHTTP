#ifndef CLOCK_ARCH_H
#define CLOCK_ARCH_H

#include <stdint.h>

// You can change clock_time_t to match your platform
typedef uint32_t clock_time_t;
#define CLOCK_CONF_SECOND 1000  // 1000 ticks per second

#endif
