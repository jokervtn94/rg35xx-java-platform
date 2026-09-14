#!/usr/bin/env python3
"""VC7R22-R2: restore the device-evidenced 14700 Hz mono x3 TSF staging.

This overlay is intentionally narrow: it only changes the MIDI TSF synthesis
rate/output staging in rg35xx_tsf_worker.c and adds one bounded provenance log
in the R1 worker-ring owner. PCM and video code are not altered here.
"""
import pathlib
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: vc7r22r2_apply_golden_tsf.py rg35xx_tsf_worker.c freej2me_libretro.c")

tsf_path = pathlib.Path(sys.argv[1])
core_path = pathlib.Path(sys.argv[2])
s = tsf_path.read_text(encoding="utf-8")
c = core_path.read_text(encoding="utf-8")

if "RG35XX-VC7R22R2-14700-MONO-X3" in s:
    raise SystemExit("VC7R22-R2 already applied")
if "RG35XX-VC7R22R1-WORKER-RING" not in c:
    raise SystemExit("VC7R22-R2 FAIL: R1 worker-ring foundation missing")


def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit("VC7R22-R2 FAIL %s count=%d" % (label, n))
    return text.replace(old, new, 1)

s = once(s,
    "#define RG35XX_TSF_RATE 44100u\n#define RG35XX_TSF_CHANNELS 16\n#define RG35XX_TSF_MAX_VOICES 16\n#define RG35XX_TSF_RENDER_FRAMES 1024u",
    "/* RG35XX-VC7R22R2-14700-MONO-X3\n * Device-evidenced Golden staging: synth at 14700 Hz mono, then duplicate\n * each synthesized sample exactly three output frames to 44100 Hz stereo.\n */\n#define RG35XX_TSF_RATE 14700u\n#define RG35XX_TSF_OUTPUT_RATE 44100u\n#define RG35XX_TSF_UPSAMPLE_X 3u\n#define RG35XX_TSF_CHANNELS 16\n#define RG35XX_TSF_MAX_VOICES 16\n#define RG35XX_TSF_RENDER_FRAMES 1024u",
    "rate constants")

s = once(s,
    "    int looped_pending;\n    int volume;\n};",
    "    int looped_pending;\n    int volume;\n    int16_t repeat_sample;\n    unsigned int repeat_left;\n};",
    "repeat state")

s = once(s,
    "static short render_pcm[RG35XX_TSF_RENDER_FRAMES * 2u];",
    "static short render_pcm[RG35XX_TSF_RENDER_FRAMES];",
    "mono scratch")

s = once(s,
    "    tsf_set_volume(s->synth, (float)s->volume / 100.0f);\n}",
    "    tsf_set_volume(s->synth, (float)s->volume / 100.0f);\n    s->repeat_sample = 0;\n    s->repeat_left = 0;\n}",
    "reset repeat")

old_render = '''static void render_frames(struct rg35xx_tsf_slot *s, int32_t *accum, size_t offset, size_t frames)\n{\n    size_t i;\n    if(!frames) return;\n    tsf_render_short(s->synth, render_pcm, (int)frames, 0);\n    for(i = 0; i < frames * 2u; ++i) accum[(offset * 2u) + i] += (int32_t)render_pcm[i];\n    s->frame_pos += frames;\n}\n'''
new_render = '''static size_t emit_pending_repeat(struct rg35xx_tsf_slot *s, int32_t *accum,\n    size_t offset, size_t capacity)\n{\n    size_t done = 0;\n    while(s->repeat_left && done < capacity) {\n        accum[(offset + done) * 2u] += (int32_t)s->repeat_sample;\n        accum[(offset + done) * 2u + 1u] += (int32_t)s->repeat_sample;\n        --s->repeat_left;\n        ++done;\n    }\n    return done;\n}\n\nstatic size_t render_frames_mono_x3(struct rg35xx_tsf_slot *s, int32_t *accum,\n    size_t offset, size_t out_capacity, size_t synth_frames)\n{\n    size_t i, done = 0;\n    if(!synth_frames || !out_capacity) return 0;\n    if(synth_frames > RG35XX_TSF_RENDER_FRAMES)\n        synth_frames = RG35XX_TSF_RENDER_FRAMES;\n    tsf_render_short(s->synth, render_pcm, (int)synth_frames, 0);\n    for(i = 0; i < synth_frames && done < out_capacity; ++i) {\n        unsigned int r;\n        int16_t sample = render_pcm[i];\n        ++s->frame_pos;\n        for(r = 0; r < RG35XX_TSF_UPSAMPLE_X && done < out_capacity; ++r) {\n            accum[(offset + done) * 2u] += (int32_t)sample;\n            accum[(offset + done) * 2u + 1u] += (int32_t)sample;\n            ++done;\n        }\n        if(r < RG35XX_TSF_UPSAMPLE_X) {\n            s->repeat_sample = sample;\n            s->repeat_left = RG35XX_TSF_UPSAMPLE_X - r;\n        }\n    }\n    return done;\n}\n'''
s = once(s, old_render, new_render, "render helper")

s = s.replace("tsf_set_output(soundfont_base, TSF_STEREO_INTERLEAVED, (int)RG35XX_TSF_RATE, 0.0f);",
              "tsf_set_output(soundfont_base, TSF_MONO, (int)RG35XX_TSF_RATE, 0.0f);")
s = s.replace("tsf_set_output(s->synth, TSF_STEREO_INTERLEAVED, (int)RG35XX_TSF_RATE, 0.0f);",
              "tsf_set_output(s->synth, TSF_MONO, (int)RG35XX_TSF_RATE, 0.0f);")
