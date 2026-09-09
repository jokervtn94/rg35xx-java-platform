#!/usr/bin/env python3
"""RG35XX: never run eager Java Sound/MIDI prewarm during MIDlet boot.

Device diagnostics established two separate facts:
1. synchronous prepareMediaEngine() blocked CMD13 before loader.start();
2. moving prepareMediaEngine() to RG35XX-MediaWarmup let video reach generation=1/2,
   but the JVM then lost stdout immediately after the ALSA /dev/snd/seq probe.

Therefore boot-time prewarming itself is unsafe on this target, not merely its
synchronous placement.  Start the MIDlet and leave media initialization lazy,
owned by the actual media request path.  This preserves video/IPC even on games
that never use audio and avoids probing unavailable ALSA sequencer hardware at
boot.

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

new = '''\t\t\t/*\n\t\t\t * RG35XX: boot-time Java Sound/MIDI prewarm is disabled. Device traces\n\t\t\t * showed the ALSA /dev/snd/seq probe can terminate or destabilize the\n\t\t\t * Java process even when moved to a daemon helper. Media must initialize\n\t\t\t * lazily from the real media request path and must never gate video/IPC.\n\t\t\t */\n\t\t\tSystem.err.println(\"RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled\");\n\t\t\tloader.start();'''

n = s.count(old)
if n != 1:
    raise SystemExit("RG35XX MEDIA BOOT FAIL: marker count=%d" % n)
s = s.replace(old, new, 1)

for required in (
    "loader.start();",
    "RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled",
):
    if required not in s:
        raise SystemExit("RG35XX MEDIA BOOT FAIL: missing " + required)

runjar = s.index("public void runJar()")
loader_pos = s.index("loader.start();", runjar)
# There must be no prepareMediaEngine call in runJar after this transform.
runjar_end = s.find("\n\tpublic ", runjar + 1)
if runjar_end < 0:
    runjar_end = len(s)
if "prepareMediaEngine();" in s[runjar:runjar_end]:
    raise SystemExit("RG35XX MEDIA BOOT FAIL: eager prepare survived in runJar")
if "RG35XX-MediaWarmup" in s[runjar:runjar_end]:
    raise SystemExit("RG35XX MEDIA BOOT FAIL: async warmup survived in runJar")

if s == orig:
    raise SystemExit("RG35XX MEDIA BOOT FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("RG35XX MEDIA BOOT PASS: eager prepare disabled", p)
