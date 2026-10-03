#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: stage-a6-rg35xx-drawregion-null-guard.py <stage-src> <audit-log>")

root = Path(sys.argv[1]).resolve()
audit = Path(sys.argv[2]).resolve()
rel = Path("org/recompile/mobile/PlatformGraphics.java")
path = root / rel

if not root.is_dir():
    raise SystemExit("A6_DRAWREGION_FAIL stage source missing: %s" % root)
if not path.is_file():
    raise SystemExit("A6_DRAWREGION_FAIL PlatformGraphics missing: %s" % path)

text = path.read_text(encoding="utf-8")

# Evidence-driven A6 overlay.
# The accepted A5 raw2D rewrite moved image.getWidth()/getHeight() ahead of the
# canonical Aweigit try/catch. The real-game A6 parent passes a null Image into
# drawRegion during the first Canvas.repaint; pinned Aweigit suppresses that
# invalid draw call, while the A5 raw path currently lets the NPE escape.
# Restore only canonical no-throw behavior. Valid raw2D drawing is unchanged.
old = (
    "\tpublic void drawRegion(Image image, int subx, int suby, int subw, int subh, int transform, int x, int y, int anchor)\n"
    "\t{\n"
    "\t\tif (subw > image.getWidth()) subw=image.getWidth(); if (subh > image.getHeight()) subh=image.getHeight();\n"
)
new = (
    "\tpublic void drawRegion(Image image, int subx, int suby, int subw, int subh, int transform, int x, int y, int anchor)\n"
    "\t{\n"
    "\t\tif (image == null || image.platformImage == null) { return; }\n"
    "\t\tif (subw > image.getWidth()) subw=image.getWidth(); if (subh > image.getHeight()) subh=image.getHeight();\n"
)

count = text.count(old)
if count != 1:
    raise SystemExit("A6_DRAWREGION_FAIL A5 drawRegion shape expected=1 found=%d" % count)
text = text.replace(old, new, 1)

if text.count("if (image == null || image.platformImage == null) { return; }") != 1:
    raise SystemExit("A6_DRAWREGION_FAIL null guard marker count")

path.write_text(text, encoding="utf-8")
with audit.open("a", encoding="utf-8") as f:
    f.write("A6_DRAWREGION\torg/recompile/mobile/PlatformGraphics.java\tcanonical-null-tolerance-before-a5-raw-preflight\n")

print("A6_DRAWREGION_NULL_GUARD_STAGE=PASS")
print("A6_DRAWREGION_NULL_GUARD_REWRITES=1")
