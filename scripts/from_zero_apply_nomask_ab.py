#!/usr/bin/env python3
"""RG35XX From-Zero isolated LCD-mask suppression A/B.

This is intentionally NOT an admitted production fix. It is a one-variable
device experiment for the remaining green-tint regression after Foundation v1.

Input must already be the From-Zero Foundation v1 assembled PlatformGraphics.
The experiment changes only Java flush semantics:
  * ignore Mobile.renderLCDMask for framebuffer composition on RG35XX libretro
  * preserve FunLights overlay behavior
  * emit one bounded diagnostic only if a game tries to enable the LCD mask

No native/video transport, audio, font, transparency, resolution, or image
normalization code is changed by this script.
"""
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: from_zero_apply_nomask_ab.py <PlatformGraphics.java>")

p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("NOMASK-AB FAIL %s count=%d" % (label, n))
    s = s.replace(old, new, 1)

once(
    "\tprotected boolean fastBlit;\n",
    "\tprotected boolean fastBlit;\n\tprivate static boolean rg35xxMaskSuppressionLogged = false;\n",
    "diagnostic flag",
)

once(
    "\t\t\tfastBlit = (!Mobile.renderLCDMask || Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;\n",
    "\t\t\tif(Mobile.renderLCDMask && !rg35xxMaskSuppressionLogged)\n"
    "\t\t\t{\n"
    "\t\t\t\trg35xxMaskSuppressionLogged = true;\n"
    "\t\t\t\tSystem.err.println(\"RG35XX-NOMASK-AB: suppressed renderLCDMask=true maskIndex=\" + Mobile.maskIndex + \" maskColor=\" + Integer.toHexString(Mobile.lcdMaskColors[Mobile.maskIndex]));\n"
    "\t\t\t}\n"
    "\t\t\tfastBlit = !Mobile.funLightsEnabled;\n",
    "fast path mask suppression",
)

once(
    "\t\t\t\t\t\tcanvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & (Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);\n",
    "\t\t\t\t\t\tcanvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i];\n",
    "slow path mask suppression",
)

if "RG35XX-NOMASK-AB" not in s:
    raise SystemExit("NOMASK-AB FAIL diagnostic marker missing")
if "fastBlit = !Mobile.funLightsEnabled;" not in s:
    raise SystemExit("NOMASK-AB FAIL fast path gate missing")
if "Mobile.renderLCDMask ? Mobile.lcdMaskColors" in s:
    raise SystemExit("NOMASK-AB FAIL conditional LCD mask survived")
if s == orig:
    raise SystemExit("NOMASK-AB FAIL no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("RG35XX_NOMASK_AB=PASS")
print("SCOPE=JAVA_PLATFORMGRAPHICS_ONLY")
print("AUDIO=UNCHANGED")
print("FONT=UNCHANGED")
print("NATIVE_CORE=UNCHANGED")
print("STATUS=DEVICE_AB_TEST_REQUIRED")
