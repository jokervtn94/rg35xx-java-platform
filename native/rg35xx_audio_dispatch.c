#include "rg35xx_audio_dispatch.h"
#include "rg35xx_media_cache.h"
#include "rg35xx_mixer.h"
#include <stdint.h>
#include <stddef.h>

/* Tasklog: RGJ-B3-004 / RGJ-B3-005 / RGJ-B3-006 / RGJ-RC1-010G */
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
        case RG35XX_AUDIO_PLAY:
            return h->payload_size == 0 && rg35xx_mixer_play(h->player_id);
        case RG35XX_AUDIO_PAUSE:
            return h->payload_size == 0 && rg35xx_mixer_pause(h->player_id);
        case RG35XX_AUDIO_STOP:
            return h->payload_size == 0 && rg35xx_mixer_stop(h->player_id);
        case RG35XX_AUDIO_SEEK_US:
            return h->payload_size == 8 && rg35xx_mixer_seek(h->player_id, rg35xx_audio_u64le(payload));
        case RG35XX_AUDIO_SET_VOLUME:
            return h->payload_size == 4 && rg35xx_mixer_set_volume(h->player_id, (int)rg35xx_audio_u32le(payload));
        case RG35XX_AUDIO_SET_LOOP_COUNT:
            return h->payload_size == 4 && rg35xx_mixer_set_loop_count(h->player_id, (int32_t)rg35xx_audio_u32le(payload));
        case RG35XX_AUDIO_RELEASE:
            if(h->payload_size != 0) return 0;
            rg35xx_mixer_release(h->player_id);
            return rg35xx_media_cache_release(h->player_id);
        case RG35XX_AUDIO_RESET:
            if(h->payload_size != 0) return 0;
            rg35xx_mixer_reset();
            rg35xx_media_cache_reset();
            return 1;
        default:
            return 0;
    }
}
