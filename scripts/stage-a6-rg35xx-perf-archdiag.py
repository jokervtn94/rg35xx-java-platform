#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
p = root / 'adapter/native/rg35xx_video_sdl1.c'
s = p.read_text(encoding='utf-8')

anchor = '''static unsigned long perf_frame_count;\nstatic unsigned long perf_start_ms;\n'''
insert = '''static unsigned long perf_frame_count;\nstatic unsigned long perf_start_ms;\n\n/* ARCH-DIAG: sample one of every 60 presents to isolate synchronous present\n * cost without materially perturbing the device-proven PERF-P3 path. */\nstatic unsigned long archdiag_samples;\nstatic unsigned long archdiag_array_ms;\nstatic unsigned long archdiag_scale_ms;\nstatic unsigned long archdiag_release_ms;\nstatic unsigned long archdiag_flip_ms;\nstatic unsigned long archdiag_total_ms;\n'''
if anchor not in s:
    raise SystemExit('A6_ARCHDIAG_STAGE_FAIL=perf counters anchor missing')
s = s.replace(anchor, insert, 1)

anchor = '''JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_presentARGB(JNIEnv *env, jclass cls, jintArray pixels, jint width, jint height) {\n    jint *src;\n    jsize length;\n    int dw, dh, ox, oy;\n    int x, y;\n    uint32_t black;\n    (void)cls;\n'''
insert = '''JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_presentARGB(JNIEnv *env, jclass cls, jintArray pixels, jint width, jint height) {\n    jint *src;\n    jsize length;\n    int dw, dh, ox, oy;\n    int x, y;\n    uint32_t black;\n    int archdiag_sample = 0;\n    unsigned long archdiag_t0 = 0;\n    unsigned long archdiag_t1 = 0;\n    unsigned long archdiag_t2 = 0;\n    unsigned long archdiag_t3 = 0;\n    unsigned long archdiag_t4 = 0;\n    (void)cls;\n'''
if anchor not in s:
    raise SystemExit('A6_ARCHDIAG_STAGE_FAIL=present header anchor missing')
s = s.replace(anchor, insert, 1)

anchor = '''    src = (*env)->GetIntArrayElements(env, pixels, 0);\n    if (!src) return 5;\n'''
insert = '''    archdiag_sample = (((perf_frame_count + 1ul) % 60ul) == 0ul);\n    if (archdiag_sample) archdiag_t0 = perf_now_ms();\n\n    src = (*env)->GetIntArrayElements(env, pixels, 0);\n    if (!src) return 5;\n    if (archdiag_sample) archdiag_t1 = perf_now_ms();\n'''
if anchor not in s:
    raise SystemExit('A6_ARCHDIAG_STAGE_FAIL=array anchor missing')
s = s.replace(anchor, insert, 1)

anchor = '''    (*env)->ReleaseIntArrayElements(env, pixels, src, JNI_ABORT);\n    if (SDL_Flip_p(screen) != 0) return 6;\n\n    /* Very-low-overhead performance telemetry: one line every 300 presents. */\n    ++perf_frame_count;\n'''
insert = '''    if (archdiag_sample) archdiag_t2 = perf_now_ms();\n    (*env)->ReleaseIntArrayElements(env, pixels, src, JNI_ABORT);\n    if (archdiag_sample) archdiag_t3 = perf_now_ms();\n    if (SDL_Flip_p(screen) != 0) return 6;\n    if (archdiag_sample) archdiag_t4 = perf_now_ms();\n\n    /* Very-low-overhead performance telemetry: one line every 300 presents. */\n    ++perf_frame_count;\n    if (archdiag_sample) {\n        ++archdiag_samples;\n        archdiag_array_ms += archdiag_t1 - archdiag_t0;\n        archdiag_scale_ms += archdiag_t2 - archdiag_t1;\n        archdiag_release_ms += archdiag_t3 - archdiag_t2;\n        archdiag_flip_ms += archdiag_t4 - archdiag_t3;\n        archdiag_total_ms += archdiag_t4 - archdiag_t0;\n    }\n'''
if anchor not in s:
    raise SystemExit('A6_ARCHDIAG_STAGE_FAIL=release/flip anchor missing')
s = s.replace(anchor, insert, 1)

anchor = '''        printf("RG35XX_PERF_P3_FRAME=%lu ELAPSED_MS=%lu FPS_X100=%lu\\n",\n               perf_frame_count, elapsed, fps100);\n        fflush(stdout);\n    }\n    return 0;\n}\n'''
insert = '''        printf("RG35XX_PERF_P3_FRAME=%lu ELAPSED_MS=%lu FPS_X100=%lu\\n",\n               perf_frame_count, elapsed, fps100);\n        if (archdiag_samples) {\n            printf("RG35XX_ARCH_DIAG_PRESENT SAMPLES=%lu ARRAY_AVG_MS=%lu SCALE_AVG_MS=%lu RELEASE_AVG_MS=%lu FLIP_AVG_MS=%lu TOTAL_AVG_MS=%lu\\n",\n                   archdiag_samples,\n                   archdiag_array_ms / archdiag_samples,\n                   archdiag_scale_ms / archdiag_samples,\n                   archdiag_release_ms / archdiag_samples,\n                   archdiag_flip_ms / archdiag_samples,\n                   archdiag_total_ms / archdiag_samples);\n            archdiag_samples = 0;\n            archdiag_array_ms = 0;\n            archdiag_scale_ms = 0;\n            archdiag_release_ms = 0;\n            archdiag_flip_ms = 0;\n            archdiag_total_ms = 0;\n        }\n        fflush(stdout);\n    }\n    return 0;\n}\n'''
if anchor not in s:
    raise SystemExit('A6_ARCHDIAG_STAGE_FAIL=telemetry anchor missing')
s = s.replace(anchor, insert, 1)

p.write_text(s, encoding='utf-8')

# Fail-closed scope gates: P3 must remain present and diagnostic must be sampling only.
checks = [
    'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480',
    'RG35XX_PERF_P2_PIXEL_PACK=FAST',
    '((perf_frame_count + 1ul) % 60ul) == 0ul',
    'RG35XX_ARCH_DIAG_PRESENT SAMPLES=',
    'archdiag_array_ms', 'archdiag_scale_ms', 'archdiag_release_ms', 'archdiag_flip_ms'
]
for c in checks:
    if c not in s:
        raise SystemExit('A6_ARCHDIAG_STAGE_FAIL=missing '+c)
if s.count('SDL_Flip_p(screen)') != 1:
    raise SystemExit('A6_ARCHDIAG_STAGE_FAIL=SDL_Flip semantics changed')
print('A6_ARCHDIAG_STAGE=PASS')
print('A6_ARCHDIAG_SAMPLE_EVERY=60')
print('A6_ARCHDIAG_SEMANTIC_CHANGE=NO')
