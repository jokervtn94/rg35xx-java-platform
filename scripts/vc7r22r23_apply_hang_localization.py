#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 3:
    raise SystemExit('usage: vc7r22r23_apply_hang_localization.py freej2me_libretro.c rg35xx_golden_video.c')

core = pathlib.Path(sys.argv[1])
video = pathlib.Path(sys.argv[2])
for p in (core, video):
    if not p.is_file():
        raise SystemExit('missing source: ' + str(p))


def once(s, old, new, label):
    n = s.count(old)
    if n != 1:
        raise SystemExit('R2.3 FAIL %s count=%d' % (label, n))
    return s.replace(old, new, 1)

# Core/audio observability. Uses existing B4 logger and a finite checkpoint set.
s = core.read_text(encoding='utf-8')
orig = s
if 'RG35XX-R2.3-HANG-LOCALIZATION' in s:
    raise SystemExit('R2.3 already applied')
for token in ('RG35XX_B4_EARLY_LOG', 'RG35XX-VC7R22R1-WORKER-RING',
              'RG35XX_AUDIO_RING_FRAMES 16384u', 'RG35XX_AUDIO_WORKER_CHUNK 1470u'):
    if token not in s:
        raise SystemExit('R2.3 core foundation missing: ' + token)

anchor = 'static unsigned int rg35xx_audio_underrun_log_budget = 8u;\n'
insert = anchor + '''/* RG35XX-R2.3-HANG-LOCALIZATION: bounded diagnostics only. */\nstatic unsigned long rg35xx_r23_worker_loops;\nstatic unsigned long rg35xx_r23_callback_calls;\nstatic unsigned long rg35xx_r23_retro_runs;\nstatic unsigned int rg35xx_r23_set_state_logs;\n\nstatic int rg35xx_r23_checkpoint(unsigned long n)\n{\n    return n == 1ul || n == 8ul || n == 32ul || n == 128ul ||\n           n == 512ul || n == 2048ul || n == 8192ul;\n}\n'''
s = once(s, anchor, insert, 'core counters')

old = '''    while(rg35xx_audio_worker_running) {\n        int drained;\n        int can_render;\n        size_t frames;\n        size_t wrote;\n'''
new = '''    while(rg35xx_audio_worker_running) {\n        int drained;\n        int can_render;\n        size_t frames;\n        size_t wrote;\n        size_t r23_queued;\n        int r23_primed;\n        int r23_enabled;\n        ++rg35xx_r23_worker_loops;\n'''
s = once(s, old, new, 'worker loop counter')

old = '''        pthread_mutex_lock(&rg35xx_audio_mutex);\n        can_render = (rg35xx_audio_ring_count + RG35XX_AUDIO_WORKER_CHUNK\n                      <= RG35XX_AUDIO_HIGH_WATER);\n        pthread_mutex_unlock(&rg35xx_audio_mutex);\n\n        /* Do not fill all 16384 frames with silence. Keep queue depth near the\n'''
new = '''        pthread_mutex_lock(&rg35xx_audio_mutex);\n        can_render = (rg35xx_audio_ring_count + RG35XX_AUDIO_WORKER_CHUNK\n                      <= RG35XX_AUDIO_HIGH_WATER);\n        r23_queued = rg35xx_audio_ring_count;\n        r23_primed = rg35xx_audio_ring_primed;\n        r23_enabled = rg35xx_async_audio_enabled;\n        pthread_mutex_unlock(&rg35xx_audio_mutex);\n        if(rg35xx_r23_checkpoint(rg35xx_r23_worker_loops))\n            rg35xx_b4_log("R23 WORKER_HB seq=%lu drained=%d queued=%lu primed=%d enabled=%d render=%d",\n                          rg35xx_r23_worker_loops, drained, (unsigned long)r23_queued,\n                          r23_primed, r23_enabled, can_render);\n\n        /* Do not fill all 16384 frames with silence. Keep queue depth near the\n'''
s = once(s, old, new, 'worker heartbeat')

old = '''static void rg35xx_audio_callback(void)\n{\n    size_t frames = 0;\n    pthread_mutex_lock(&rg35xx_audio_mutex);\n'''
new = '''static void rg35xx_audio_callback(void)\n{\n    size_t frames = 0;\n    size_t r23_queued = 0;\n    int r23_primed = 0;\n    int r23_enabled = 0;\n    ++rg35xx_r23_callback_calls;\n    pthread_mutex_lock(&rg35xx_audio_mutex);\n'''
s = once(s, old, new, 'callback counter')

