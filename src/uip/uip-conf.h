#ifndef __UIP_CONF_H__
#define __UIP_CONF_H__

#include <stdint.h> // for uint8_t etc.

typedef uint8_t  u8_t;
typedef uint16_t u16_t;
typedef uint32_t u32_t;

/* uip_stats_t is used for statistics tracking (just use int or struct) */
typedef unsigned long uip_stats_t;

#define UIP_APPCALL() // empty

/* Define application state structure if required */
typedef struct {
  // put your TCP app state here
  int dummy; // placeholder
} uip_tcp_appstate_t;

#define UIP_CONF_LOGGING 1
#define UIP_CONF_TCP 1
#define UIP_CONF_UDP 0
#define UIP_CONF_MAX_CONNECTIONS 5
#define UIP_CONF_MAX_LISTENPORTS 5
#define UIP_CONF_BUFFER_SIZE 512
#define UIP_CONF_BYTE_ORDER UIP_LITTLE_ENDIAN

#endif /* __UIP_CONF_H__ */
