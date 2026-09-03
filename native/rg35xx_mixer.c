#include "rg35xx_mixer.h"
#include "rg35xx_midi_backend.h"
#include <string.h>

/* Tasklog: RGJ-B3-006 / RGJ-B3-STAB-001 / RGJ-RC1-010D */
#define RG35XX_MIXER_CHUNK_FRAMES 1024u
#define RG35XX_PCM_PHASE_BITS 15u
#define RG35XX_PCM_PHASE_ONE  (1u << RG35XX_PCM_PHASE_BITS)
#define RG35XX_PCM_PHASE_MASK (RG35XX_PCM_PHASE_ONE - 1u)

struct pcm_voice {
    uint32_t player_id;
    uint64_t source_pos_q15;
    uint32_t source_step_q15;
    int active;
    int paused;
};

static struct pcm_voice pcm_voices[RG35XX_MEDIA_MAX_PCM_VOICES];
static rg35xx_media_end_cb media_end_callback;
/* Static reusable accumulator: no malloc/calloc/free in audio render hot path. */
static int32_t mix_accum[RG35XX_MIXER_CHUNK_FRAMES * 2u];

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

static int32_t lerp_s16(int16_t a, int16_t b, uint32_t frac_q15)
{
    int32_t delta = (int32_t)b - (int32_t)a;
    return (int32_t)a + ((delta * (int32_t)frac_q15) >> RG35XX_PCM_PHASE_BITS);
}

static uint32_t pcm_step_q15(int sample_rate)
{
    uint64_t scaled;
    uint32_t step;
    if(sample_rate <= 0) return 0;
    scaled = (uint64_t)(uint32_t)sample_rate * (uint64_t)RG35XX_PCM_PHASE_ONE;
    step = (uint32_t)((scaled + (RG35XX_MIXER_RATE / 2)) / RG35XX_MIXER_RATE);
    return step ? step : 1u;
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
    memset(mix_accum, 0, sizeof(mix_accum));
    media_end_callback = end_cb;
    rg35xx_midi_backend_init(end_cb);
}

void rg35xx_mixer_reset(void)
{
    memset(pcm_voices, 0, sizeof(pcm_voices));
    memset(mix_accum, 0, sizeof(mix_accum));
    rg35xx_midi_backend_reset();
}

int rg35xx_mixer_play(uint32_t id)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    struct pcm_voice *v;
    if(!e) return 0;
    if(e->type == RG35XX_MEDIA_MIDI) return rg35xx_midi_backend_play(e);
    if(e->type != RG35XX_MEDIA_PCM16 || e->sample_rate <= 0 || e->channels < 1 || e->channels > 2) return 0;
    v = alloc_voice(id);
    if(!v) return 0;
    v->source_step_q15 = pcm_step_q15(e->sample_rate);
    if(!v->source_step_q15) return 0;
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
    v = find_voice(id); if(v) { v->active = 0; v->paused = 0; v->source_pos_q15 = 0; }
    e->state = RG35XX_MEDIA_STOPPED; e->media_time_us = 0; return 1;
}

int rg35xx_mixer_seek(uint32_t id, uint64_t us)
{
    struct rg35xx_media_entry *e = rg35xx_media_cache_find(id);
    struct pcm_voice *v;
    uint64_t frame;
    uint64_t total_frames;
    size_t bpf;
    if(!e) return 0;
    if(e->type == RG35XX_MEDIA_MIDI) return rg35xx_midi_backend_seek(id, us);
    if(e->type != RG35XX_MEDIA_PCM16 || e->sample_rate <= 0 || e->channels < 1 || e->channels > 2) return 0;
    v = alloc_voice(id);
    if(!v) return 0;
    bpf = (size_t)e->channels * 2u;
    total_frames = (uint64_t)(e->blob_size / bpf);
    frame = (us * (uint64_t)e->sample_rate) / UINT64_C(1000000);
    if(frame > total_frames) frame = total_frames;
    v->source_pos_q15 = frame << RG35XX_PCM_PHASE_BITS;
    v->source_step_q15 = pcm_step_q15(e->sample_rate);
    e->media_time_us = ((frame * UINT64_C(1000000)) / (uint64_t)e->sample_rate);
    return 1;
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
        v->source_pos_q15 = 0; return;
    }
    v->active = 0; e->state = RG35XX_MEDIA_STOPPED; e->media_time_us = 0;
    if(media_end_callback) media_end_callback(e->player_id);
}