if "TSF_STEREO_INTERLEAVED" in s:
    raise SystemExit("VC7R22-R2 FAIL: stereo TSF residue")

old_mix = '''size_t rg35xx_tsf_mix_slot(int slot, int32_t *accum, size_t frames)\n{\n    struct rg35xx_tsf_slot *s;\n    size_t done = 0;\n    if(!valid_slot(slot) || !accum || !frames) return 0;\n    s = &slots[slot];\n    if(!s->opened || !s->synth || !s->playing || s->paused || s->finished) return 0;\n\n    while(done < frames && s->playing) {\n        size_t remaining = frames - done;\n        size_t segment;\n        uint64_t boundary_frame = s->next ? message_frame(s->next) : s->duration_frames;\n\n        while(s->next && boundary_frame <= s->frame_pos) {\n            apply_message(s->synth, s->next);\n            s->next = s->next->next;\n            boundary_frame = s->next ? message_frame(s->next) : s->duration_frames;\n        }\n\n        if(!s->next && s->frame_pos >= s->duration_frames) {\n            if(!restart_loop(s)) break;\n            continue;\n        }\n\n        segment = boundary_frame > s->frame_pos ? (size_t)(boundary_frame - s->frame_pos) : 1u;\n        if(segment > remaining) segment = remaining;\n        if(segment > RG35XX_TSF_RENDER_FRAMES) segment = RG35XX_TSF_RENDER_FRAMES;\n        render_frames(s, accum, done, segment);\n        done += segment;\n    }\n    return done;\n}\n'''
new_mix = '''size_t rg35xx_tsf_mix_slot(int slot, int32_t *accum, size_t frames)\n{\n    struct rg35xx_tsf_slot *s;\n    size_t done = 0;\n    if(!valid_slot(slot) || !accum || !frames) return 0;\n    s = &slots[slot];\n    if(!s->opened || !s->synth || !s->playing || s->paused || s->finished) return 0;\n\n    done += emit_pending_repeat(s, accum, done, frames - done);\n    while(done < frames && s->playing) {\n        size_t remaining = frames - done;\n        size_t synth_segment;\n        size_t max_synth_for_output;\n        uint64_t boundary_frame = s->next ? message_frame(s->next) : s->duration_frames;\n\n        while(s->next && boundary_frame <= s->frame_pos) {\n            apply_message(s->synth, s->next);\n            s->next = s->next->next;\n            boundary_frame = s->next ? message_frame(s->next) : s->duration_frames;\n        }\n\n        if(!s->next && s->frame_pos >= s->duration_frames) {\n            if(!restart_loop(s)) break;\n            done += emit_pending_repeat(s, accum, done, frames - done);\n            continue;\n        }\n\n        synth_segment = boundary_frame > s->frame_pos\n            ? (size_t)(boundary_frame - s->frame_pos) : 1u;\n        max_synth_for_output = (remaining + RG35XX_TSF_UPSAMPLE_X - 1u) / RG35XX_TSF_UPSAMPLE_X;\n        if(synth_segment > max_synth_for_output) synth_segment = max_synth_for_output;\n        if(synth_segment > RG35XX_TSF_RENDER_FRAMES) synth_segment = RG35XX_TSF_RENDER_FRAMES;\n        done += render_frames_mono_x3(s, accum, done, frames - done, synth_segment);\n        if(done < frames) done += emit_pending_repeat(s, accum, done, frames - done);\n    }\n    return done;\n}\n'''
s = once(s, old_mix, new_mix, "mix slot")

required = (
    "RG35XX-VC7R22R2-14700-MONO-X3",
    "#define RG35XX_TSF_RATE 14700u",
    "#define RG35XX_TSF_OUTPUT_RATE 44100u",
    "#define RG35XX_TSF_UPSAMPLE_X 3u",
    "TSF_MONO",
    "render_frames_mono_x3",
    "repeat_left",
)
for token in required:
    if token not in s:
        raise SystemExit("VC7R22-R2 FAIL missing " + token)

old_init = '''    if(rg35xx_load_soundfont_bytes() &&\n       !rg35xx_media_runtime_init(rg35xx_soundfont_bytes,\n                                  rg35xx_soundfont_size))\n        log_fn(RETRO_LOG_WARN,\n            "RG35XX VC7R22-R1 MIDI runtime init failed; PCM remains available.\\n");\n    rg35xx_register_async_audio();'''
new_init = '''    if(rg35xx_load_soundfont_bytes()) {\n        if(!rg35xx_media_runtime_init(rg35xx_soundfont_bytes,\n                                      rg35xx_soundfont_size)) {\n            log_fn(RETRO_LOG_WARN,\n                "RG35XX VC7R22-R2 MIDI runtime init failed; PCM remains available.\\n");\n        } else {\n            log_fn(RETRO_LOG_INFO,\n                "RG35XX-AUDIO: SoundFont loaded, synth=14700Hz output=44100Hz voices=16 mono-x3 STABLE worker-ring\\n");\n        }\n    }\n    rg35xx_register_async_audio();'''
c = once(c, old_init, new_init, "runtime init provenance")

if "RG35XX_AUDIO_FRAMES_PER_RUN 735u" in c or "rg35xx_pump_media_audio();" in c:
    raise SystemExit("VC7R22-R2 FAIL: frame-coupled audio residue")

tsf_path.write_text(s, encoding="utf-8", newline="\n")
core_path.write_text(c, encoding="utf-8", newline="\n")
print("VC7R22-R2 GOLDEN TSF STAGING=PASS")
print("VC7R22-R2 SYNTH=14700 MONO UPSAMPLE_X=3 OUTPUT=44100")
print("VC7R22-R2 VIDEO=UNTOUCHED PCM=UNTOUCHED")
