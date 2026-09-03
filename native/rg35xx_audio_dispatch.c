#include "rg35xx_audio_protocol.h"
#include "rg35xx_media_cache.h"
#include <stdint.h>
#include <stddef.h>

/* Tasklog: RGJ-B3-004 / RGJ-B3-005 */
static uint64_t rg35xx_audio_u64le(const uint8_t *p)
{
    uint64_t v = 0;
    int i;
    for(i = 7; i >= 0; --i) v = (v << 8) | p[i];
    return v;
}

int rg35xx_audio_dispatch(const struct rg35xx_audio_header *h,
                          const uint8_t *payload)
{
    struct rg35xx_media_entry *e;
    if(!h) return 0;
    if(h->payload_size && !payload) return 0;

    switch(h->opcode)
    {
        case RG35XX_AUDIO_REGISTER_MIDI:
            return rg35xx_media_cache_register(h->player_id, RG35XX_MEDIA_MIDI,
                                               payload, h->payload_size, 0, 0);

        case RG35XX_AUDIO_REGISTER_PCM16:
            if(h->payload_size < 8) return 0;
            return rg35xx_media_cache_register(h->player_id, RG35XX_MEDIA_PCM16,
                                               payload + 8, h->payload_size - 8,
                                               (int)rg35xx_audio_u32le(payload),
                                               (int)rg35xx_audio_u32le(payload + 4));

        case RG35XX_AUDIO_RELEASE:
            return rg35xx_media_cache_release(h->player_id);

        case RG35XX_AUDIO_RESET:
            rg35xx_media_cache_reset();
            return 1;

        default:
            break;
    }

    e = rg35xx_media_cache_find(h->player_id);
    if(!e) return 0;

    switch(h->opcode)
    {
        case RG35XX_AUDIO_PLAY:
            if(h->payload_size != 0) return 0;
            e->state = RG35XX_MEDIA_PLAYING;
            return 1;
        case RG35XX_AUDIO_PAUSE:
            if(h->payload_size != 0) return 0;
            e->state = RG35XX_MEDIA_PAUSED;
            return 1;
        case RG35XX_AUDIO_STOP:
            if(h->payload_size != 0) return 0;
            e->state = RG35XX_MEDIA_STOPPED;
            e->media_time_us = 0;
            return 1;
        case RG35XX_AUDIO_SEEK_US:
            if(h->payload_size != 8) return 0;
            e->media_time_us = rg35xx_audio_u64le(payload);
            return 1;
        case RG35XX_AUDIO_SET_VOLUME:
            if(h->payload_size != 4) return 0;
            e->volume = (int)rg35xx_audio_u32le(payload);
            if(e->volume < 0) e->volume = 0;
            if(e->volume > 100) e->volume = 100;
            return 1;
        case RG35XX_AUDIO_SET_LOOP_COUNT:
            if(h->payload_size != 4) return 0;
            e->loop_count = (int32_t)rg35xx_audio_u32le(payload);
            return e->loop_count != 0;
        default:
            return 0;
    }
}
