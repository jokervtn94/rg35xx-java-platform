#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-video-perf-p3.py <repo-root>')
root = Path(sys.argv[1]).resolve()
p = root / 'adapter/native/rg35xx_video_sdl1.c'
s = p.read_text(encoding='utf-8')

# PERF-P3 layers strictly on PERF-P2.
if 'RG35XX_PERF_P2_PIXEL_PACK=FAST' not in s:
    raise SystemExit('A6_PERF_P3_STAGE_FAIL PERF-P2 fast pack missing')
if 'RG35XX_PERF_P2_FRAME=' not in s:
    raise SystemExit('A6_PERF_P3_STAGE_FAIL PERF-P2 telemetry missing')

# memcpy is used only for duplicating already-packed destination rows.
inc = '#include <sys/time.h>\n'
if s.count(inc) != 1:
    raise SystemExit('A6_PERF_P3_STAGE_FAIL sys/time include anchor count=%d' % s.count(inc))
s = s.replace(inc, inc + '#include <string.h>\n', 1)

global_anchor = '''static uint32_t perf2_amask;\n'''
global_repl = '''static uint32_t perf2_amask;\n\n/* PERF-P3: exact device geometry is 240x320 -> 360x480 (3:2).  PERF-P2\n * still packs each of 172800 destination pixels independently.  For 3:2 NN\n * scaling, pack each of the 76800 source pixels once, expand each source-pair\n * to three destination pixels, and duplicate every even source row by memcpy. */\nstatic uint32_t perf3_row[360];\nstatic int perf3_announced;\n'''
if s.count(global_anchor) != 1:
    raise SystemExit('A6_PERF_P3_STAGE_FAIL global anchor count=%d' % s.count(global_anchor))
s = s.replace(global_anchor, global_repl, 1)

old = '''    if (perf2_fast_rgb) {\n        for (y = 0; y < dh; ++y) {\n            int sy = perf_ymap[y];\n            uint32_t *dst = (uint32_t *)((uint8_t *)screen->pixels + (oy + y) * screen->pitch) + ox;\n            for (x = 0; x < dw; ++x) {\n                int sx = perf_xmap[x];\n                uint32_t argb = (uint32_t)src[sy * width + sx];\n                uint32_t r = (argb >> 16) & 0xffu;\n                uint32_t g = (argb >> 8) & 0xffu;\n                uint32_t b = argb & 0xffu;\n                dst[x] = ((r >> perf2_rloss) << perf2_rshift)\n                       | ((g >> perf2_gloss) << perf2_gshift)\n                       | ((b >> perf2_bloss) << perf2_bshift)\n                       | perf2_amask;\n            }\n        }\n    } else {\n'''
new = '''    if (perf2_fast_rgb && width == 240 && height == 320 && dw == 360 && dh == 480) {\n        if (!perf3_announced) {\n            printf("RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480\\n");\n            fflush(stdout);\n            perf3_announced = 1;\n        }\n        for (y = 0; y < 320; ++y) {\n            int srcbase = y * 240;\n            int dx = 0;\n            int dy = (y >> 1) * 3 + ((y & 1) ? 2 : 0);\n            uint32_t *dst0;\n            for (x = 0; x < 240; x += 2) {\n                uint32_t a0 = (uint32_t)src[srcbase + x];\n                uint32_t a1 = (uint32_t)src[srcbase + x + 1];\n                uint32_t r0 = (a0 >> 16) & 0xffu;\n                uint32_t g0 = (a0 >> 8) & 0xffu;\n                uint32_t b0 = a0 & 0xffu;\n                uint32_t r1 = (a1 >> 16) & 0xffu;\n                uint32_t g1 = (a1 >> 8) & 0xffu;\n                uint32_t b1 = a1 & 0xffu;\n                uint32_t p0 = ((r0 >> perf2_rloss) << perf2_rshift)\n                            | ((g0 >> perf2_gloss) << perf2_gshift)\n                            | ((b0 >> perf2_bloss) << perf2_bshift)\n                            | perf2_amask;\n                uint32_t p1 = ((r1 >> perf2_rloss) << perf2_rshift)\n                            | ((g1 >> perf2_gloss) << perf2_gshift)\n                            | ((b1 >> perf2_bloss) << perf2_bshift)\n                            | perf2_amask;\n                perf3_row[dx++] = p0;\n                perf3_row[dx++] = p0;\n                perf3_row[dx++] = p1;\n            }\n            dst0 = (uint32_t *)((uint8_t *)screen->pixels + (oy + dy) * screen->pitch) + ox;\n            memcpy(dst0, perf3_row, 360u * sizeof(uint32_t));\n            if ((y & 1) == 0) {\n                uint32_t *dst1 = (uint32_t *)((uint8_t *)screen->pixels + (oy + dy + 1) * screen->pitch) + ox;\n                memcpy(dst1, perf3_row, 360u * sizeof(uint32_t));\n            }\n        }\n    } else if (perf2_fast_rgb) {\n        /* Generic true-colour fallback remains PERF-P2. */\n        for (y = 0; y < dh; ++y) {\n            int sy = perf_ymap[y];\n            uint32_t *dst = (uint32_t *)((uint8_t *)screen->pixels + (oy + y) * screen->pitch) + ox;\n            for (x = 0; x < dw; ++x) {\n                int sx = perf_xmap[x];\n                uint32_t argb = (uint32_t)src[sy * width + sx];\n                uint32_t r = (argb >> 16) & 0xffu;\n                uint32_t g = (argb >> 8) & 0xffu;\n                uint32_t b = argb & 0xffu;\n                dst[x] = ((r >> perf2_rloss) << perf2_rshift)\n                       | ((g >> perf2_gloss) << perf2_gshift)\n                       | ((b >> perf2_bloss) << perf2_bshift)\n                       | perf2_amask;\n            }\n        }\n    } else {\n'''
if s.count(old) != 1:
    raise SystemExit('A6_PERF_P3_STAGE_FAIL PERF-P2 fast loop anchor count=%d' % s.count(old))
