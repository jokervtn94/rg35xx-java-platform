#ifndef RG35XX_MEDIA_EVENT_QUEUE_H
#define RG35XX_MEDIA_EVENT_QUEUE_H

#include <stdint.h>

/*
 * Bounded native media-event handoff between the audio/mixer callback context
 * and the existing libretro control-writer context.
 *
 * Events are rare (LOOPED / END_OF_MEDIA), so a mutex is acceptable here and
 * avoids lock-free memory-ordering assumptions on the ARMv5 target. No heap
 * allocation is performed and the mutex is never taken for normal audio frames.
 */
#define RG35XX_MEDIA_EVENT_QUEUE_CAPACITY 32

struct rg35xx_media_event_record {
    uint8_t event_type;
    uint32_t player_id;
    uint64_t media_time_us;
};

void rg35xx_media_event_queue_reset(void);
void rg35xx_media_event_queue_push(uint8_t event_type,
                                   uint32_t player_id,
                                   uint64_t media_time_us);
int rg35xx_media_event_queue_pop(struct rg35xx_media_event_record *out);

#endif
