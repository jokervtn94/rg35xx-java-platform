#!/usr/bin/env python3
"""Integrate the Golden receiver-thread video transport into pinned libretro core.

Only video ownership is changed here. Input/config/game-load command semantics stay
on the original core thread. The receiver is intentionally started only after all
variable-length boot payloads have been sent, preventing its 5-byte frame request
from interleaving inside a path/settings payload.
"""
import pathlib
import re
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: g1_apply_native_overlay.py <src/libretro/freej2me_libretro.c>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("G1 NATIVE OVERLAY FAIL: %s marker count=%d" % (label, n))
    s = s.replace(old, new, 1)

once(
    '#include "freej2me_libretro.h"\n',
    '#include "freej2me_libretro.h"\n#include "rg35xx/golden/rg35xx_golden_video.h"\n',
    "golden include")

# Golden canvas symbol size in the proven core is 0x96000 = 640*480*2.
insert_after = 'float normal_throttle_rate = DEFAULT_FPS;\n'
helpers = r'''

#define RG35XX_G1_OUTPUT_WIDTH  640u
#define RG35XX_G1_OUTPUT_HEIGHT 480u

static void rg35xx_g1_video_cb(const void *data, unsigned width,
                               unsigned height, size_t pitch)
{
    Video(data, width, height, pitch);
}

static void rg35xx_g1_geometry_cb(unsigned width, unsigned height)
{
    static unsigned last_w = 0;
    static unsigned last_h = 0;
    if(width == last_w && height == last_h) return;
    Geometry.base_width = width;
    Geometry.base_height = height;
    Geometry.max_width = RG35XX_G1_OUTPUT_WIDTH;
    Geometry.max_height = RG35XX_G1_OUTPUT_HEIGHT;
    Geometry.aspect_ratio = (float)width / (float)height;
    Environ(RETRO_ENVIRONMENT_SET_GEOMETRY, &Geometry);
    last_w = width;
    last_h = height;
}
'''
once(insert_after, insert_after + helpers, "G1 helpers")

# retro_run must no longer request a frame itself. The native receiver thread is
# the sole owner of request/read/publish transactions.
pat_req = re.compile(
    r'\n\t\t/\* request frame \*/\n\t\tif\(!frameRequested\).*?\n\t\t/\* handle joypad \*/',
    re.S,
)
ms = list(pat_req.finditer(s))
if len(ms) != 1:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: frame request block count=%d" % len(ms))
s = s[:ms[0].start()] + '\n\n\t\t/* frame requests are owned by RG35XX receiver thread */\n\n\t\t/* handle joypad */' + s[ms[0].end():]

# Remove synchronous stdout frame parsing + old 32-bit frame conversion/pointer
# drawing. Keep the isRunning() scope and refresh logical source geometry for
# pointer/touch coordinate calculations performed on subsequent ticks.
pat_rx = re.compile(
    r'\n\t\t/\*\n\t\t \* grab frame.*?\n\t}\n\n\t/\* send frame to libretro irrespective of FreeJ2ME running \(for error messages\) \*/',
    re.S,
)
ms = list(pat_rx.finditer(s))
if len(ms) != 1:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: synchronous receiver block count=%d" % len(ms))
replacement = r'''

        /* G1 receiver owns stdout. Only consume already-published logical
         * geometry here; never block retro_run waiting for Java. */
        {
            unsigned sw, sh, sr;
            if(rg35xx_golden_video_source_geometry(&sw, &sh, &sr))
            {
                frameWidth = (sr == 1u || sr == 3u) ? sh : sw;
                frameHeight = (sr == 1u || sr == 3u) ? sw : sh;
                frameSize = frameWidth * frameHeight;
            }
        }
    }

    /* send frame to libretro irrespective of FreeJ2ME running (for error messages) */'''
s = s[:ms[0].start()] + replacement + s[ms[0].end():]

once(
    '\tVideo(frame, frameWidth, frameHeight, sizeof(unsigned int) * frameWidth);\n',
    '\tif(!rg35xx_golden_video_present(rg35xx_g1_video_cb, rg35xx_g1_geometry_cb))\n'
    '\t\tVideo(NULL, RG35XX_G1_OUTPUT_WIDTH, RG35XX_G1_OUTPUT_HEIGHT, RG35XX_G1_OUTPUT_WIDTH * sizeof(uint16_t));\n',
    "frontend present")

