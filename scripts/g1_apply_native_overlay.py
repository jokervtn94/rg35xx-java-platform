#!/usr/bin/env python3
"""Integrate the Golden RG35XX transport/runtime contract into pinned libretro core.

Video ownership is moved off retro_run() to a dedicated receiver thread. The
launcher is also restored to the device-proven absolute JamVM/headless contract.
The transform is fail-closed against pinned FreeJ2ME commit
13ec186903087156c145268f8706eecfaf9f1e50.
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

# ---------------------------------------------------------------------------
# Golden runtime launcher contract
# ---------------------------------------------------------------------------
once('#define NUM_ARGUMENTS 7\n', '#define NUM_ARGUMENTS 10\n', "argument count")

once(
    '#ifdef __linux__\nconst char *freej2meapp = "freej2me_plus-lr.jar";',
    '#ifdef __linux__\nconst char *freej2meapp = "freej2me-lr.jar";',
    "Golden Linux runtime JAR name")

once(
    '#include <stdarg.h>\n#include <unistd.h>\n#include <sys/wait.h>',
    '#include <stdarg.h>\n#include <unistd.h>\n#include <fcntl.h>\n#include <sys/wait.h>',
    "fcntl include")

old_params = '''#ifdef __linux__
\tparams[0] = strdup("java");
#elif _WIN32
\tparams[0] = strdup("javaw");
#endif
\tparams[1] = strdup("-jar");
\tparams[2] = strdup(supported_encodings[characterEncoding]);
\tparams[3] = strdup(freej2meapp);
\tparams[4] = strdup(resArg[0]);
\tparams[5] = strdup(resArg[1]);
\tparams[6] = NULL; // Null-terminate the array
'''
new_params = '''#ifdef __linux__
\tparams[0] = strdup("/mnt/mmc/CFW/java/bin/jamvm");
\tparams[1] = strdup(supported_encodings[characterEncoding]);
\tparams[2] = strdup("-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit");
\tparams[3] = strdup("-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment");
\tparams[4] = strdup("-Djava.awt.headless=true");
\tparams[5] = strdup("-jar");
\tparams[6] = strdup(freej2meapp);
\tparams[7] = strdup(resArg[0]);
\tparams[8] = strdup(resArg[1]);
\tparams[9] = NULL; // Null-terminate the array
#elif _WIN32
\tparams[0] = strdup("javaw");
\tparams[1] = strdup("-jar");
\tparams[2] = strdup(supported_encodings[characterEncoding]);
\tparams[3] = strdup(freej2meapp);
\tparams[4] = strdup(resArg[0]);
\tparams[5] = strdup(resArg[1]);
\tparams[6] = NULL;
#endif
'''
once(old_params, new_params, "Golden JamVM argv")

old_exec = '''\t\tdup2(pWrite[0], fd_stdin);  /* read from parent pWrite */
\t\tdup2(pRead[1], fd_stdout);  /* write to parent pRead */

\t\tclose(pWrite[1]);
\t\tclose(pRead[0]);

\t\tchdir(systemPath);

\t\texecvp(cmd, params);

\t\t/* execvp failure! */
\t\tretro_deinit();
'''
new_exec = '''\t\tdup2(pWrite[0], fd_stdin);  /* read from parent pWrite */
\t\tdup2(pRead[1], fd_stdout);  /* binary stdout -> parent pRead */

\t\tclose(pWrite[1]);
\t\tclose(pRead[0]);

\t\t/* Golden device diagnostics: stderr only. Never redirect stdout because
\t\t * stdout is the framed RGB565 protocol. */
\t\t{
\t\t\tint errfd = open("/mnt/mmc/freej2me-java-error.log", O_WRONLY | O_CREAT | O_APPEND, 0644);
\t\t\tif(errfd >= 0)
\t\t\t{
\t\t\t\tdup2(errfd, 2);
\t\t\t\tif(errfd != 2) close(errfd);
\t\t\t}
\t\t}

\t\tchdir(systemPath);

\t\texecv(cmd, params);

\t\t/* execv failure! */
\t\t_exit(127);
'''
once(old_exec, new_exec, "absolute JamVM exec")

# Linux must use the Golden short runtime name. The Windows branch may retain
# the upstream plus-name because this rebuild targets RG35XX/Linux only.
if '#ifdef __linux__\nconst char *freej2meapp = "freej2me-lr.jar";' not in s:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: Golden Linux JAR name missing")

# ---------------------------------------------------------------------------
# Golden receiver-thread video contract
# ---------------------------------------------------------------------------
once(
    '#include "freej2me_libretro.h"\n',
    '#include "freej2me_libretro.h"\n#include "rg35xx/golden/rg35xx_golden_video.h"\n',
    "golden include")

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

pat_req = re.compile(
    r'\n\t\t/\* request frame \*/\n\t\tif\(!frameRequested\).*?\n\t\t/\* handle joypad \*/',
    re.S,
)
ms = list(pat_req.finditer(s))
if len(ms) != 1:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: frame request block count=%d" % len(ms))
s = s[:ms[0].start()] + '\n\n\t\t/* frame requests are owned by RG35XX receiver thread */\n\n\t\t/* handle joypad */' + s[ms[0].end():]

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

ack = ('\n\tjavaRequestFrame[3] = 1; // Indicate that frame was processed\n'
       '\twrite_to_pipe(pWrite[1], javaRequestFrame, 5);\n')
if s.count(ack) != 1:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: old frame ack count=%d" % s.count(ack))
s = s.replace(ack, '\n', 1)

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

once(
    'void retro_deinit(void)\n{\n\tif(isRunning())',
    'void retro_deinit(void)\n{\n\trg35xx_golden_video_deinit();\n\tif(isRunning())',
    "receiver deinit ordering")

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
    'execvp(cmd, params)',
    'params[0] = strdup("java")',
):
    if forbidden in s:
        raise SystemExit("G1 NATIVE OVERLAY FAIL: forbidden legacy token remains: " + forbidden)

for required in (
    'rg35xx_golden_video_start()',
    'rg35xx_golden_video_present(',
    'RETRO_PIXEL_FORMAT_RGB565',
    'RG35XX_G1_OUTPUT_WIDTH  640u',
    'rg35xx_golden_video_deinit();',
    '/mnt/mmc/CFW/java/bin/jamvm',
    '-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit',
    '-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment',
    '-Djava.awt.headless=true',
    '/mnt/mmc/freej2me-java-error.log',
    'execv(cmd, params);',
):
    if required not in s:
        raise SystemExit("G1 NATIVE OVERLAY FAIL: required token missing: " + required)

if s == orig:
    raise SystemExit("G1 NATIVE OVERLAY FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("G1 NATIVE OVERLAY PASS:", p)