old = '''        pthread_cond_signal(&rg35xx_audio_cond);\n    }\n    pthread_mutex_unlock(&rg35xx_audio_mutex);\n\n    if(frames > 0 && AudioBatch && soundEnabled)\n'''
new = '''        pthread_cond_signal(&rg35xx_audio_cond);\n    }\n    r23_queued = rg35xx_audio_ring_count;\n    r23_primed = rg35xx_audio_ring_primed;\n    r23_enabled = rg35xx_async_audio_enabled;\n    pthread_mutex_unlock(&rg35xx_audio_mutex);\n    if(rg35xx_r23_checkpoint(rg35xx_r23_callback_calls))\n        rg35xx_b4_log("R23 CALLBACK_HB seq=%lu frames=%lu queued=%lu primed=%d enabled=%d",\n                      rg35xx_r23_callback_calls, (unsigned long)frames,\n                      (unsigned long)r23_queued, r23_primed, r23_enabled);\n\n    if(frames > 0 && AudioBatch && soundEnabled)\n'''
s = once(s, old, new, 'callback heartbeat')

old = '''static void rg35xx_audio_set_state(bool enabled)\n{\n    pthread_mutex_lock(&rg35xx_audio_mutex);\n'''
new = '''static void rg35xx_audio_set_state(bool enabled)\n{\n    if(rg35xx_r23_set_state_logs < 8u) {\n        ++rg35xx_r23_set_state_logs;\n        rg35xx_b4_log("R23 SET_STATE seq=%u enabled=%d worker_started=%d",\n                      rg35xx_r23_set_state_logs, enabled ? 1 : 0,\n                      rg35xx_audio_worker_started);\n    }\n    pthread_mutex_lock(&rg35xx_audio_mutex);\n'''
s = once(s, old, new, 'set_state bounded log')

old = 'void retro_run(void)\n{\n'
new = '''void retro_run(void)\n{\n#ifdef __linux__\n    ++rg35xx_r23_retro_runs;\n    if(rg35xx_r23_checkpoint(rg35xx_r23_retro_runs))\n        rg35xx_b4_log("R23 RETRO_RUN_HB seq=%lu java_pid=%d",\n                      rg35xx_r23_retro_runs, javaProcess);\n#endif\n'''
s = once(s, old, new, 'retro_run heartbeat')

for token in ('R23 WORKER_HB', 'R23 CALLBACK_HB', 'R23 SET_STATE', 'R23 RETRO_RUN_HB'):
    if token not in s:
        raise SystemExit('R2.3 core marker missing: ' + token)
if s == orig:
    raise SystemExit('R2.3 core no mutation')
core.write_text(s, encoding='utf-8', newline='\n')

# Video observability only. Existing B4 video logger writes to the same file.
s = video.read_text(encoding='utf-8')
orig = s
for token in ('RG35XX_B4_VIDEO_LOG', 'B4 FIRST_PRESENT', 'B4 VIDEO_DEINIT'):
    if token not in s:
        raise SystemExit('R2.3 video foundation missing: ' + token)

s = once(s,
'''    int obs_first_present;\n};''',
'''    int obs_first_present;\n    unsigned long obs_r23_present_calls;\n};''',
'video counter field')

old = '''    if(geometry_cb) geometry_cb(g.output_width, g.output_height);\n    video_cb(g.canvas, g.output_width, g.output_height,\n             (size_t)g.output_width * sizeof(uint16_t));\n    g.presented_generation = generation;'''
new = '''    ++g.obs_r23_present_calls;\n    if(g.obs_r23_present_calls == 1ul || g.obs_r23_present_calls == 8ul ||\n       g.obs_r23_present_calls == 32ul || g.obs_r23_present_calls == 128ul ||\n       g.obs_r23_present_calls == 512ul || g.obs_r23_present_calls == 2048ul ||\n       g.obs_r23_present_calls == 8192ul)\n        rg35xx_b4_video_log("R23 VIDEO_HB seq=%lu generation=%lu presented=%lu src=%ux%u dst=%ux%u",\n                            g.obs_r23_present_calls, generation, g.presented_generation,\n                            g.snapshot.width, g.snapshot.height, g.cached_dst_w, g.cached_dst_h);\n\n    if(geometry_cb) geometry_cb(g.output_width, g.output_height);\n    video_cb(g.canvas, g.output_width, g.output_height,\n             (size_t)g.output_width * sizeof(uint16_t));\n    g.presented_generation = generation;'''
s = once(s, old, new, 'video heartbeat')

if 'R23 VIDEO_HB' not in s:
    raise SystemExit('R2.3 video marker missing')
if s == orig:
    raise SystemExit('R2.3 video no mutation')
video.write_text(s, encoding='utf-8', newline='\n')

print('R2.3 HANG_LOCALIZATION=PASS')
print('R2.3 BEHAVIOR_CHANGE=NONE_DIAGNOSTICS_ONLY')
print('R2.3 LOG_SCHEDULE=1,8,32,128,512,2048,8192')
