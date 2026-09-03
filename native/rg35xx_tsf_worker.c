#include "rg35xx_tsf_worker.h"
#include "rg35xx_midi_backend.h"
#include "tsf.h"
#include "tml.h"
#include <limits.h>
#include <string.h>

/* RGJ-RC1-010F replacement worker.
 * TML/TSF allocation is confined to init/open/setup paths. The render path
 * uses fixed storage and the two slots already owned by rg35xx_midi_backend.
 */
#define RG35XX_TSF_SLOTS RG35XX_MEDIA_MAX_MIDI_CTX
#define RG35XX_TSF_RATE 44100u
#define RG35XX_TSF_CHANNELS 16
#define RG35XX_TSF_MAX_VOICES 16
#define RG35XX_TSF_RENDER_FRAMES 1024u

struct rg35xx_tsf_slot {
    tml_message *first;
    tml_message *next;
    tsf *synth;
    uint64_t time_us;
    uint64_t duration_us;
    int opened;
    int playing;
    int paused;
    int finished;
    int loop_count;
    int loops_left;
    int looped_pending;
    int volume;
};

static tsf *soundfont_base;
static struct rg35xx_tsf_slot slots[RG35XX_TSF_SLOTS];
static short render_pcm[RG35XX_TSF_RENDER_FRAMES * 2u];

static int valid_slot(int slot)
{
    return slot >= 0 && slot < RG35XX_TSF_SLOTS;
}

static int prepare_channels(tsf *synth)
{
    int ch;
    if(!synth) return 0;
    for(ch = 0; ch < RG35XX_TSF_CHANNELS; ++ch) {
        if(!tsf_channel_set_presetnumber(synth, ch, 0, ch == 9)) return 0;
    }
    return 1;
}

static void reset_synth(struct rg35xx_tsf_slot *s)
{
    if(!s || !s->synth) return;
    tsf_reset(s->synth);
    prepare_channels(s->synth);
    tsf_set_volume(s->synth, (float)s->volume / 100.0f);
}

static void apply_message(tsf *synth, const tml_message *m)
{
    int ch;
    if(!synth || !m) return;
    ch = (int)m->channel;
    switch(m->type) {
        case TML_NOTE_ON:
            if((unsigned char)m->velocity == 0)
                tsf_channel_note_off(synth, ch, (int)(unsigned char)m->key);
            else
                tsf_channel_note_on(synth, ch, (int)(unsigned char)m->key,
                    (float)(unsigned char)m->velocity / 127.0f);
            break;
        case TML_NOTE_OFF:
            tsf_channel_note_off(synth, ch, (int)(unsigned char)m->key);
            break;
        case TML_PROGRAM_CHANGE:
            tsf_channel_set_presetnumber(synth, ch,
                (int)(unsigned char)m->program, ch == 9);
            break;
        case TML_CONTROL_CHANGE:
            tsf_channel_midi_control(synth, ch,
                (int)(unsigned char)m->control,
                (int)(unsigned char)m->control_value);
            break;
        case TML_PITCH_BEND:
            tsf_channel_set_pitchwheel(synth, ch, (int)m->pitch_bend);
            break;
        default:
            break;
    }
}

static void replay_to(struct rg35xx_tsf_slot *s, uint64_t target_us)
{
    tml_message *m;
    if(!s || !s->synth) return;
    reset_synth(s);
    m = s->first;
    while(m && ((uint64_t)m->time * UINT64_C(1000)) <= target_us) {
        apply_message(s->synth, m);
        m = m->next;
    }
    s->next = m;
    s->time_us = target_us > s->duration_us ? s->duration_us : target_us;
}

static int restart_loop(struct rg35xx_tsf_slot *s)
{
    if(!s) return 0;
    if(s->loop_count == -1 || s->loops_left > 1) {
        if(s->loops_left > 1) --s->loops_left;
        reset_synth(s);
        s->next = s->first;
        s->time_us = 0;
        s->finished = 0;
        s->looped_pending = 1;
        return 1;
    }
    s->playing = 0;
    s->paused = 0;
    s->finished = 1;
    s->time_us = s->duration_us;
    return 0;
}

static size_t frames_until_us(uint64_t now_us, uint64_t target_us)
{
    uint64_t delta;
    uint64_t frames;
    if(target_us <= now_us) return 0;
    delta = target_us - now_us;
    frames = (delta * RG35XX_TSF_RATE + UINT64_C(999999)) / UINT64_C(1000000);
    if(frames > (uint64_t)RG35XX_TSF_RENDER_FRAMES) frames = RG35XX_TSF_RENDER_FRAMES;
    return (size_t)frames;
}

static void render_frames(struct rg35xx_tsf_slot *s, int32_t *accum, size_t offset, size_t frames)
{
    size_t i;
    if(!frames) return;
    tsf_render_short(s->synth, render_pcm, (int)frames, 0);
    for(i = 0; i < frames * 2u; ++i) accum[(offset * 2u) + i] += (int32_t)render_pcm[i];
    s->time_us += ((uint64_t)frames * UINT64_C(1000000)) / RG35XX_TSF_RATE;
}

int rg35xx_tsf_worker_init(const uint8_t *soundfont, size_t size)
{
    if(soundfont_base) return 1;
    if(!soundfont || !size || size > (size_t)INT_MAX) return 0;
    soundfont_base = tsf_load_memory(soundfont, (int)size);
    if(!soundfont_base) return 0;
    tsf_set_output(soundfont_base, TSF_STEREO_INTERLEAVED, (int)RG35XX_TSF_RATE, 0.0f);
    if(!tsf_set_max_voices(soundfont_base, RG35XX_TSF_MAX_VOICES) ||
       !prepare_channels(soundfont_base)) {
        tsf_close(soundfont_base);
        soundfont_base = NULL;
        return 0;
    }
    memset(slots, 0, sizeof(slots));
    return 1;
}

