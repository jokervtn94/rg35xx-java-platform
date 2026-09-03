#ifndef RG35XX_MEDIA_CACHE_H
#define RG35XX_MEDIA_CACHE_H

#include <stdint.h>
#include <stddef.h>

/*
 * Bounded native media registry contract.
 * Allocation/deallocation is owned by the native audio worker, not retro_run.
 * Tasklog: RGJ-B3-005 / RGJ-B3-006
 */
#define RG35XX_MEDIA_MAX_PLAYERS    32
#define RG35XX_MEDIA_MAX_PCM_VOICES 8
#define RG35XX_MEDIA_MAX_MIDI_CTX   2

enum rg35xx_media_type {
    RG35XX_MEDIA_NONE = 0,
    RG35XX_MEDIA_MIDI = 1,
    RG35XX_MEDIA_PCM16 = 2,
    RG35XX_MEDIA_TONE = 3
};

enum rg35xx_media_state {
    RG35XX_MEDIA_EMPTY = 0,
    RG35XX_MEDIA_REGISTERED,
    RG35XX_MEDIA_PLAYING,
    RG35XX_MEDIA_PAUSED,
    RG35XX_MEDIA_STOPPED
};

struct rg35xx_media_entry {
    uint32_t player_id;
    uint8_t type;
    uint8_t state;
    int volume;
    int loop_count;
    uint64_t media_time_us;
    uint8_t *blob;
    size_t blob_size;
    int sample_rate;
    int channels;
};

#endif
