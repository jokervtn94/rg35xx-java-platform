#include "rg35xx_mixer.h"
#include "rg35xx_midi_backend.h"
#include <stdlib.h>
#include <string.h>

/* Tasklog: RGJ-B3-006 */
struct pcm_voice {
    uint32_t player_id;
    size_t byte_pos;
    int active;
    int paused;
};

static struct pcm_voice pcm_voices[RG35XX_MEDIA_MAX_PCM_VOICES];
static rg35xx_media_end_cb media_end_callback;

static int16_t read_s16le(const uint8_t *p)
{
    return (int16_t)((uint16_t)p[0] | ((uint16_t)p[1] << 8));
}

static int16_t clamp16(int32_t v)
{
    if(v > 32767) return 32767;
    if(v < -32768) return -32768;
    return (int16_t)v;
}

static struct pcm_voice *find_voice(uint32_t id)
{
    int i;
    for(i = 0; i < RG35XX_MEDIA_MAX_PCM_VOICES; ++i)
        if(pcm_voices[i].player_id == id) return &pcm_voices[i];
    return NULL;
}

static struct pcm_voice *alloc_voice(uint32_t id)
{
    int i;
    struct pcm_voice *v = find_voice(id);
    if(v) return v;
    for(i = 0; i < RG35XX_MEDIA_MAX_PCM_VOICES; ++i)
        if(pcm_voices[i].player_id == 0) { pcm_voices[i].player_id = id; return &pcm_voices[i]; }
    memset(&pcm_voices[0], 0, sizeof(pcm_voices[0]));
    pcm_voices[0].player_id = id;
    return &pcm_voices[0];
}

void rg35xx_mixer_init(rg35xx_media_end_cb end_cb)
{
    memset(pcm_voices, 0, sizeof(pcm_voices));
    media_end_callback = end_cb;
    rg35xx_midi_backend_init(end_cb);
}

void rg35xx_mixer_reset(void)
{
    memset(pcm_voices, 0, sizeof(pcm_voices));
    rg35xx_midi_backend_reset();
}

int rg35xx_mixer_play(uint32_t id)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    struct pcm_voice *v;
    if(!e) return 0;
    if(e->type == RG35XX_MEDIA_MIDI) return rg35xx_midi_backend_play(e);
    if(e->type != RG35XX_MEDIA_PCM16) return 0;
    v = alloc_voice(id);
    if(!v) return 0;
    v->active = 1; v->paused = 0; e->state = RG35XX_MEDIA_PLAYING;
    return 1;
}

int rg35xx_mixer_pause(uint32_t id)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    struct pcm_voice *v;
    if(!e) return 0;
    if(e->type == RG35XX_MEDIA_MIDI) return rg35xx_midi_backend_pause(id);
    v = find_voice(id); if(!v) return 0;
    v->paused = 1; e->state = RG35XX_MEDIA_PAUSED; return 1;
}

int rg35xx_mixer_stop(uint32_t id)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    struct pcm_voice *v;
    if(!e) return 0;
    if(e->type == RG35XX_MEDIA_MIDI) return rg35xx_midi_backend_stop(id);
    v = find_voice(id); if(v) { v->active = 0; v->paused = 0; v->byte_pos = 0; }
    e->state = RG35XX_MEDIA_STOPPED; e->media_time_us = 0; return 1;
}

int rg35xx_mixer_seek(uint32_t id, uint64_t us)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    struct pcm_voice *v;
    uint64_t frame;
    size_t bpf;
    if(!e) return 0;
    if(e->type == RG35XX_MEDIA_MIDI) return rg35xx_midi_backend_seek(id, us);
    if(e->type != RG35XX_MEDIA_PCM16 || e->sample_rate <= 0) return 0;
    v = alloc_voice(id); bpf = (size_t)e->channels * 2u;
    frame = (us * (uint64_t)e->sample_rate) / UINT64_C(1000000);
    v->byte_pos = (size_t)(frame * bpf); if(v->byte_pos > e->blob_size) v->byte_pos = e->blob_size;
    e->media_time_us = us; return 1;
}

int rg35xx_mixer_set_volume(uint32_t id, int level)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    if(!e) return 0; if(level < 0) level = 0; if(level > 100) level = 100; e->volume = level; return 1;
}

int rg35xx_mixer_set_loop_count(uint32_t id, int count)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    if(!e || count == 0) return 0; e->loop_count = count; return 1;
}

void rg35xx_mixer_release(uint32_t id)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    struct pcm_voice *v = find_voice(id);
    if(v) memset(v, 0, sizeof(*v));
    if(e && e->type == RG35XX_MEDIA_MIDI) rg35xx_midi_backend_release(id);
}

static void pcm_finish_or_loop(struct rg35xx_media_entry *e, struct pcm_voice *v)
{
    if(e->loop_count == -1 || e->loop_count > 1) {
        if(e->loop_count > 1) e->loop_count--;
        v->byte_pos = 0; return;
    }
    v->active = 0; e->state = RG35XX_MEDIA_STOPPED; e->media_time_us = 0;
    if(media_end_callback) media_end_callback(e->player_id);
}

size_t rg35xx_mixer_render(int16_t *out, size_t frames)
{
    size_t f;
    int vi;
    int32_t *accum;
    if(!out || frames == 0) return 0;
    accum = (int32_t *)calloc(frames * 2u, sizeof(int32_t));
    if(!accum) { memset(out, 0, frames * 2u * sizeof(int16_t)); return 0; }

    /* TML/TSF adds stereo samples into the same accumulator as PCM voices. */
    rg35xx_midi_backend_mix(accum, frames);

    for(f = 0; f < frames; ++f) {
        int32_t left = accum[f * 2], right = accum[f * 2 + 1];
        for(vi = 0; vi < RG35XX_MEDIA_MAX_PCM_VOICES; ++vi) {
            struct pcm_voice *v = &pcm_voices[vi];
            struct rg35xx_media_entry *e;
            size_t bpf;
            int32_t l, r;
            if(!v->active || v->paused || !v->player_id) continue;
            e = rg35xx_media_cache_find(v->player_id);
            if(!e || e->type != RG35XX_MEDIA_PCM16) continue;
            bpf = (size_t)e->channels * 2u;
            if(v->byte_pos + bpf > e->blob_size) { pcm_finish_or_loop(e, v); if(!v->active) continue; }
            if(e->channels == 1) l = r = read_s16le(e->blob + v->byte_pos);
            else { l = read_s16le(e->blob + v->byte_pos); r = read_s16le(e->blob + v->byte_pos + 2); }
            v->byte_pos += bpf;
            left += (l * e->volume) / 100; right += (r * e->volume) / 100;
            e->media_time_us = ((uint64_t)(v->byte_pos / bpf) * UINT64_C(1000000)) / (uint64_t)e->sample_rate;
        }
        out[f * 2] = clamp16(left); out[f * 2 + 1] = clamp16(right);
    }
    free(accum);
    return frames;
}
