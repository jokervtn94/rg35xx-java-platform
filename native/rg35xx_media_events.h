#ifndef RG35XX_MEDIA_EVENTS_H
#define RG35XX_MEDIA_EVENTS_H

#include <stdint.h>

/* Must stay wire-compatible with RG35XXMediaRegistry / patch 0014. */
#define RG35XX_MEDIA_EVENT_END_OF_MEDIA 1
#define RG35XX_MEDIA_EVENT_LOOPED       2

typedef void (*rg35xx_media_event_cb)(int event_type,
                                      uint32_t player_id,
                                      uint64_t media_time_us);

#endif
