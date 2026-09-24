#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-video-perf-p4.py <repo-root>')
root = Path(sys.argv[1]).resolve()
p = root / 'adapter/native/rg35xx_video_sdl1.c'
s = p.read_text(encoding='utf-8')

# PERF-P4 layers strictly on PERF-P3 real-device-proven geometry/scaling.
if 'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480' not in s:
    raise SystemExit('A6_PERF_P4_STAGE_FAIL PERF-P3 scaler missing')
if 'RG35XX_PERF_P3_FRAME=' not in s:
    raise SystemExit('A6_PERF_P4_STAGE_FAIL PERF-P3 telemetry missing')

old_globals = '''static uint32_t perf3_row[360];\nstatic int perf3_announced;\n'''
new_globals = '''static int perf4_announced;\n'''
if s.count(old_globals) != 1:
    raise SystemExit('A6_PERF_P4_STAGE_FAIL P3 globals anchor count=%d' % s.count(old_globals))
s = s.replace(old_globals, new_globals, 1)

old = '''    if (perf2_fast_rgb && width == 240 && height == 320 && dw == 360 && dh == 480) {\n        if (!perf3_announced) {\n            printf("RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480\\n");\n            fflush(stdout);\n            perf3_announced = 1;\n        }\n        for (y = 0; y < 320; ++y) {\n            int srcbase = y * 240;\n            int dx = 0;\n            int dy = (y >> 1) * 3 + ((y & 1) ? 2 : 0);\n            uint32_t *dst0;\n            for (x = 0; x < 240; x += 2) {\n                uint32_t a0 = (uint32_t)src[srcbase + x];\n                uint32_t a1 = (uint32_t)src[srcbase + x + 1];\n                uint32_t r0 = (a0 >> 16) & 0xffu;\n                uint32_t g0 = (a0 >> 8) & 0xffu;\n                uint32_t b0 = a0 & 0xffu;\n                uint32_t r1 = (a1 >> 16) & 0xffu;\n                uint32_t g1 = (a1 >> 8) & 0xffu;\n                uint32_t b1 = a1 & 0xffu;\n                uint32_t p0 = ((r0 >> perf2_rloss) << perf2_rshift)\n                            | ((g0 >> perf2_gloss) << perf2_gshift)\n                            | ((b0 >> perf2_bloss) << perf2_bshift)\n                            | perf2_amask;\n                uint32_t p1 = ((r1 >> perf2_rloss) << perf2_rshift)\n                            | ((g1 >> perf2_gloss) << perf2_gshift)\n                            | ((b1 >> perf2_bloss) << perf2_bshift)\n                            | perf2_amask;\n                perf3_row[dx++] = p0;\n                perf3_row[dx++] = p0;\n                perf3_row[dx++] = p1;\n            }\n            dst0 = (uint32_t *)((uint8_t *)screen->pixels + (oy + dy) * screen->pitch) + ox;\n            memcpy(dst0, perf3_row, 360u * sizeof(uint32_t));\n            if ((y & 1) == 0) {\n                uint32_t *dst1 = (uint32_t *)((uint8_t *)screen->pixels + (oy + dy + 1) * screen->pitch) + ox;\n                memcpy(dst1, perf3_row, 360u * sizeof(uint32_t));\n            }\n        }\n    } else if (perf2_fast_rgb) {\n'''
new = '''    if (perf2_fast_rgb && width == 240 && height == 320 && dw == 360 && dh == 480) {\n        if (!perf4_announced) {\n            printf("RG35XX_PERF_P4_SCALER=DIRECT_ROW_3_TO_2_240x320_TO_360x480\\n");\n            fflush(stdout);\n            perf4_announced = 1;\n        }\n        for (y = 0; y < 320; ++y) {\n            int srcbase = y * 240;\n            int dx = 0;\n            int dy = (y >> 1) * 3 + ((y & 1) ? 2 : 0);\n            uint32_t *dst0 = (uint32_t *)((uint8_t *)screen->pixels + (oy + dy) * screen->pitch) + ox;\n            for (x = 0; x < 240; x += 2) {\n                uint32_t a0 = (uint32_t)src[srcbase + x];\n                uint32_t a1 = (uint32_t)src[srcbase + x + 1];\n                uint32_t r0 = (a0 >> 16) & 0xffu;\n                uint32_t g0 = (a0 >> 8) & 0xffu;\n                uint32_t b0 = a0 & 0xffu;\n                uint32_t r1 = (a1 >> 16) & 0xffu;\n                uint32_t g1 = (a1 >> 8) & 0xffu;\n                uint32_t b1 = a1 & 0xffu;\n                uint32_t p0 = ((r0 >> perf2_rloss) << perf2_rshift)\n                            | ((g0 >> perf2_gloss) << perf2_gshift)\n                            | ((b0 >> perf2_bloss) << perf2_bshift)\n                            | perf2_amask;\n                uint32_t p1 = ((r1 >> perf2_rloss) << perf2_rshift)\n                            | ((g1 >> perf2_gloss) << perf2_gshift)\n                            | ((b1 >> perf2_bloss) << perf2_bshift)\n                            | perf2_amask;\n                dst0[dx++] = p0;\n                dst0[dx++] = p0;\n                dst0[dx++] = p1;\n            }\n            if ((y & 1) == 0) {\n                uint32_t *dst1 = (uint32_t *)((uint8_t *)screen->pixels + (oy + dy + 1) * screen->pitch) + ox;\n                memcpy(dst1, dst0, 360u * sizeof(uint32_t));\n            }\n        }\n    } else if (perf2_fast_rgb) {\n'''
if s.count(old) != 1:
    raise SystemExit('A6_PERF_P4_STAGE_FAIL P3 exact scaler anchor count=%d' % s.count(old))