void rg35xx_tsf_worker_shutdown(void)
{
    int i;
    for(i = 0; i < RG35XX_TSF_SLOTS; ++i) rg35xx_tsf_close(i);
    if(soundfont_base) tsf_close(soundfont_base);
    soundfont_base = NULL;
    memset(slots, 0, sizeof(slots));
}

int rg35xx_tsf_worker_ready(void)
{
    return soundfont_base != NULL;
}

int rg35xx_tsf_open_memory(int slot, const uint8_t *midi, size_t size)
{
    struct rg35xx_tsf_slot *s;
    unsigned int length_ms = 0;
    if(!valid_slot(slot) || !soundfont_base || !midi || !size || size > (size_t)INT_MAX) return 0;
    rg35xx_tsf_close(slot);
    s = &slots[slot];
    s->first = tml_load_memory(midi, (int)size);
    if(!s->first) return 0;
    s->synth = tsf_copy(soundfont_base);
    if(!s->synth) {
        tml_free(s->first);
        memset(s, 0, sizeof(*s));
        return 0;
    }
    tsf_set_output(s->synth, TSF_STEREO_INTERLEAVED, (int)RG35XX_TSF_RATE, 0.0f);
    if(!tsf_set_max_voices(s->synth, RG35XX_TSF_MAX_VOICES) || !prepare_channels(s->synth)) {
        tsf_close(s->synth);
        tml_free(s->first);
        memset(s, 0, sizeof(*s));
        return 0;
    }
    tml_get_info(s->first, NULL, NULL, NULL, NULL, &length_ms);
    s->duration_us = (uint64_t)length_ms * UINT64_C(1000);
    s->next = s->first;
    s->volume = 100;
    s->opened = 1;
    return 1;
}

int rg35xx_tsf_start(int slot, int volume, int loop_count, uint64_t media_time_us)
{
    struct rg35xx_tsf_slot *s;
    if(!valid_slot(slot) || loop_count == 0) return 0;
    s = &slots[slot];
    if(!s->opened || !s->synth) return 0;
    if(volume < 0) volume = 0;
    if(volume > 100) volume = 100;
    s->volume = volume;
    s->loop_count = loop_count;
    s->loops_left = loop_count;
    s->looped_pending = 0;
    s->finished = 0;
    tsf_set_volume(s->synth, (float)volume / 100.0f);
    if(media_time_us != s->time_us) replay_to(s, media_time_us);
    s->playing = 1;
    s->paused = 0;
    return 1;
}

int rg35xx_tsf_pause(int slot)
{
    struct rg35xx_tsf_slot *s;
    if(!valid_slot(slot)) return 0;
    s = &slots[slot];
    if(!s->opened) return 0;
    s->playing = 0;
    s->paused = 1;
    return 1;
}

int rg35xx_tsf_stop(int slot)
{
    struct rg35xx_tsf_slot *s;
    if(!valid_slot(slot)) return 0;
    s = &slots[slot];
    if(!s->opened) return 0;
    reset_synth(s);
    s->next = s->first;
    s->time_us = 0;
    s->playing = 0;
    s->paused = 0;
    s->finished = 0;
    s->looped_pending = 0;
    return 1;
}

int rg35xx_tsf_seek(int slot, uint64_t media_time_us)
{
    struct rg35xx_tsf_slot *s;
    if(!valid_slot(slot)) return 0;
    s = &slots[slot];
    if(!s->opened || !s->synth) return 0;
    replay_to(s, media_time_us);
    s->finished = 0;
    s->looped_pending = 0;
    return 1;
}

void rg35xx_tsf_close(int slot)
{
    struct rg35xx_tsf_slot *s;
    if(!valid_slot(slot)) return;
    s = &slots[slot];
    if(s->synth) tsf_close(s->synth);
    if(s->first) tml_free(s->first);
    memset(s, 0, sizeof(*s));
}

size_t rg35xx_tsf_mix_slot(int slot, int32_t *accum, size_t frames)
{
    struct rg35xx_tsf_slot *s;
    size_t done = 0;
    if(!valid_slot(slot) || !accum || !frames) return 0;
    s = &slots[slot];
    if(!s->opened || !s->synth || !s->playing || s->paused || s->finished) return 0;

    while(done < frames && s->playing) {
        size_t remaining = frames - done;
        size_t segment;
        uint64_t next_event_us = s->next ? (uint64_t)s->next->time * UINT64_C(1000) : s->duration_us;

        while(s->next && next_event_us <= s->time_us) {
            apply_message(s->synth, s->next);
            s->next = s->next->next;
            next_event_us = s->next ? (uint64_t)s->next->time * UINT64_C(1000) : s->duration_us;
        }

        if(!s->next && s->time_us >= s->duration_us) {
            if(!restart_loop(s)) break;
            continue;
        }

        segment = frames_until_us(s->time_us, next_event_us);
        if(!segment) segment = 1;
        if(segment > remaining) segment = remaining;
        render_frames(s, accum, done, segment);
        done += segment;
    }
    return done;
}

int rg35xx_tsf_slot_finished(int slot)
{
    return valid_slot(slot) ? slots[slot].finished : 1;
}

uint64_t rg35xx_tsf_slot_time_us(int slot)
{
    return valid_slot(slot) ? slots[slot].time_us : 0;
}

int rg35xx_tsf_take_looped(int slot)
{
    int pending;
    if(!valid_slot(slot)) return 0;
    pending = slots[slot].looped_pending;
    slots[slot].looped_pending = 0;
    return pending;
}
