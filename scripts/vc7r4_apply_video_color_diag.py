#!/usr/bin/env python3
import pathlib, sys

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

if 'RG35XX-VC7R4-COLOR-DIAG' in s:
    raise SystemExit('VC7R4 color diagnostic already applied')

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('VC7R4 COLOR DIAG FAIL: %s count=%d' % (label, n))
    s = s.replace(old, new, 1)

once('#include <errno.h>\n', '#include <errno.h>\n#include <stdio.h>\n', 'stdio include')

anchor = 'static struct rg35xx_golden_state g;\n'
helpers = r'''
/* RG35XX-VC7R4-COLOR-DIAG
 * Diagnostic-only final-stage probe. The accepted RGB565 transport and
 * Smart-Fit logic are left intact; we only log representative values and
 * overlay a small native-generated RGB565 reference strip after Smart-Fit.
 */
static FILE *rg35xx_vc7r4_log;
static unsigned rg35xx_vc7r4_rx_logged;
static unsigned rg35xx_vc7r4_present_logged;

static void rg35xx_vc7r4_open_log(void)
{
    if(!rg35xx_vc7r4_log)
    {
        rg35xx_vc7r4_log = fopen("/mnt/mmc/freej2me-vc7r4-color.log", "a");
        if(rg35xx_vc7r4_log)
        {
            fprintf(rg35xx_vc7r4_log,
                    "VC7R4 START RGB565 refs black=%04X white=%04X red=%04X green=%04X blue=%04X\n",
                    0x0000u, 0xFFFFu, 0xF800u, 0x07E0u, 0x001Fu);
            fflush(rg35xx_vc7r4_log);
        }
    }
}

static void rg35xx_vc7r4_log_rx(const unsigned char *wire,
                                const struct rg35xx_golden_frame *decoded,
                                size_t pixels, unsigned w, unsigned h)
{
    size_t i;
    if(rg35xx_vc7r4_rx_logged || !wire || !decoded || pixels == 0) return;
    rg35xx_vc7r4_rx_logged = 1;
    rg35xx_vc7r4_open_log();
    if(!rg35xx_vc7r4_log) return;
    fprintf(rg35xx_vc7r4_log, "VC7R4 RX src=%ux%u pixels=%lu wire16=", w, h, (unsigned long)pixels);
    for(i = 0; i < 16u && i < pixels * 2u; ++i) fprintf(rg35xx_vc7r4_log, "%02X", wire[i]);
    fprintf(rg35xx_vc7r4_log, " decoded8=");
    for(i = 0; i < 8u && i < pixels; ++i) fprintf(rg35xx_vc7r4_log, "%04X%s", decoded->pixels[i], i == 7u ? "" : ",");
    fprintf(rg35xx_vc7r4_log, "\n");
    fflush(rg35xx_vc7r4_log);
}

static void rg35xx_vc7r4_overlay_reference_strip(void)
{
    static const uint16_t refs[5] = { 0x0000u, 0xFFFFu, 0xF800u, 0x07E0u, 0x001Fu };
    unsigned x, y;
    unsigned h = g.output_height < 48u ? g.output_height : 48u;
    unsigned w = g.output_width;
    if(w == 0 || h == 0) return;
    for(y = 0; y < h; ++y)
    {
        uint16_t *row = g.canvas + (size_t)y * w;
        for(x = 0; x < w; ++x)
        {
            unsigned bar = (unsigned)(((unsigned long long)x * 5u) / w);
            if(bar > 4u) bar = 4u;
            row[x] = refs[bar];
        }
    }
}

static void rg35xx_vc7r4_log_present(size_t pitch)
{
    unsigned w = g.output_width, h = g.output_height;
    size_t center;
    if(rg35xx_vc7r4_present_logged || w == 0 || h == 0) return;
    rg35xx_vc7r4_present_logged = 1;
    rg35xx_vc7r4_open_log();
    if(!rg35xx_vc7r4_log) return;
    center = (size_t)(h / 2u) * w + (w / 2u);
    fprintf(rg35xx_vc7r4_log,
            "VC7R4 PRESENT output=%ux%u pitch=%lu sizeof_pixel=%lu samples tl=%04X x1=%04X center=%04X br=%04X\n",
            w, h, (unsigned long)pitch, (unsigned long)sizeof(uint16_t),
            g.canvas[0], w > 1u ? g.canvas[1] : g.canvas[0],
            g.canvas[center], g.canvas[(size_t)w * h - 1u]);
    fflush(rg35xx_vc7r4_log);
}

'''
once(anchor, anchor + helpers, 'helpers')

once('''        decode_wire_rgb565(g.back, g.wire_payload, pixels);\n        publish_back(w, h, rotation, header);''',
     '''        decode_wire_rgb565(g.back, g.wire_payload, pixels);\n        rg35xx_vc7r4_log_rx(g.wire_payload, g.back, pixels, w, h);\n        publish_back(w, h, rotation, header);''',
     'rx probe')

once('''    if(geometry_cb) geometry_cb(g.output_width, g.output_height);\n    video_cb(g.canvas, g.output_width, g.output_height,\n             (size_t)g.output_width * sizeof(uint16_t));''',
     '''    rg35xx_vc7r4_overlay_reference_strip();\n    if(geometry_cb) geometry_cb(g.output_width, g.output_height);\n    rg35xx_vc7r4_log_present((size_t)g.output_width * sizeof(uint16_t));\n    video_cb(g.canvas, g.output_width, g.output_height,\n             (size_t)g.output_width * sizeof(uint16_t));''',
     'final-stage strip')

# Anchor only to the unique lifecycle function entry. Internal teardown order can
# vary across assembled G1/B4 sources, but logging must close before state reset.
once('void rg35xx_golden_video_deinit(void)\n{\n',
     '''void rg35xx_golden_video_deinit(void)\n{\n    if(rg35xx_vc7r4_log)\n    {\n        fprintf(rg35xx_vc7r4_log, "VC7R4 STOP generations=%lu presented=%lu\\n", g.generation, g.presented_generation);\n        fclose(rg35xx_vc7r4_log);\n        rg35xx_vc7r4_log = NULL;\n    }\n''',
     'video deinit entry')

for req in ('RG35XX-VC7R4-COLOR-DIAG', '0xF800u', '0x07E0u', '0x001Fu',
            'rg35xx_vc7r4_log_rx', 'rg35xx_vc7r4_overlay_reference_strip',
            'video_cb(g.canvas', '(size_t)g.output_width * sizeof(uint16_t)',
            'VC7R4 STOP generations='):
    if req not in s:
        raise SystemExit('VC7R4 COLOR DIAG FAIL missing ' + req)
if s == orig:
    raise SystemExit('VC7R4 COLOR DIAG FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('VC7R4 COLOR DIAGNOSTIC OVERLAY=PASS')
print('REFERENCE_STRIP=BLACK,WHITE,RED,GREEN,BLUE')
print('LOG=/mnt/mmc/freej2me-vc7r4-color.log')