s = s.replace(old, new, 1)
s = s.replace('RG35XX_PERF_P2_FRAME=', 'RG35XX_PERF_P3_FRAME=')

body = s[s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB'):s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay')]
required = [
    'width == 240 && height == 320 && dw == 360 && dh == 480',
    'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480',
    'perf3_row[dx++] = p0;',
    'perf3_row[dx++] = p1;',
    'memcpy(dst0, perf3_row, 360u * sizeof(uint32_t));',
    'else if (perf2_fast_rgb)',
    'RG35XX_PERF_P3_FRAME='
]
for r in required:
    if r not in body:
        raise SystemExit('A6_PERF_P3_STAGE_FAIL missing '+r)
# P1 coordinate divisions remain map-rebuild only; P3 fixed path adds none.
if body.count('((long long)x * width) / dw') != 1 or body.count('((long long)y * height) / dh') != 1:
    raise SystemExit('A6_PERF_P3_STAGE_FAIL coordinate division regression')
# Keep black-map + generic fallback only.
if body.count('SDL_MapRGB_p(screen->format') != 2:
    raise SystemExit('A6_PERF_P3_STAGE_FAIL MapRGB source count=%d' % body.count('SDL_MapRGB_p(screen->format')))

p.write_text(s, encoding='utf-8')
print('A6_PERF_P3_VIDEO_STAGE=PASS')
print('A6_PERF_P3_OWNER=RG35XX_3_TO_2_SCALER_DESTINATION_PIXEL_OVERWORK')
print('A6_PERF_P3_EXACT_GEOMETRY=240x320_TO_360x480')
print('A6_PERF_P3_SOURCE_PACKS_PER_FRAME=76800')
print('A6_PERF_P3_OLD_DEST_PACKS_PER_FRAME=172800')
print('A6_PERF_P3_GENERIC_FALLBACK=PERF_P2')
