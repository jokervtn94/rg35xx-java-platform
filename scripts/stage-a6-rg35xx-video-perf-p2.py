#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-video-perf-p2.py <repo-root>')
root = Path(sys.argv[1]).resolve()
p = root / 'adapter/native/rg35xx_video_sdl1.c'
s = p.read_text(encoding='utf-8')

# PERF-P2 is intentionally layered on the proven PERF-P1 source transformation.
if 'static int perf_xmap[RG35XX_LCD_W];' not in s:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL PERF-P1 xmap missing')
if 'RG35XX_PERF_P1_FRAME=' not in s:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL PERF-P1 telemetry missing')

anchor = '''typedef struct SDL_Surface {\n    uint32_t flags;\n    void *format;\n    int w, h;\n    uint16_t pitch;\n    void *pixels;\n} SDL_Surface;\n'''
compat = '''/* SDL 1.2 public SDL_PixelFormat layout.  This adapter intentionally avoids\n * depending on SDL development headers on the target/toolchain. */\ntypedef struct RG35XX_SDL_PixelFormat {\n    void *palette;\n    uint8_t BitsPerPixel;\n    uint8_t BytesPerPixel;\n    uint8_t Rloss;\n    uint8_t Gloss;\n    uint8_t Bloss;\n    uint8_t Aloss;\n    uint8_t Rshift;\n    uint8_t Gshift;\n    uint8_t Bshift;\n    uint8_t Ashift;\n    uint32_t Rmask;\n    uint32_t Gmask;\n    uint32_t Bmask;\n    uint32_t Amask;\n    uint32_t colorkey;\n    uint8_t alpha;\n} RG35XX_SDL_PixelFormat;\n\ntypedef struct SDL_Surface {\n    uint32_t flags;\n    void *format;\n    int w, h;\n    uint16_t pitch;\n    void *pixels;\n} SDL_Surface;\n'''
if s.count(anchor) != 1:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL surface anchor count=%d' % s.count(anchor))
s = s.replace(anchor, compat, 1)

global_anchor = '''static unsigned long perf_frame_count;\nstatic unsigned long perf_start_ms;\n'''
global_repl = '''static unsigned long perf_frame_count;\nstatic unsigned long perf_start_ms;\n\n/* PERF-P2: SDL_MapRGB in SDL 1.2 is a small function, but calling it once for\n * every scaled destination pixel costs heavily on ARMv5. Cache the public\n * true-colour format fields once and perform the exact SDL_MapRGB expression\n * inline. Unsupported/paletted formats keep the PERF-P1 SDL_MapRGB fallback. */\nstatic int perf2_fast_rgb;\nstatic uint8_t perf2_rloss, perf2_gloss, perf2_bloss;\nstatic uint8_t perf2_rshift, perf2_gshift, perf2_bshift;\nstatic uint32_t perf2_amask;\n'''
if s.count(global_anchor) != 1:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL global anchor count=%d' % s.count(global_anchor))
s = s.replace(global_anchor, global_repl, 1)

init_anchor = '''    if (screen->w != RG35XX_LCD_W || screen->h != RG35XX_LCD_H) return 121;\n    return 0;\n}\n'''
init_repl = '''    if (screen->w != RG35XX_LCD_W || screen->h != RG35XX_LCD_H) return 121;\n\n    {\n        RG35XX_SDL_PixelFormat *fmt = (RG35XX_SDL_PixelFormat *)screen->format;\n        perf2_fast_rgb = 0;\n        if (fmt && fmt->palette == 0 && fmt->BitsPerPixel == 32 && fmt->BytesPerPixel == 4) {\n            perf2_rloss = fmt->Rloss;\n            perf2_gloss = fmt->Gloss;\n            perf2_bloss = fmt->Bloss;\n            perf2_rshift = fmt->Rshift;\n            perf2_gshift = fmt->Gshift;\n            perf2_bshift = fmt->Bshift;\n            perf2_amask = fmt->Amask;\n            perf2_fast_rgb = 1;\n            printf("RG35XX_PERF_P2_PIXEL_PACK=FAST BPP=%u BYTES=%u RMASK=%08lx GMASK=%08lx BMASK=%08lx AMASK=%08lx\\n",\n                   (unsigned)fmt->BitsPerPixel, (unsigned)fmt->BytesPerPixel,\n                   (unsigned long)fmt->Rmask, (unsigned long)fmt->Gmask,\n                   (unsigned long)fmt->Bmask, (unsigned long)fmt->Amask);\n        } else {\n            printf("RG35XX_PERF_P2_PIXEL_PACK=SDL_MAPRGB_FALLBACK\\n");\n        }\n        fflush(stdout);\n    }\n    return 0;\n}\n'''
if s.count(init_anchor) != 1:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL init anchor count=%d' % s.count(init_anchor))
s = s.replace(init_anchor, init_repl, 1)

