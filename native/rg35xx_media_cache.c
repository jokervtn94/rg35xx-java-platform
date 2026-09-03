#include "rg35xx_media_cache.h"
#include <stdlib.h>
#include <string.h>

/* Tasklog: RGJ-B3-005 */
static struct rg35xx_media_entry rg35xx_media_entries[RG35XX_MEDIA_MAX_PLAYERS];

static void rg35xx_media_clear_entry(struct rg35xx_media_entry *e)
{
    if(!e) return;
    if(e->blob) free(e->blob);
    memset(e, 0, sizeof(*e));
}

void rg35xx_media_cache_reset(void)
{
    int i;
    for(i = 0; i < RG35XX_MEDIA_MAX_PLAYERS; ++i)
        rg35xx_media_clear_entry(&rg35xx_media_entries[i]);
}

struct rg35xx_media_entry *rg35xx_media_cache_find(uint32_t player_id)
{
    int i;
    if(player_id == 0) return NULL;
    for(i = 0; i < RG35XX_MEDIA_MAX_PLAYERS; ++i)
        if(rg35xx_media_entries[i].player_id == player_id)
            return &rg35xx_media_entries[i];
    return NULL;
}

static struct rg35xx_media_entry *rg35xx_media_cache_slot(uint32_t player_id)
{
    int i;
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(player_id);
    if(e) return e;
    for(i = 0; i < RG35XX_MEDIA_MAX_PLAYERS; ++i)
        if(rg35xx_media_entries[i].player_id == 0)
            return &rg35xx_media_entries[i];
    return NULL;
}

int rg35xx_media_cache_register(uint32_t player_id, uint8_t type,
                                const uint8_t *blob, size_t blob_size,
                                int sample_rate, int channels)
{
    struct rg35xx_media_entry *e;
    uint8_t *copy;
    if(player_id == 0 || !blob || blob_size == 0) return 0;
    if(type != RG35XX_MEDIA_MIDI && type != RG35XX_MEDIA_PCM16) return 0;
    if(type == RG35XX_MEDIA_PCM16 && (sample_rate <= 0 || channels < 1 || channels > 2)) return 0;

    e = rg35xx_media_cache_slot(player_id);
    if(!e) return 0;
    copy = (uint8_t *)malloc(blob_size);
    if(!copy) return 0;
    memcpy(copy, blob, blob_size);

    rg35xx_media_clear_entry(e);
    e->player_id = player_id;
    e->type = type;
    e->state = RG35XX_MEDIA_REGISTERED;
    e->volume = 100;
    e->loop_count = 1;
    e->blob = copy;
    e->blob_size = blob_size;
    e->sample_rate = sample_rate;
    e->channels = channels;
    return 1;
}

int rg35xx_media_cache_release(uint32_t player_id)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(player_id);
    if(!e) return 0;
    rg35xx_media_clear_entry(e);
    return 1;
}
