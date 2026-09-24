#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-perf-a1-async-native.py <repo-root>')
root = Path(sys.argv[1]).resolve()
p = root / 'adapter/native/rg35xx_video_sdl1.c'
s = p.read_text(encoding='utf-8')

# A1 must layer on the exact PERF-P3 source, not ARCH-DIAG/P4/J1.
for marker in (
    'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480',
    'static uint32_t perf3_row[360];',
    'RG35XX_PERF_P3_FRAME=',
):
    if marker not in s:
        raise SystemExit('A6_PERF_A1_STAGE_FAIL missing P3 marker '+marker)
if 'RG35XX_ARCH_DIAG_PRESENT' in s:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL ARCH-DIAG contamination')
if 'RG35XX_PERF_P4_SCALER' in s:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL P4 contamination')

# Optional SDL 1.2 thread primitives. They are dynamically resolved so the
# existing -ldl-only native link contract remains untouched. If unavailable,
# runtime falls back to synchronous PERF-P3 rather than failing display init.
type_anchor = 'typedef char *(*pSDL_VideoDriverName)(char *, int);\n'
type_repl = type_anchor + '''typedef struct SDL_Thread SDL_Thread;\ntypedef struct SDL_mutex SDL_mutex;\ntypedef struct SDL_cond SDL_cond;\ntypedef SDL_Thread *(*pSDL_CreateThread)(int (*)(void *), void *);\ntypedef void (*pSDL_WaitThread)(SDL_Thread *, int *);\ntypedef SDL_mutex *(*pSDL_CreateMutex)(void);\ntypedef void (*pSDL_DestroyMutex)(SDL_mutex *);\ntypedef int (*pSDL_mutexP)(SDL_mutex *);\ntypedef int (*pSDL_mutexV)(SDL_mutex *);\ntypedef SDL_cond *(*pSDL_CreateCond)(void);\ntypedef void (*pSDL_DestroyCond)(SDL_cond *);\ntypedef int (*pSDL_CondSignal)(SDL_cond *);\ntypedef int (*pSDL_CondWait)(SDL_cond *, SDL_mutex *);\n'''
if s.count(type_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL type anchor count=%d' % s.count(type_anchor))
s = s.replace(type_anchor, type_repl, 1)

glob_anchor = 'static pSDL_VideoDriverName SDL_VideoDriverName_p;\n'
glob_repl = glob_anchor + '''static pSDL_CreateThread SDL_CreateThread_p;\nstatic pSDL_WaitThread SDL_WaitThread_p;\nstatic pSDL_CreateMutex SDL_CreateMutex_p;\nstatic pSDL_DestroyMutex SDL_DestroyMutex_p;\nstatic pSDL_mutexP SDL_mutexP_p;\nstatic pSDL_mutexV SDL_mutexV_p;\nstatic pSDL_CreateCond SDL_CreateCond_p;\nstatic pSDL_DestroyCond SDL_DestroyCond_p;\nstatic pSDL_CondSignal SDL_CondSignal_p;\nstatic pSDL_CondWait SDL_CondWait_p;\n'''
if s.count(glob_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL global SDL anchor count=%d' % s.count(glob_anchor))
s = s.replace(glob_anchor, glob_repl, 1)

load_anchor = '''    LOADSYM(SDL_VideoDriverName);\n#undef LOADSYM\n    return 0;\n'''
load_repl = '''    LOADSYM(SDL_VideoDriverName);\n#undef LOADSYM\n    SDL_CreateThread_p = (pSDL_CreateThread)dlsym(sdl, "SDL_CreateThread");\n    SDL_WaitThread_p = (pSDL_WaitThread)dlsym(sdl, "SDL_WaitThread");\n    SDL_CreateMutex_p = (pSDL_CreateMutex)dlsym(sdl, "SDL_CreateMutex");\n    SDL_DestroyMutex_p = (pSDL_DestroyMutex)dlsym(sdl, "SDL_DestroyMutex");\n    SDL_mutexP_p = (pSDL_mutexP)dlsym(sdl, "SDL_mutexP");\n    SDL_mutexV_p = (pSDL_mutexV)dlsym(sdl, "SDL_mutexV");\n    SDL_CreateCond_p = (pSDL_CreateCond)dlsym(sdl, "SDL_CreateCond");\n    SDL_DestroyCond_p = (pSDL_DestroyCond)dlsym(sdl, "SDL_DestroyCond");\n    SDL_CondSignal_p = (pSDL_CondSignal)dlsym(sdl, "SDL_CondSignal");\n    SDL_CondWait_p = (pSDL_CondWait)dlsym(sdl, "SDL_CondWait");\n    return 0;\n'''
if s.count(load_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL load anchor count=%d' % s.count(load_anchor))
s = s.replace(load_anchor, load_repl, 1)

state_anchor = 'static int perf3_announced;\n'
state_repl = state_anchor + '''\n/* PERF-A1: the ARCH-DIAG real-device run measured synchronous present at\n * 6.22 ms average (1.89 ms P3 scale + 4.06 ms SDL_Flip) out of the game's\n * 50 ms target frame budget. Keep exact PERF-P3 rendering, but move the\n * exact 240x320 path to a native latest-frame worker. Three source slots let\n * the producer snapshot without touching the worker's active or queued slot. */\n#define PERF_A1_W 240\n#define PERF_A1_H 320\n#define PERF_A1_PIXELS (PERF_A1_W * PERF_A1_H)\nstatic uint32_t perf_a1_frames[3][PERF_A1_PIXELS];\nstatic SDL_Thread *perf_a1_thread;\nstatic SDL_mutex *perf_a1_mutex;\nstatic SDL_cond *perf_a1_cond;\nstatic int perf_a1_enabled;\nstatic int perf_a1_running;\nstatic int perf_a1_latest = -1;\nstatic int perf_a1_worker = -1;\nstatic int perf_a1_first_present = 1;\nstatic unsigned long perf_a1_submits;\nstatic unsigned long perf_a1_presented;\nstatic unsigned long perf_a1_dropped;\nstatic unsigned long perf_a1_copy_ms;\nstatic int perf_a1_last_rc;\n'''
if s.count(state_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL P3 state anchor count=%d' % s.count(state_anchor))
s = s.replace(state_anchor, state_repl, 1)

# Worker helper is intentionally exact P3 240x320 -> 360x480 rendering.
helper_anchor = 'JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_initDisplay(JNIEnv *env, jclass cls) {'
helper = r'''static int perf_a1_render_exact(const uint32_t *src) {
    int x, y;
    uint32_t black;

    if (!screen || !screen->pixels || !src) return 1;
    if (perf_a1_first_present) {
        black = SDL_MapRGB_p(screen->format, 0, 0, 0);
        for (y = 0; y < RG35XX_LCD_H; ++y) {
            uint32_t *row = (uint32_t *)((uint8_t *)screen->pixels + y * screen->pitch);
            for (x = 0; x < RG35XX_LCD_W; ++x) row[x] = black;
        }
        perf_a1_first_present = 0;
    }

    if (!perf3_announced) {
        printf("RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480\n");
        fflush(stdout);
        perf3_announced = 1;
    }
    for (y = 0; y < 320; ++y) {
        int srcbase = y * 240;
        int dx = 0;
        int dy = (y >> 1) * 3 + ((y & 1) ? 2 : 0);
        uint32_t *dst0;
        for (x = 0; x < 240; x += 2) {
            uint32_t a0 = src[srcbase + x];
            uint32_t a1 = src[srcbase + x + 1];
            uint32_t r0 = (a0 >> 16) & 0xffu;
            uint32_t g0 = (a0 >> 8) & 0xffu;
            uint32_t b0 = a0 & 0xffu;
            uint32_t r1 = (a1 >> 16) & 0xffu;
            uint32_t g1 = (a1 >> 8) & 0xffu;
            uint32_t b1 = a1 & 0xffu;
            uint32_t p0 = ((r0 >> perf2_rloss) << perf2_rshift)
                        | ((g0 >> perf2_gloss) << perf2_gshift)
                        | ((b0 >> perf2_bloss) << perf2_bshift)
                        | perf2_amask;
            uint32_t p1 = ((r1 >> perf2_rloss) << perf2_rshift)
                        | ((g1 >> perf2_gloss) << perf2_gshift)
                        | ((b1 >> perf2_bloss) << perf2_bshift)
                        | perf2_amask;
            perf3_row[dx++] = p0;
            perf3_row[dx++] = p0;
            perf3_row[dx++] = p1;
        }
        dst0 = (uint32_t *)((uint8_t *)screen->pixels + dy * screen->pitch) + 140;
        memcpy(dst0, perf3_row, 360u * sizeof(uint32_t));
        if ((y & 1) == 0) {
            uint32_t *dst1 = (uint32_t *)((uint8_t *)screen->pixels + (dy + 1) * screen->pitch) + 140;
            memcpy(dst1, perf3_row, 360u * sizeof(uint32_t));
        }
    }

    if (SDL_Flip_p(screen) != 0) return 6;
    ++perf_frame_count;
    if (perf_frame_count == 1) perf_start_ms = perf_now_ms();
    if ((perf_frame_count % 300ul) == 0ul) {
        unsigned long elapsed = perf_now_ms() - perf_start_ms;
        unsigned long fps100 = elapsed ? (perf_frame_count * 100000ul) / elapsed : 0ul;
        printf("RG35XX_PERF_P3_FRAME=%lu ELAPSED_MS=%lu FPS_X100=%lu\n",
               perf_frame_count, elapsed, fps100);
        fflush(stdout);
    }
    return 0;
}

static int perf_a1_worker_main(void *unused) {
    (void)unused;
    for (;;) {
        int slot;
        int rc;
        SDL_mutexP_p(perf_a1_mutex);
        while (perf_a1_running && perf_a1_latest < 0)
            SDL_CondWait_p(perf_a1_cond, perf_a1_mutex);
        if (!perf_a1_running) {
            SDL_mutexV_p(perf_a1_mutex);
            break;
        }
        slot = perf_a1_latest;
        perf_a1_latest = -1;
        perf_a1_worker = slot;
        SDL_mutexV_p(perf_a1_mutex);

        rc = perf_a1_render_exact(perf_a1_frames[slot]);

        SDL_mutexP_p(perf_a1_mutex);
        perf_a1_worker = -1;
        ++perf_a1_presented;
        if (rc != 0) perf_a1_last_rc = rc;
        SDL_mutexV_p(perf_a1_mutex);
    }
    return 0;
}

static void perf_a1_stop(void) {
    if (!perf_a1_enabled) return;
    SDL_mutexP_p(perf_a1_mutex);
    perf_a1_running = 0;
    SDL_CondSignal_p(perf_a1_cond);
    SDL_mutexV_p(perf_a1_mutex);
    if (perf_a1_thread && SDL_WaitThread_p) SDL_WaitThread_p(perf_a1_thread, 0);
    perf_a1_thread = 0;
    if (perf_a1_cond && SDL_DestroyCond_p) SDL_DestroyCond_p(perf_a1_cond);
    if (perf_a1_mutex && SDL_DestroyMutex_p) SDL_DestroyMutex_p(perf_a1_mutex);
    perf_a1_cond = 0;
    perf_a1_mutex = 0;
    perf_a1_enabled = 0;
}

static int perf_a1_start(void) {
    if (!SDL_CreateThread_p || !SDL_WaitThread_p || !SDL_CreateMutex_p ||
        !SDL_DestroyMutex_p || !SDL_mutexP_p || !SDL_mutexV_p ||
        !SDL_CreateCond_p || !SDL_DestroyCond_p || !SDL_CondSignal_p || !SDL_CondWait_p) {
        printf("RG35XX_PERF_A1_ASYNC=SDL_THREAD_API_UNAVAILABLE_FALLBACK_P3\n");
        fflush(stdout);
        return 0;
    }
    perf_a1_mutex = SDL_CreateMutex_p();
    perf_a1_cond = SDL_CreateCond_p();
    if (!perf_a1_mutex || !perf_a1_cond) {
        if (perf_a1_cond) SDL_DestroyCond_p(perf_a1_cond);
        if (perf_a1_mutex) SDL_DestroyMutex_p(perf_a1_mutex);
        perf_a1_cond = 0;
        perf_a1_mutex = 0;
        printf("RG35XX_PERF_A1_ASYNC=SYNC_OBJECT_FAIL_FALLBACK_P3\n");
        fflush(stdout);
        return 0;
    }
    perf_a1_running = 1;
    perf_a1_latest = -1;
    perf_a1_worker = -1;
    perf_a1_thread = SDL_CreateThread_p(perf_a1_worker_main, 0);
    if (!perf_a1_thread) {
        perf_a1_running = 0;
        SDL_DestroyCond_p(perf_a1_cond);
        SDL_DestroyMutex_p(perf_a1_mutex);
        perf_a1_cond = 0;
        perf_a1_mutex = 0;
        printf("RG35XX_PERF_A1_ASYNC=THREAD_CREATE_FAIL_FALLBACK_P3\n");
        fflush(stdout);
        return 0;
    }
    perf_a1_enabled = 1;
    printf("RG35XX_PERF_A1_ASYNC=ENABLED MODE=LATEST_ONLY SLOTS=3 SOURCE=240x320 WORKER=P3_SCALE_PLUS_SDL_FLIP\n");
    fflush(stdout);
    return 1;
}

'''
if s.count(helper_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL init anchor count=%d' % s.count(helper_anchor))
s = s.replace(helper_anchor, helper + helper_anchor, 1)

# Start worker only after exact true-colour framebuffer capability is known.
init_anchor = '''        fflush(stdout);\n    }\n    return 0;\n}\n\nJNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_presentARGB'''
init_repl = '''        fflush(stdout);\n    }\n    if (perf2_fast_rgb) perf_a1_start();\n    return 0;\n}\n\nJNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_presentARGB'''
if s.count(init_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL init tail anchor count=%d' % s.count(init_anchor))
s = s.replace(init_anchor, init_repl, 1)

# Exact 240x320 path now snapshots to native latest-frame slots and returns.
# Any geometry change stops A1 and falls through to untouched synchronous P3.
present_anchor = '''    if (!screen || !screen->pixels || !pixels) return 1;\n    if (width <= 0 || height <= 0) return 2;\n    length = (*env)->GetArrayLength(env, pixels);\n    if ((long long)length < (long long)width * (long long)height) return 3;\n\n    fit_geometry(width, height, &dw, &dh, &ox, &oy);\n'''
present_repl = '''    if (!screen || !screen->pixels || !pixels) return 1;\n    if (width <= 0 || height <= 0) return 2;\n    length = (*env)->GetArrayLength(env, pixels);\n    if ((long long)length < (long long)width * (long long)height) return 3;\n\n    if (perf_a1_enabled && width == PERF_A1_W && height == PERF_A1_H) {\n        int slot = -1;\n        int i;\n        unsigned long copy_t0 = perf_now_ms();\n        unsigned long submits_snapshot = 0;\n        unsigned long presented_snapshot = 0;\n        unsigned long dropped_snapshot = 0;\n        unsigned long copy_snapshot = 0;\n\n        SDL_mutexP_p(perf_a1_mutex);\n        for (i = 0; i < 3; ++i) {\n            if (i != perf_a1_latest && i != perf_a1_worker) { slot = i; break; }\n        }\n        SDL_mutexV_p(perf_a1_mutex);\n        if (slot < 0) return 7;\n\n        src = (*env)->GetIntArrayElements(env, pixels, 0);\n        if (!src) return 5;\n        memcpy(perf_a1_frames[slot], src, PERF_A1_PIXELS * sizeof(uint32_t));\n        (*env)->ReleaseIntArrayElements(env, pixels, src, JNI_ABORT);\n\n        SDL_mutexP_p(perf_a1_mutex);\n        if (perf_a1_latest >= 0) ++perf_a1_dropped;\n        perf_a1_latest = slot;\n        ++perf_a1_submits;\n        perf_a1_copy_ms += perf_now_ms() - copy_t0;\n        if ((perf_a1_submits % 300ul) == 0ul) {\n            submits_snapshot = perf_a1_submits;\n            presented_snapshot = perf_a1_presented;\n            dropped_snapshot = perf_a1_dropped;\n            copy_snapshot = perf_a1_copy_ms;\n            perf_a1_copy_ms = 0;\n        }\n        SDL_CondSignal_p(perf_a1_cond);\n        SDL_mutexV_p(perf_a1_mutex);\n\n        if (submits_snapshot) {\n            printf("RG35XX_PERF_A1_QUEUE SUBMITS=%lu PRESENTED=%lu DROPPED=%lu COPY_AVG_MS=%lu LAST_RC=%d\\n",\n                   submits_snapshot, presented_snapshot, dropped_snapshot, copy_snapshot / 300ul, perf_a1_last_rc);\n            fflush(stdout);\n        }\n        return 0;\n    } else if (perf_a1_enabled) {\n        printf("RG35XX_PERF_A1_ASYNC=GEOMETRY_CHANGE_FALLBACK_P3 SOURCE=%dx%d\\n", (int)width, (int)height);\n        fflush(stdout);\n        perf_a1_stop();\n    }\n\n    fit_geometry(width, height, &dw, &dh, &ox, &oy);\n'''
if s.count(present_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL present anchor count=%d' % s.count(present_anchor))
s = s.replace(present_anchor, present_repl, 1)

# Stop/join worker before SDL_Quit and clear optional symbol pointers.
shutdown_anchor = '''    (void)env;\n    (void)cls;\n    if (SDL_Quit_p) SDL_Quit_p();\n'''
shutdown_repl = '''    (void)env;\n    (void)cls;\n    perf_a1_stop();\n    if (SDL_Quit_p) SDL_Quit_p();\n'''
if s.count(shutdown_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL shutdown anchor count=%d' % s.count(shutdown_anchor))
s = s.replace(shutdown_anchor, shutdown_repl, 1)

clear_anchor = '''    SDL_MapRGB_p = 0;\n    SDL_VideoDriverName_p = 0;\n}\n'''
clear_repl = '''    SDL_MapRGB_p = 0;\n    SDL_VideoDriverName_p = 0;\n    SDL_CreateThread_p = 0;\n    SDL_WaitThread_p = 0;\n    SDL_CreateMutex_p = 0;\n    SDL_DestroyMutex_p = 0;\n    SDL_mutexP_p = 0;\n    SDL_mutexV_p = 0;\n    SDL_CreateCond_p = 0;\n    SDL_DestroyCond_p = 0;\n    SDL_CondSignal_p = 0;\n    SDL_CondWait_p = 0;\n}\n'''
if s.count(clear_anchor) != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL clear anchor count=%d' % s.count(clear_anchor))
s = s.replace(clear_anchor, clear_repl, 1)

# Fail-closed source gates.
required = (
    'RG35XX_PERF_A1_ASYNC=ENABLED MODE=LATEST_ONLY SLOTS=3 SOURCE=240x320 WORKER=P3_SCALE_PLUS_SDL_FLIP',
    'RG35XX_PERF_A1_QUEUE SUBMITS=',
    'memcpy(perf_a1_frames[slot], src, PERF_A1_PIXELS * sizeof(uint32_t));',
    'perf_a1_render_exact(perf_a1_frames[slot])',
    'perf_a1_stop();',
    'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480',
)
for marker in required:
    if marker not in s:
        raise SystemExit('A6_PERF_A1_STAGE_FAIL missing '+marker)
if s.count('RG35XX_PERF_A1_ASYNC=ENABLED') != 1:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL async enable marker count')
if 'java.lang' in s:
    raise SystemExit('A6_PERF_A1_STAGE_FAIL unexpected Java-side edit marker')

p.write_text(s, encoding='utf-8')
print('A6_PERF_A1_STAGE=PASS')
print('A6_PERF_A1_OWNER=SYNCHRONOUS_P3_SCALE_PLUS_SDL_FLIP_6P22MS_AVG')
print('A6_PERF_A1_JAVA=UNCHANGED_EXACT_PERF_P3')
print('A6_PERF_A1_QUEUE=LATEST_ONLY_3_NATIVE_SLOTS')
print('A6_PERF_A1_GENERIC_GEOMETRY=SYNC_P3_FALLBACK')
