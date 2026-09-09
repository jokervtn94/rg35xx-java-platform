#!/usr/bin/env python3
"""Add observability-only markers to the assembled Golden video implementation.

This overlay must not alter RGB565 framing, receiver synchronization, geometry,
scaling, buffering, or presentation semantics. It only appends a few first-use
and shutdown checkpoints to the same B4 early log used by the native core.
"""
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: b4_apply_video_observability.py <rg35xx_golden_video.c>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("B4 VIDEO OBS FAIL: %s marker count=%d" % (label, n))
    s = s.replace(old, new, 1)

once(
    '#include <errno.h>\n#include <pthread.h>',
    '#include <errno.h>\n#include <fcntl.h>\n#include <pthread.h>\n#include <stdarg.h>\n#include <stdio.h>',
    'headers')

once(
    '    unsigned cached_y;\n};',
    '    unsigned cached_y;\n\n    int obs_first_header;\n    int obs_first_publish;\n    int obs_first_present;\n};',
    'state flags')

once(
    'static struct rg35xx_golden_state g;\n',
    r'''static struct rg35xx_golden_state g;

#define RG35XX_B4_VIDEO_LOG "/mnt/mmc/freej2me-vc3-early.log"

static void rg35xx_b4_video_log(const char *fmt, ...)
{
    char line[768];
    int fd;
    int n;
    va_list ap;
    va_start(ap, fmt);
    n = vsnprintf(line, sizeof(line), fmt, ap);
    va_end(ap);
    if(n < 0) return;
    if(n >= (int)sizeof(line)) n = (int)sizeof(line) - 1;
    if(n == 0 || line[n - 1] != '\n')
    {
        if(n < (int)sizeof(line) - 1) line[n++] = '\n';
    }
    fd = open(RG35XX_B4_VIDEO_LOG, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if(fd < 0) return;
    (void)write(fd, line, (size_t)n);
    (void)fsync(fd);
    close(fd);
}
''',
    'video logger helper')

once(
    '    pthread_mutex_unlock(&g.mutex);\n}\n\nstatic void *receiver_main',
    '    pthread_mutex_unlock(&g.mutex);\n\n    if(!g.obs_first_publish)\n    {\n        g.obs_first_publish = 1;\n        rg35xx_b4_video_log("B4 FIRST_FRAME_PUBLISH generation=%lu src=%ux%u rot=%u",\n                            g.generation, w, h, rot);\n    }\n}\n\nstatic void *receiver_main',
    'first publish')

once(
    '        if(!read_header_resync(header, &w, &h, &rotation)) break;\n\n        pixels = (size_t)w * (size_t)h;',
    '        if(!read_header_resync(header, &w, &h, &rotation)) break;\n\n        pixels = (size_t)w * (size_t)h;\n        if(!g.obs_first_header)\n        {\n            g.obs_first_header = 1;\n            rg35xx_b4_video_log("B4 FIRST_FRAME_HEADER src=%ux%u rot=%u payload=%lu",\n                                w, h, rotation, (unsigned long)(pixels * 2u));\n        }',
    'first header')

once(
    'void rg35xx_golden_video_deinit(void)\n{\n    rg35xx_golden_video_stop();',
    'void rg35xx_golden_video_deinit(void)\n{\n    rg35xx_b4_video_log("B4 VIDEO_DEINIT generation=%lu presented=%lu",\n                        g.generation, g.presented_generation);\n    rg35xx_golden_video_stop();',
    'deinit summary')

once(
    '    if(geometry_cb) geometry_cb(g.output_width, g.output_height);\n    video_cb(g.canvas, g.output_width, g.output_height,\n             (size_t)g.output_width * sizeof(uint16_t));\n    g.presented_generation = generation;',
    '    if(!g.obs_first_present)\n    {\n        g.obs_first_present = 1;\n        rg35xx_b4_video_log("B4 FIRST_PRESENT generation=%lu src=%ux%u dst=%ux%u x=%u y=%u output=%ux%u",\n                            generation, g.snapshot.width, g.snapshot.height,\n                            g.cached_dst_w, g.cached_dst_h, g.cached_x, g.cached_y,\n                            g.output_width, g.output_height);\n    }\n\n    if(geometry_cb) geometry_cb(g.output_width, g.output_height);\n    video_cb(g.canvas, g.output_width, g.output_height,\n             (size_t)g.output_width * sizeof(uint16_t));\n    g.presented_generation = generation;',
    'first present')

required = (
    'B4 FIRST_FRAME_HEADER',
    'B4 FIRST_FRAME_PUBLISH',
    'B4 FIRST_PRESENT',
    'B4 VIDEO_DEINIT',
    'RG35XX_B4_VIDEO_LOG',
)
for token in required:
    if token not in s:
        raise SystemExit("B4 VIDEO OBS FAIL: missing token: " + token)

# The overlay is observability-only: reject accidental experiment markers.
for forbidden in ('RG35XX-PNG-COMPAT', 'RG35XX-CV:', 'RG35XX-MediaWarmup'):
    if forbidden in s:
        raise SystemExit("B4 VIDEO OBS FAIL: unadmitted feature present: " + forbidden)

if s == orig:
    raise SystemExit("B4 VIDEO OBS FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("B4 VIDEO OBS PASS:", p)