# Old processed-frame acknowledgement belongs to the synchronous protocol.
ack = ('\n\tjavaRequestFrame[3] = 1; // Indicate that frame was processed\n'
       '\twrite_to_pipe(pWrite[1], javaRequestFrame, 5);\n')
if s.count(ack) != 1:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: old frame ack count=%d" % s.count(ack))
s = s.replace(ack, '\n', 1)

# Start receiver only after save path, ROM path, config payload and startup event
# have all been serialized by the core thread. This avoids command/payload
# interleaving on Java stdin.
start_marker = ('\twrite_to_pipe(pWrite[1], startupevent, 5);\n\n'
                '\tlog_fn(RETRO_LOG_INFO, "Booting up...\\n");')
start_new = ('\twrite_to_pipe(pWrite[1], startupevent, 5);\n\n'
             '\tif(!rg35xx_golden_video_init(pRead[0], pWrite[1], RG35XX_G1_OUTPUT_WIDTH, RG35XX_G1_OUTPUT_HEIGHT) ||\n'
             '\t   !rg35xx_golden_video_start())\n'
             '\t{\n'
             '\t\tlog_fn(RETRO_LOG_ERROR, "RG35XX G1 video receiver failed to start.\\n");\n'
             '\t\treturn false;\n'
             '\t}\n\n'
             '\tlog_fn(RETRO_LOG_INFO, "Booting up...\\n");')
once(start_marker, start_new, "receiver start after boot payloads")

# Stop the receiver before killing/closing the Java process and its pipes.
once(
    'void retro_deinit(void)\n{\n\tif(isRunning())',
    'void retro_deinit(void)\n{\n\trg35xx_golden_video_deinit();\n\tif(isRunning())',
    "receiver deinit ordering")

# Physical RG35XX boundary is fixed RGB565 640x480. Logical MIDlet size remains
# in the frame header and is Smart-Fit in the helper.
old_av = ('\tinfo->geometry.base_width   = BASE_WIDTH;\n'
          '\tinfo->geometry.base_height  = BASE_HEIGHT;\n'
          '\tinfo->geometry.max_width    = MAX_WIDTH;\n'
          '\tinfo->geometry.max_height   = MAX_HEIGHT;\n'
          '\tinfo->geometry.aspect_ratio = ((float)BASE_WIDTH) / ((float)BASE_HEIGHT);')
new_av = ('\tinfo->geometry.base_width   = RG35XX_G1_OUTPUT_WIDTH;\n'
          '\tinfo->geometry.base_height  = RG35XX_G1_OUTPUT_HEIGHT;\n'
          '\tinfo->geometry.max_width    = RG35XX_G1_OUTPUT_WIDTH;\n'
          '\tinfo->geometry.max_height   = RG35XX_G1_OUTPUT_HEIGHT;\n'
          '\tinfo->geometry.aspect_ratio = 4.0f / 3.0f;')
once(old_av, new_av, "fixed RG35XX geometry")
once(
    '\tint pixelformat = RETRO_PIXEL_FORMAT_XRGB8888;\n',
    '\tint pixelformat = RETRO_PIXEL_FORMAT_RGB565;\n',
    "RGB565 frontend boundary")

for forbidden in (
    'status = read_from_pipe(pRead[0], frameHeader, 15)',
    'frameBufferSize = frameSize * 3',
    'Video(frame, frameWidth, frameHeight, sizeof(unsigned int) * frameWidth)',
    'javaRequestFrame[3] = 1',
):
    if forbidden in s:
        raise SystemExit("G1 NATIVE OVERLAY FAIL: synchronous video token remains: " + forbidden)

for required in (
    'rg35xx_golden_video_start()',
    'rg35xx_golden_video_present(',
    'RETRO_PIXEL_FORMAT_RGB565',
    'RG35XX_G1_OUTPUT_WIDTH  640u',
    'rg35xx_golden_video_deinit();',
):
    if required not in s:
        raise SystemExit("G1 NATIVE OVERLAY FAIL: required token missing: " + required)

if s == orig:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("G1 NATIVE OVERLAY PASS:", p)
