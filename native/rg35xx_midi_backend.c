#include "rg35xx_midi_backend.h"
#include <string.h>

/*
 * Media Engine adapter state. Actual TML/TSF object construction/rendering is
 * supplied by the proven core audio worker through the hook functions below.
 * This keeps Platform 1.0 from embedding a second synthesizer implementation.
 */
struct rg35xx_midi_ctx {
    uint32_t player_id;
    int active;
    int paused;
    uint64_t media_time_us;
};

static struct rg35xx_midi_ctx ctx[RG35XX_MEDIA_MAX_MIDI_CTX];
static rg35xx_midi_end_cb end_callback;

/* Existing core integration hooks. Return nonzero on success. */
int rg35xx_tsf_open_memory(int slot, const uint8_t *midi, size_t size);
int rg35xx_tsf_start(int slot, int volume, int loop_count, uint64_t media_time_us);
int rg35xx_tsf_pause(int slot);
int rg35xx_tsf_stop(int slot);
int rg35xx_tsf_seek(int slot, uint64_t media_time_us);
void rg35xx_tsf_close(int slot);
size_t rg35xx_tsf_mix_slot(int slot, int32_t *accum, size_t frames);
int rg35xx_tsf_slot_finished(int slot);
uint64_t rg35xx_tsf_slot_time_us(int slot);

static int find_slot(uint32_t id)
{
    int i;
    for(i = 0; i < RG35XX_MEDIA_MAX_MIDI_CTX; ++i)
        if(ctx[i].player_id == id) return i;
    return -1;
}

static int alloc_slot(uint32_t id)
{
    int i = find_slot(id);
    if(i >= 0) return i;
    for(i = 0; i < RG35XX_MEDIA_MAX_MIDI_CTX; ++i)
        if(ctx[i].player_id == 0) { ctx[i].player_id = id; return i; }
    /* deterministic SFX replacement; slot 0 is retained as primary/BGM */
    i = RG35XX_MEDIA_MAX_MIDI_CTX > 1 ? 1 : 0;
    rg35xx_tsf_close(i);
    memset(&ctx[i], 0, sizeof(ctx[i]));
    ctx[i].player_id = id;
    return i;
}

void rg35xx_midi_backend_init(rg35xx_midi_end_cb cb)
{
    memset(ctx, 0, sizeof(ctx));
    end_callback = cb;
}

void rg35xx_midi_backend_reset(void)
{
    int i;
    for(i = 0; i < RG35XX_MEDIA_MAX_MIDI_CTX; ++i) {
        if(ctx[i].player_id) rg35xx_tsf_close(i);
        memset(&ctx[i], 0, sizeof(ctx[i]));
    }
}

int rg35xx_midi_backend_play(struct rg35xx_media_entry *e)
{
    int slot;
    if(!e || e->type != RG35XX_MEDIA_MIDI || !e->blob || !e->blob_size) return 0;
    slot = alloc_slot(e->player_id);
    if(!ctx[slot].active && !ctx[slot].paused) {
        if(!rg35xx_tsf_open_memory(slot, e->blob, e->blob_size)) return 0;
    }
    if(!rg35xx_tsf_start(slot, e->volume, e->loop_count, e->media_time_us)) return 0;
    ctx[slot].active = 1;
    ctx[slot].paused = 0;
    e->state = RG35XX_MEDIA_PLAYING;
    return 1;
}

int rg35xx_midi_backend_pause(uint32_t id)
{
    int slot = find_slot(id);
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    if(slot < 0 || !e || !rg35xx_tsf_pause(slot)) return 0;
    ctx[slot].paused = 1;
    ctx[slot].active = 0;
    ctx[slot].media_time_us = rg35xx_tsf_slot_time_us(slot);
    e->media_time_us = ctx[slot].media_time_us;
    e->state = RG35XX_MEDIA_PAUSED;
    return 1;
}

int rg35xx_midi_backend_stop(uint32_t id)
{
    int slot = find_slot(id);
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    if(slot < 0 || !e || !rg35xx_tsf_stop(slot)) return 0;
    ctx[slot].active = 0;
    ctx[slot].paused = 0;
    ctx[slot].media_time_us = 0;
    e->media_time_us = 0;
    e->state = RG35XX_MEDIA_STOPPED;
    return 1;
}

int rg35xx_midi_backend_seek(uint32_t id, uint64_t us)
{
    int slot = find_slot(id);
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    if(!e) return 0;
    if(slot >= 0 && !rg35xx_tsf_seek(slot, us)) return 0;
    e->media_time_us = us;
    if(slot >= 0) ctx[slot].media_time_us = us;
    return 1;
}

void rg35xx_midi_backend_release(uint32_t id)
{
    int slot = find_slot(id);
    if(slot < 0) return;
    rg35xx_tsf_close(slot);
    memset(&ctx[slot], 0, sizeof(ctx[slot]));
}

size_t rg35xx_midi_backend_mix(int32_t *accum, size_t frames)
{
    int i;
    if(!accum || !frames) return 0;
    for(i = 0; i < RG35XX_MEDIA_MAX_MIDI_CTX; ++i) {
        struct rg35xx_media_entry *e;
        uint32_t id;
        if(!ctx[i].player_id || !ctx[i].active || ctx[i].paused) continue;
        id = ctx[i].player_id;
        rg35xx_tsf_mix_slot(i, accum, frames);
        e = rg35xx_media_cache_find(id);
        if(e) e->media_time_us = rg35xx_tsf_slot_time_us(i);
        if(rg35xx_tsf_slot_finished(i)) {
            ctx[i].active = 0;
            if(e) { e->state = RG35XX_MEDIA_STOPPED; e->media_time_us = 0; }
            if(end_callback) end_callback(id);
        }
    }
    return frames;
}
