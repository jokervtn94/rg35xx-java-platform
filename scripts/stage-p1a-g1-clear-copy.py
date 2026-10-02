#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g1-clear-copy.py <stage-src>")

root = Path(sys.argv[1]).resolve()
rel = Path("org/recompile/mobile/PlatformGraphics.java")
path = root / rel
if not path.is_file():
    raise SystemExit("P1A_G1_STAGE_FAIL missing %s" % path)

text = path.read_text(encoding="utf-8")
parent_text = text


def replace_once(old, new, label):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit("P1A_G1_STAGE_FAIL %s expected=1 found=%d" % (label, count))
    text = text.replace(old, new, 1)
    print("P1A_G1_STAGE_REWRITE=%s" % label)


replace_once(
    "\tpublic void clearRect(int x, int y, int width, int height)\n"
    "\t{\n"
    "\t\tgc.clearRect(x, y, width, height);\n"
    "\t}\n",
    "\tpublic void clearRect(int x, int y, int width, int height)\n"
    "\t{\n"
    "\t\tif (platformImage.isRG35XXRaw())\n"
    "\t\t{\n"
    "\t\t\tif (width <= 0 || height <= 0) { return; }\n"
    "\t\t\tint px = x + translateX;\n"
    "\t\t\tint py = y + translateY;\n"
    "\t\t\tint left = Math.max(px, Math.max(clipX, 0));\n"
    "\t\t\tint top = Math.max(py, Math.max(clipY, 0));\n"
    "\t\t\tint right = Math.min(px + width, Math.min(clipX + clipWidth, platformImage.getRG35XXWidth()));\n"
    "\t\t\tint bottom = Math.min(py + height, Math.min(clipY + clipHeight, platformImage.getRG35XXHeight()));\n"
    "\t\t\tif (right <= left || bottom <= top) { return; }\n"
    "\t\t\tint[] dst = platformImage.getRG35XXPixels();\n"
    "\t\t\tint stride = platformImage.getRG35XXWidth();\n"
    "\t\t\tfor (int row = top; row < bottom; row++)\n"
    "\t\t\t{\n"
    "\t\t\t\tArrays.fill(dst, row * stride + left, row * stride + right, 0x00000000);\n"
    "\t\t\t}\n"
    "\t\t\treturn;\n"
    "\t\t}\n"
    "\t\tgc.clearRect(x, y, width, height);\n"
    "\t}\n",
    "PlatformGraphics.clearRect_RAW2D",
)

replace_once(
    "\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n"
    "\t{\n"
    "\t\tx = AnchorX(x, subw, anchor);\n"
    "\t\ty = AnchorY(y, subh, anchor);\n\n"
    "\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n"
    "\t\tgc.drawImage(sub, x, y, null);\n"
    "\t}\n",
    "\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n"
    "\t{\n"
    "\t\tx = AnchorX(x, subw, anchor);\n"
    "\t\ty = AnchorY(y, subh, anchor);\n\n"
    "\t\tif (platformImage.isRG35XXRaw())\n"
    "\t\t{\n"
    "\t\t\tint[] pixels = platformImage.getRG35XXPixels();\n"
    "\t\t\tint imageWidth = platformImage.getRG35XXWidth();\n"
    "\t\t\tint imageHeight = platformImage.getRG35XXHeight();\n"
    "\t\t\tRG35XXCore2D.blit(pixels, imageWidth, imageHeight, pixels, imageWidth, imageHeight,\n"
    "\t\t\t\tsubx, suby, subw, subh, 0, x + translateX, y + translateY,\n"
    "\t\t\t\tclipX, clipY, clipWidth, clipHeight);\n"
    "\t\t\treturn;\n"
    "\t\t}\n\n"
    "\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n"
    "\t\tgc.drawImage(sub, x, y, null);\n"
    "\t}\n",
    "PlatformGraphics.copyArea_RAW2D",
)

# Fail closed on the accepted coordinate contract and exact owner scope.
for token in [
    "int px = x + translateX;",
    "int py = y + translateY;",
    "Arrays.fill(dst, row * stride + left, row * stride + right, 0x00000000);",
    "subx, suby, subw, subh, 0, x + translateX, y + translateY,",
    "clipX, clipY, clipWidth, clipHeight",
]:
    if token not in text:
        raise SystemExit("P1A_G1_STAGE_FAIL missing semantic token: %s" % token)

# Parent staging history may contain diagnostic names in comments/log strings.
# G1 must not add any new game-specific marker; compare delta, not whole parent.
for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if text.count(forbidden) != parent_text.count(forbidden):
        raise SystemExit("P1A_G1_STAGE_FAIL game-specific marker delta: %s" % forbidden)

path.write_text(text, encoding="utf-8")
print("P1A_G1_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G1_CHANGED_SOURCE=org/recompile/mobile/PlatformGraphics.java")
print("P1A_G1_METHODS=clearRect,copyArea")
print("P1A_G1_CORE2D_CHANGE=NO")
print("P1A_G1_GAME_SPECIFIC_MARKER_DELTA=NO")
print("P1A_G1_STAGE=PASS")
