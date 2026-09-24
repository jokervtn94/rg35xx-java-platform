#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-video-perf-p1.py <repo-root>')
root = Path(sys.argv[1]).resolve()
p = root / 'adapter/native/rg35xx_video_sdl1.c'
s = p.read_text(encoding='utf-8')

old_include = '''#include <stdio.h>\n#include <stdlib.h>\n'''
new_include = '''#include <stdio.h>\n#include <stdlib.h>\n#include <sys/time.h>\n'''
if s.count(old_include) != 1:
    raise SystemExit('A6_PERF_P1_STAGE_FAIL include anchor count=%d' % s.count(old_include))
s = s.replace(old_include, new_include, 1)

old_defs = '''#define SDL_SWSURFACE 0x00000000u\n#define RG35XX_LCD_W 640\n#define RG35XX_LCD_H 480\n'''
new_defs = '''#define SDL_SWSURFACE 0x00000000u\n#define RG35XX_LCD_W 640\n#define RG35XX_LCD_H 480\n\n/* PERF-P1: cache nearest-neighbour source coordinates.  The old presenter\n * performed 64-bit division for every destination pixel on every frame.\n * RG35XX is ARMv5, so those divisions are especially expensive. */\nstatic int perf_map_sw = -1;\nstatic int perf_map_sh = -1;\nstatic int perf_map_dw = -1;\nstatic int perf_map_dh = -1;\nstatic int perf_map_ox = -1;\nstatic int perf_map_oy = -1;\nstatic int perf_xmap[RG35XX_LCD_W];\nstatic int perf_ymap[RG35XX_LCD_H];\nstatic unsigned long perf_frame_count;\nstatic unsigned long perf_start_ms;\n\nstatic unsigned long perf_now_ms(void) {\n    struct timeval tv;\n    gettimeofday(&tv, 0);\n    return (unsigned long)tv.tv_sec * 1000ul + (unsigned long)(tv.tv_usec / 1000);\n}\n'''
if s.count(old_defs) != 1:
    raise SystemExit('A6_PERF_P1_STAGE_FAIL defs anchor count=%d' % s.count(old_defs))
s = s.replace(old_defs, new_defs, 1)

start = s.index('JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_presentARGB')
end = s.index('\nJNIEXPORT void JNICALL Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay', start)
new_func = r'''JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_presentARGB(JNIEnv *env, jclass cls, jintArray pixels, jint width, jint height) {
    jint *src;
    jsize length;
    int dw, dh, ox, oy;
    int x, y;
    uint32_t black;
    (void)cls;

    if (!screen || !screen->pixels || !pixels) return 1;
    if (width <= 0 || height <= 0) return 2;
    length = (*env)->GetArrayLength(env, pixels);
    if ((long long)length < (long long)width * (long long)height) return 3;

    fit_geometry(width, height, &dw, &dh, &ox, &oy);
    if (dw <= 0 || dh <= 0) return 4;

    /* Geometry normally remains 240x320 -> 360x480 for this platform.
     * Rebuild lookup tables only when it actually changes. */
    if (width != perf_map_sw || height != perf_map_sh ||
        dw != perf_map_dw || dh != perf_map_dh || ox != perf_map_ox || oy != perf_map_oy) {
        for (x = 0; x < dw; ++x)
            perf_xmap[x] = (int)(((long long)x * width) / dw);
        for (y = 0; y < dh; ++y)
            perf_ymap[y] = (int)(((long long)y * height) / dh);

        /* Clear only when geometry changes. Content never writes outside the
         * aspect-fit rectangle, so the black side bars remain black. */
        black = SDL_MapRGB_p(screen->format, 0, 0, 0);
        for (y = 0; y < RG35XX_LCD_H; ++y) {
            uint32_t *row = (uint32_t *)((uint8_t *)screen->pixels + y * screen->pitch);
            for (x = 0; x < RG35XX_LCD_W; ++x) row[x] = black;
        }

        perf_map_sw = width;
        perf_map_sh = height;
        perf_map_dw = dw;
        perf_map_dh = dh;
        perf_map_ox = ox;
        perf_map_oy = oy;
    }

    src = (*env)->GetIntArrayElements(env, pixels, 0);
    if (!src) return 5;

    for (y = 0; y < dh; ++y) {
        int sy = perf_ymap[y];
        uint32_t *dst = (uint32_t *)((uint8_t *)screen->pixels + (oy + y) * screen->pitch) + ox;
        for (x = 0; x < dw; ++x) {
            int sx = perf_xmap[x];
            uint32_t argb = (uint32_t)src[sy * width + sx];
            dst[x] = SDL_MapRGB_p(screen->format,
                                  (uint8_t)(argb >> 16),
                                  (uint8_t)(argb >> 8),
                                  (uint8_t)argb);
        }
    }

    (*env)->ReleaseIntArrayElements(env, pixels, src, JNI_ABORT);
    if (SDL_Flip_p(screen) != 0) return 6;

    /* Very-low-overhead performance telemetry: one line every 300 presents. */
    ++perf_frame_count;
    if (perf_frame_count == 1) perf_start_ms = perf_now_ms();
    if ((perf_frame_count % 300ul) == 0ul) {
        unsigned long elapsed = perf_now_ms() - perf_start_ms;
        unsigned long fps100 = elapsed ? (perf_frame_count * 100000ul) / elapsed : 0ul;
        printf("RG35XX_PERF_P1_FRAME=%lu ELAPSED_MS=%lu FPS_X100=%lu\n",
               perf_frame_count, elapsed, fps100);
        fflush(stdout);
    }
    return 0;
}
'''
s = s[:start] + new_func + s[end:]

body = s[s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB'):s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay')]
if 'int sx = perf_xmap[x];' not in body or 'int sy = perf_ymap[y];' not in body:
    raise SystemExit('A6_PERF_P1_STAGE_FAIL cached map missing')
if body.count('((long long)x * width) / dw') != 1 or body.count('((long long)y * height) / dh') != 1:
    raise SystemExit('A6_PERF_P1_STAGE_FAIL unexpected division count')

p.write_text(s, encoding='utf-8')
print('A6_PERF_P1_VIDEO_STAGE=PASS')
print('A6_PERF_P1_OWNER=RG35XX_NATIVE_PRESENT_SCALER')
print('A6_PERF_P1_XY_MAP=CACHED_ON_GEOMETRY_CHANGE')
print('A6_PERF_P1_BLACK_CLEAR=GEOMETRY_CHANGE_ONLY')
print('A6_PERF_P1_PIXEL_FORMAT=UNCHANGED_SDL_MAPRGB')
print('A6_PERF_P1_SCALING=UNCHANGED_NEAREST_NEIGHBOR')
