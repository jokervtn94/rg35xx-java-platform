#!/usr/bin/env python3
"""RG35XX: do not let eager Java Sound/MIDI prewarm block MIDlet startup.

Device diagnostics showed CMD13 enters MobilePlatform.runJar(), prints the ALSA
/dev/snd/seq failure from prepareMediaEngine(), and never reaches loader.start().
On RG35XX the media engine is allowed to prewarm in a daemon helper only after
MIDlet startup has been released, so libretro IO can continue receiving CMD15
frame requests.

Fail-closed against pinned FreeJ2ME commit 13ec186903087156c145268f8706eecfaf9f1e50.
"""
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: g1_apply_rg35xx_media_boot.py <MobilePlatform.java>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s

old = '''\t\t\t/*\n\t\t\t * Load up everything needed to play sound before the jar opens to minimize ingame stutters\n\t\t\t * this basically just loads up the synthesizers, as they're the biggest troublemakers.\n\t\t\t */\n\t\t\tjavax.microedition.media.Manager.prepareMediaEngine();\n\n\t\t\tloader.start();'''

new = '''\t\t\t/*\n\t\t\t * RG35XX device diagnostics proved that eager prepareMediaEngine() can\n\t\t\t * block indefinitely while GNU Classpath/ALSA probes /dev/snd/seq.\n\t\t\t * Never gate MIDlet startup or the libretro command thread on media\n\t\t\t * prewarming. Start the MIDlet first, then prewarm opportunistically\n\t\t\t * on a daemon helper. Native/Java media paths can initialize lazily if\n\t\t\t * this helper remains blocked.\n\t\t\t */\n\t\t\tloader.start();\n\n\t\t\tThread rg35xxMediaWarmup = new Thread(new Runnable()\n\t\t\t{\n\t\t\t\tpublic void run()\n\t\t\t\t{\n\t\t\t\t\ttry\n\t\t\t\t\t{\n\t\t\t\t\t\tSystem.err.println(\"RG35XX-MEDIA-BOOT: async prepare ENTER\");\n\t\t\t\t\t\tjavax.microedition.media.Manager.prepareMediaEngine();\n\t\t\t\t\t\tSystem.err.println(\"RG35XX-MEDIA-BOOT: async prepare RETURN\");\n\t\t\t\t\t}\n\t\t\t\t\tcatch(Throwable t)\n\t\t\t\t\t{\n\t\t\t\t\t\tSystem.err.println(\"RG35XX-MEDIA-BOOT: async prepare ERROR: \" + t);\n\t\t\t\t\t}\n\t\t\t\t}\n\t\t\t}, \"RG35XX-MediaWarmup\");\n\t\t\trg35xxMediaWarmup.setDaemon(true);\n\t\t\trg35xxMediaWarmup.start();'''

n = s.count(old)
if n != 1:
    raise SystemExit("RG35XX MEDIA BOOT FAIL: marker count=%d" % n)
s = s.replace(old, new, 1)

for required in (
    "loader.start();",
    "RG35XX-MediaWarmup",
    "RG35XX-MEDIA-BOOT: async prepare ENTER",
    "rg35xxMediaWarmup.setDaemon(true)",
):
    if required not in s:
        raise SystemExit("RG35XX MEDIA BOOT FAIL: missing " + required)

# The synchronous prewarm must no longer precede loader.start().
runjar = s.index("public void runJar()")
loader_pos = s.index("loader.start();", runjar)
prepare_pos = s.index("Manager.prepareMediaEngine();", runjar)
if not loader_pos < prepare_pos:
    raise SystemExit("RG35XX MEDIA BOOT FAIL: prepare still gates loader.start")

if s == orig:
    raise SystemExit("RG35XX MEDIA BOOT FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("RG35XX MEDIA BOOT PASS:", p)
