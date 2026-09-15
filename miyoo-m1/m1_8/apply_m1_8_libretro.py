#!/usr/bin/env python3
from pathlib import Path
import sys

p = Path(sys.argv[1] if len(sys.argv) > 1 else "upstream/src/org/recompile/freej2me/Libretro.java")
s = p.read_text()

old_import = "import org.recompile.mobile.MobilePlatform;"
new_import = old_import + "\nimport org.recompile.mobile.M1InputDispatch;"
if old_import not in s:
    raise SystemExit("M1.8 fail-closed: MobilePlatform import not found")
s = s.replace(old_import, new_import, 1)

old_lio = "\tLibretroIO lio;"
new_lio = "\tLibretroIO lio;\n\tprivate final M1InputDispatch m1InputDispatch = new M1InputDispatch();"
if old_lio not in s:
    raise SystemExit("M1.8 fail-closed: LibretroIO field anchor not found")
s = s.replace(old_lio, new_lio, 1)

old_release = "\t\t\t\t\t\t\tcase 2:\t// joypad key up\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = false;\n\t\t\t\t\t\t\t\tMobilePlatform.keyReleased(Mobile.getMobileKey(code));\n\t\t\t\t\t\t\tbreak;"
new_release = "\t\t\t\t\t\t\tcase 2:\t// legacy libretro joypad key up\n\t\t\t\t\t\t\t\t// M1.8 owns physical gameplay input via /dev/input/js0.\n\t\t\t\t\t\t\t\t// Consume this legacy packet without dispatch to prevent double events.\n\t\t\t\t\t\t\tbreak;"
if old_release not in s:
    raise SystemExit("M1.8 fail-closed: canonical release block not found")
s = s.replace(old_release, new_release, 1)

old_press = "\t\t\t\t\t\t\tcase 3: // joypad key down\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = true;\n\t\t\t\t\t\t\t\tMobilePlatform.keyPressed(Mobile.getMobileKey(code));\n\t\t\t\t\t\t\tbreak;"
new_press = "\t\t\t\t\t\t\tcase 3: // legacy libretro joypad key down\n\t\t\t\t\t\t\t\t// M1.8 owns physical gameplay input via /dev/input/js0.\n\t\t\t\t\t\t\t\t// Consume this legacy packet without dispatch to prevent double events.\n\t\t\t\t\t\t\tbreak;"
if old_press not in s:
    raise SystemExit("M1.8 fail-closed: canonical press block not found")
s = s.replace(old_press, new_press, 1)

# Poll from the existing Libretro IO loop after each complete command packet.
# This introduces no second timer/thread; rawGetState is nonblocking.
anchor = "\t\t\t\t\tif (count==5)\n\t\t\t\t\t{\n\t\t\t\t\t\tcount = 0;"
replacement = anchor + "\n\t\t\t\t\t\tm1InputDispatch.poll(System.currentTimeMillis());"
if anchor not in s:
    raise SystemExit("M1.8 fail-closed: command packet anchor not found")
s = s.replace(anchor, replacement, 1)

p.write_text(s)