static void render_chunk(int16_t *out, size_t frames)
{
    size_t f;
    int vi;
    memset(mix_accum, 0, frames * 2u * sizeof(int32_t));
    rg35xx_midi_backend_mix(mix_accum, frames);

    for(f = 0; f < frames; ++f) {
        int32_t left = mix_accum[f * 2], right = mix_accum[f * 2 + 1];
        for(vi = 0; vi < RG35XX_MEDIA_MAX_PCM_VOICES; ++vi) {
            struct pcm_voice *v = &pcm_voices[vi];
            struct rg35xx_media_entry *e;
            size_t bpf;
            uint64_t total_frames;
            uint64_t src_frame;
            uint64_t next_frame;
            uint32_t frac;
            const uint8_t *p0;
            const uint8_t *p1;
            int16_t l0, r0, l1, r1;
            int32_t l, r;

            if(!v->active || v->paused || !v->player_id) continue;
            e = rg35xx_media_cache_find(v->player_id);
            if(!e || e->type != RG35XX_MEDIA_PCM16 || e->sample_rate <= 0 || e->channels < 1 || e->channels > 2) continue;

            bpf = (size_t)e->channels * 2u;
            total_frames = (uint64_t)(e->blob_size / bpf);
            if(total_frames == 0) { pcm_finish_or_loop(e, v); continue; }

            src_frame = v->source_pos_q15 >> RG35XX_PCM_PHASE_BITS;
            if(src_frame >= total_frames) {
                pcm_finish_or_loop(e, v);
                if(!v->active) continue;
                src_frame = 0;
            }

            frac = (uint32_t)(v->source_pos_q15 & RG35XX_PCM_PHASE_MASK);
            next_frame = src_frame + 1u;
            if(next_frame >= total_frames) next_frame = src_frame;

            p0 = e->blob + (size_t)(src_frame * bpf);
            p1 = e->blob + (size_t)(next_frame * bpf);
            if(e->channels == 1) {
                l0 = r0 = read_s16le(p0);
                l1 = r1 = read_s16le(p1);
            } else {
                l0 = read_s16le(p0); r0 = read_s16le(p0 + 2);
                l1 = read_s16le(p1); r1 = read_s16le(p1 + 2);
            }

            if(frac == 0 || next_frame == src_frame) {
                l = l0; r = r0;
            } else {
                l = lerp_s16(l0, l1, frac);
                r = lerp_s16(r0, r1, frac);
            }

            v->source_pos_q15 += (uint64_t)v->source_step_q15;
            left += (l * e->volume) / 100;
            right += (r * e->volume) / 100;
            e->media_time_us = (((v->source_pos_q15 >> RG35XX_PCM_PHASE_BITS) * UINT64_C(1000000)) / (uint64_t)e->sample_rate);
        }
        out[f * 2] = clamp16(left); out[f * 2 + 1] = clamp16(right);
    }
}

size_t rg35xx_mixer_render(int16_t *out, size_t frames)
{
    size_t done = 0;
    if(!out || frames == 0) return 0;
    while(done < frames) {
        size_t chunk = frames - done;
        if(chunk > RG35XX_MIXER_CHUNK_FRAMES) chunk = RG35XX_MIXER_CHUNK_FRAMES;
        render_chunk(out + done * 2u, chunk);
        done += chunk;
    }
    return frames;
}