s = s.replace(old, new, 1)
s = s.replace('RG35XX_PERF_P3_FRAME=', 'RG35XX_PERF_P4_FRAME=')

body = s[s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB'):s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay')]
required = [
    'width == 240 && height == 320 && dw == 360 && dh == 480',
    'RG35XX_PERF_P4_SCALER=DIRECT_ROW_3_TO_2_240x320_TO_360x480',
    'dst0[dx++] = p0;',
    'dst0[dx++] = p1;',
    'memcpy(dst1, dst0, 360u * sizeof(uint32_t));',
    'else if (perf2_fast_rgb)',
    'RG35XX_PERF_P4_FRAME='
]
for r in required:
    if r not in body:
        raise SystemExit('A6_PERF_P4_STAGE_FAIL missing '+r)
if 'perf3_row' in s:
    raise SystemExit('A6_PERF_P4_STAGE_FAIL P3 scratch row still present')
if body.count('memcpy(') != 1:
    raise SystemExit('A6_PERF_P4_STAGE_FAIL expected one vertical-row memcpy site, got %d' % body.count('memcpy('))
if body.count('((long long)x * width) / dw') != 1 or body.count('((long long)y * height) / dh') != 1:
    raise SystemExit('A6_PERF_P4_STAGE_FAIL coordinate division regression')
if body.count('SDL_MapRGB_p(screen->format') != 2:
    raise SystemExit("A6_PERF_P4_STAGE_FAIL MapRGB source count=%d" % body.count("SDL_MapRGB_p(screen->format"))

p.write_text(s, encoding='utf-8')
print('A6_PERF_P4_VIDEO_STAGE=PASS')
print('A6_PERF_P4_OWNER=RG35XX_P3_SCRATCH_ROW_COPY_OVERHEAD')
print('A6_PERF_P4_EXACT_GEOMETRY=240x320_TO_360x480')
print('A6_PERF_P4_P3_OUTPUT_WRITE_BYTES_PER_FRAME=1152000')
print('A6_PERF_P4_OUTPUT_WRITE_BYTES_PER_FRAME=691200')
print('A6_PERF_P4_OUTPUT_WRITE_REDUCTION_PERCENT=40')
print('A6_PERF_P4_GENERIC_FALLBACK=PERF_P2')
