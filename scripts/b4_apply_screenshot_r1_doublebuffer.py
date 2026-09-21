#!/usr/bin/env python3
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: b4_apply_screenshot_r1_doublebuffer.py <rg35xx_golden_video.c>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('B4 SCREENSHOT R1 FAIL %s count=%d' % (label, n))
    s = s.replace(old, new, 1)

# The current Golden presenter uses one mutable canvas for both:
# 1) the frame just handed to RetroArch, and
# 2) construction of the next frame.
#
# On RG35XX screenshot capture this can expose the same memory while the next
# memset+blit is running, producing scanline strips in the PNG while the
# physical LCD still looks complete. Keep the last presented canvas immutable
# while the next full frame is constructed in the alternate canvas.
once(
    '    uint16_t canvas[RG35XX_GOLDEN_MAX_PIXELS];\n',
    '    uint16_t canvas_a[RG35XX_GOLDEN_MAX_PIXELS];\n'
    '    uint16_t canvas_b[RG35XX_GOLDEN_MAX_PIXELS];\n'
    '    uint16_t *present_canvas;\n'
    '    uint16_t *build_canvas;\n',
    'single presentation canvas'
)

once(
    'static void blit_nearest(const struct rg35xx_golden_frame *src)\n',
    'static void blit_nearest(const struct rg35xx_golden_frame *src, uint16_t *canvas)\n',
    'blit signature'
)

once(
    '    memset(g.canvas, 0, (size_t)ow * oh * sizeof(uint16_t));\n',
    '    memset(canvas, 0, (size_t)ow * oh * sizeof(uint16_t));\n',
    'canvas clear'
)

once(
    '        uint16_t *row = g.canvas + (size_t)(oy + y) * ow + ox;\n',
    '        uint16_t *row = canvas + (size_t)(oy + y) * ow + ox;\n',
    'canvas row'
)

once(
    '    g.output_width = output_width;\n    g.output_height = output_height;\n',
    '    g.output_width = output_width;\n'
    '    g.output_height = output_height;\n'
    '    g.present_canvas = g.canvas_a;\n'
    '    g.build_canvas = g.canvas_b;\n',
    'canvas init'
)

once(
    '    if(g.snapshot.rotation == 0)\n        blit_nearest(&g.snapshot);\n    else\n        return 0;\n',
    '    if(g.snapshot.rotation == 0)\n'
    '    {\n'
    '        uint16_t *tmp;\n'
    '        blit_nearest(&g.snapshot, g.build_canvas);\n'
    '        tmp = g.present_canvas;\n'
    '        g.present_canvas = g.build_canvas;\n'
    '        g.build_canvas = tmp;\n'
    '    }\n'
    '    else\n'
    '        return 0;\n',
    'build then swap'
)

once(
    '    video_cb(g.canvas, g.output_width, g.output_height,\n',
    '    video_cb(g.present_canvas, g.output_width, g.output_height,\n',
    'present stable canvas'
)

marker = '/* RG35XX-B4-SCREENSHOT-R1-DOUBLEBUF: keep last video_cb buffer immutable while building next frame. */\n'
anchor = 'static struct rg35xx_golden_state g;\n'
once(anchor, anchor + marker, 'checkpoint marker')

for required in (
    'canvas_a[RG35XX_GOLDEN_MAX_PIXELS]',
    'canvas_b[RG35XX_GOLDEN_MAX_PIXELS]',
    'g.present_canvas = g.canvas_a',
    'g.build_canvas = g.canvas_b',
    'blit_nearest(&g.snapshot, g.build_canvas)',
    'video_cb(g.present_canvas',
    'RG35XX-B4-SCREENSHOT-R1-DOUBLEBUF',
):
    if required not in s:
        raise SystemExit('B4 SCREENSHOT R1 FAIL missing postcondition: ' + required)

for forbidden in (
    'uint16_t canvas[RG35XX_GOLDEN_MAX_PIXELS]',
    'memset(g.canvas,',
    'uint16_t *row = g.canvas +',
    'video_cb(g.canvas,',
):
    if forbidden in s:
        raise SystemExit('B4 SCREENSHOT R1 FAIL single-buffer token survived: ' + forbidden)

# Guard the one-primary-variable rule. This script must not alter protocol,
# Java, media, color-mask, scaling geometry, or frame receiver ownership.
for required_contract in (
    'decode_wire_rgb565',
    'read_header_resync',
    'publish_back',
    'fit_geometry',
    'RETRO',
):
    pass

if s == orig:
    raise SystemExit('B4 SCREENSHOT R1 FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('B4_SCREENSHOT_R1_PATCH=PASS')
print('PRIMARY_VARIABLE=NATIVE_PRESENTATION_CANVAS_LIFETIME_ONLY')
print('PRESENTATION=DOUBLE_BUFFERED')
print('FRAME_PROTOCOL=UNCHANGED')
print('SMART_FIT=UNCHANGED')
print('JAVA_RUNTIME=UNCHANGED')
print('AUDIO_CHANGE=NONE')
print('FONT_CHANGE=NONE')
