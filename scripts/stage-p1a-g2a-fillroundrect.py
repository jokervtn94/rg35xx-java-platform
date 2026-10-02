#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2a-fillroundrect.py <stage-src>")

root = Path(sys.argv[1]).resolve()
path = root / "org/recompile/mobile/PlatformGraphics.java"
if not path.is_file():
    raise SystemExit("P1A_G2A_STAGE_FAIL missing PlatformGraphics.java")

text = path.read_text(encoding="utf-8")
parent = text
old = (
    "\tpublic void fillRoundRect(int x, int y, int width, int height, int arcWidth, int arcHeight)\n"
    "\t{\n"
    "\t\tgc.fillRoundRect(x, y, width, height, arcWidth, arcHeight);\n"
    "\t\tgc.fillRect(x, y, width, height);\n"
    "\t}\n"
)
new = (
    "\tpublic void fillRoundRect(int x, int y, int width, int height, int arcWidth, int arcHeight)\n"
    "\t{\n"
    "\t\tif (platformImage.isRG35XXRaw())\n"
    "\t\t{\n"
    "\t\t\t// Pinned Aweigit/JDK8 final result is the following full fillRect;\n"
    "\t\t\t// preserve that quirk instead of inventing rounded raw raster.\n"
    "\t\t\tfillRect(x, y, width, height);\n"
    "\t\t\treturn;\n"
    "\t\t}\n"
    "\t\tgc.fillRoundRect(x, y, width, height, arcWidth, arcHeight);\n"
    "\t\tgc.fillRect(x, y, width, height);\n"
    "\t}\n"
)
count = text.count(old)
if count != 1:
    raise SystemExit("P1A_G2A_STAGE_FAIL fillRoundRect anchor expected=1 found=%d" % count)
text = text.replace(old, new, 1)

for token in [
    "if (platformImage.isRG35XXRaw())",
    "fillRect(x, y, width, height);",
    "gc.fillRoundRect(x, y, width, height, arcWidth, arcHeight);",
    "gc.fillRect(x, y, width, height);",
]:
    if token not in text:
        raise SystemExit("P1A_G2A_STAGE_FAIL missing token: %s" % token)

# This unit may not add game names or alter any other G2 method anchor count.
for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if text.count(forbidden) != parent.count(forbidden):
        raise SystemExit("P1A_G2A_STAGE_FAIL game-specific marker delta: %s" % forbidden)

for signature in [
    "public void drawArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
    "public void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
    "public void drawRoundRect(int x, int y, int width, int height, int arcWidth, int arcHeight)",
    "public void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)",
]:
    if text.count(signature) != parent.count(signature):
        raise SystemExit("P1A_G2A_STAGE_FAIL unrelated G2 signature drift: %s" % signature)

path.write_text(text, encoding="utf-8")
print("P1A_G2A_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G2A_METHOD=fillRoundRect")
print("P1A_G2A_RAW_IMPL=EXISTING_ACCEPTED_FILLRECT")
print("P1A_G2A_CANONICAL_QUIRK=FINAL_FULL_FILLRECT")
print("P1A_G2A_CORE2D_CHANGE=NO")
print("P1A_G2A_STAGE=PASS")
