#!/usr/bin/env python3
import pathlib, sys

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
marker = 'RG35XX-VC7R3-AUDIO: libretro media pump'
if marker in s:
    print('VC7R3 media pump already present')
    raise SystemExit(0)
needle = '''static void rg35xx_drain_media_events_to_java(void)\n{\n\tstruct rg35xx_media_event_record e;\n\twhile(rg35xx_media_event_queue_pop(&e))\n\t\trg35xx_send_media_event(&e);\n}\n'''
if s.count(needle) != 1:
    raise SystemExit('VC7R3 FAIL: expected one media-event drain function after historical 0017')
replacement = '''#define RG35XX_AUDIO_FRAMES_PER_RUN 735u /* 44100 Hz / 60 Hz */\nstatic int16_t rg35xx_audio_run_buffer[RG35XX_AUDIO_FRAMES_PER_RUN * 2u];\n\n/* RG35XX-VC7R3-AUDIO: libretro media pump.\n * Java commands are drained and mixer output is submitted on the libretro run\n * owner. This intentionally does not mutate the accepted RGB565/video path. */\nstatic void rg35xx_pump_media_audio(void)\n{\n\tint drained = rg35xx_audio_pipe_drain(&rg35xx_java_audio_pipe);\n\tsize_t frames;\n\tif(drained < 0)\n\t\tlog_fn(RETRO_LOG_WARN, "RG35XX VC7R3 media pipe drain failed; frontend remains alive.\\n");\n\tframes = rg35xx_mixer_render(rg35xx_audio_run_buffer, RG35XX_AUDIO_FRAMES_PER_RUN);\n\tif(AudioBatch && soundEnabled && frames > 0)\n\t\tAudioBatch(rg35xx_audio_run_buffer, frames);\n}\n\nstatic void rg35xx_drain_media_events_to_java(void)\n{\n\tstruct rg35xx_media_event_record e;\n\trg35xx_pump_media_audio();\n\twhile(rg35xx_media_event_queue_pop(&e))\n\t\trg35xx_send_media_event(&e);\n}\n'''
s = s.replace(needle, replacement)
# Historical 0015 starts a background command drain. The VC7R3 owner is retro_run;
# make the legacy starter a no-op to avoid concurrent mixer/pipe mutation.
old = '''static void rg35xx_audio_drain_start(void)\n{\n\tif(rg35xx_audio_drain_started || rg35xx_java_audio_pipe.read_fd < 0) return;\n\trg35xx_audio_drain_running = 1;\n\tif(pthread_create(&rg35xx_audio_drain_thread, NULL,\n\t                  rg35xx_audio_drain_main, NULL) == 0)\n\t\trg35xx_audio_drain_started = 1;\n\telse\n\t\trg35xx_audio_drain_running = 0;\n}\n'''
new = '''static void rg35xx_audio_drain_start(void)\n{\n\t/* VC7R3: command drain and mixer render are owned by retro_run(). */\n\trg35xx_audio_drain_running = 0;\n\trg35xx_audio_drain_started = 0;\n}\n'''
if s.count(old) != 1:
    raise SystemExit('VC7R3 FAIL: expected historical 0015 audio drain starter')
s = s.replace(old, new)
p.write_text(s, encoding='utf-8')
print('VC7R3 MEDIA PUMP OVERLAY=PASS')