old_loop = '''    for (y = 0; y < dh; ++y) {\n        int sy = perf_ymap[y];\n        uint32_t *dst = (uint32_t *)((uint8_t *)screen->pixels + (oy + y) * screen->pitch) + ox;\n        for (x = 0; x < dw; ++x) {\n            int sx = perf_xmap[x];\n            uint32_t argb = (uint32_t)src[sy * width + sx];\n            dst[x] = SDL_MapRGB_p(screen->format,\n                                  (uint8_t)(argb >> 16),\n                                  (uint8_t)(argb >> 8),\n                                  (uint8_t)argb);\n        }\n    }\n'''
new_loop = '''    if (perf2_fast_rgb) {\n        for (y = 0; y < dh; ++y) {\n            int sy = perf_ymap[y];\n            uint32_t *dst = (uint32_t *)((uint8_t *)screen->pixels + (oy + y) * screen->pitch) + ox;\n            for (x = 0; x < dw; ++x) {\n                int sx = perf_xmap[x];\n                uint32_t argb = (uint32_t)src[sy * width + sx];\n                uint32_t r = (argb >> 16) & 0xffu;\n                uint32_t g = (argb >> 8) & 0xffu;\n                uint32_t b = argb & 0xffu;\n                dst[x] = ((r >> perf2_rloss) << perf2_rshift)\n                       | ((g >> perf2_gloss) << perf2_gshift)\n                       | ((b >> perf2_bloss) << perf2_bshift)\n                       | perf2_amask;\n            }\n        }\n    } else {\n        for (y = 0; y < dh; ++y) {\n            int sy = perf_ymap[y];\n            uint32_t *dst = (uint32_t *)((uint8_t *)screen->pixels + (oy + y) * screen->pitch) + ox;\n            for (x = 0; x < dw; ++x) {\n                int sx = perf_xmap[x];\n                uint32_t argb = (uint32_t)src[sy * width + sx];\n                dst[x] = SDL_MapRGB_p(screen->format,\n                                      (uint8_t)(argb >> 16),\n                                      (uint8_t)(argb >> 8),\n                                      (uint8_t)argb);\n            }\n        }\n    }\n'''
if s.count(old_loop) != 1:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL PERF-P1 loop anchor count=%d' % s.count(old_loop))
s = s.replace(old_loop, new_loop, 1)

s = s.replace('RG35XX_PERF_P1_FRAME=', 'RG35XX_PERF_P2_FRAME=')

# Fail-closed source gates. There are exactly two remaining SDL_MapRGB uses in
# presentARGB: one black-map call on geometry rebuild, and one pixel fallback.
body = s[s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB'):s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay')]
if 'if (perf2_fast_rgb)' not in body:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL fast branch missing')
if body.count('SDL_MapRGB_p(screen->format') != 2:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL expected black-map+fallback MapRGB calls=2, got %d' % body.count('SDL_MapRGB_p(screen->format')))
if 'perf2_amask' not in body:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL exact opaque SDL_MapRGB Amask semantics missing')
if 'RG35XX_PERF_P2_FRAME=' not in body:
    raise SystemExit('A6_PERF_P2_STAGE_FAIL telemetry rename missing')

p.write_text(s, encoding='utf-8')
print('A6_PERF_P2_VIDEO_STAGE=PASS')
print('A6_PERF_P2_OWNER=RG35XX_NATIVE_PER_PIXEL_SDL_MAPRGB_CALL')
print('A6_PERF_P2_FAST_FORMAT=TRUECOLOR_32BPP_4BYTE_NONPALETTED')
print('A6_PERF_P2_MAPRGB_SEMANTICS=SDL12_RLOSS_SHIFT_PLUS_AMASK')
print('A6_PERF_P2_FALLBACK=SDL_MAPRGB')
