#!/usr/bin/env python3
"""Execute the A5 core2D stage with two narrow source-shape adjustments:
1) remove one nonessential Font baseline rewrite whose anchor also appears in
   Aweigit's commented legacy block;
2) retarget only the PlatformImage helper-import rewrite from a same-package
   Mobile import (which does not exist) to ByteArrayInputStream, which exists
   exactly once in the pinned canonical source.
All functional runtime rewrites remain fail-closed and unchanged.
"""
from pathlib import Path

src = Path(__file__).with_name("stage-a5-rg35xx-core2d.py")
text = src.read_text(encoding="utf-8")

# Remove only the ambiguous/nonessential baseline-position rewrite block.
lines = text.splitlines(True)
marker = '"font-baseline-headless")'
idx = [i for i, line in enumerate(lines) if marker in line]
if len(idx) != 1:
    raise SystemExit("A5_CORE2D_V2_FAIL baseline marker count=%d" % len(idx))
end = idx[0]
start = end
while start >= 0 and not lines[start].startswith("replace_once(rel,"):
    start -= 1
if start < 0:
    raise SystemExit("A5_CORE2D_V2_FAIL baseline block start missing")
del lines[start:end + 1]
effective = "".join(lines)

# Retarget exactly one Python rewrite statement; do not broaden matching in the
# runtime source itself. PlatformImage and Mobile are in the same package, so
# canonical PlatformImage correctly has no import org.recompile.mobile.Mobile.
old = '''replace_once(rel, "import org.recompile.mobile.Mobile;\\n", "import org.recompile.mobile.Mobile;\\nimport org.recompile.rg35xx.RG35XXCore2D;\\n", "platformimage-import-core2d")'''
new = '''replace_once(rel, "import java.io.ByteArrayInputStream;\\n", "import java.io.ByteArrayInputStream;\\nimport org.recompile.rg35xx.RG35XXCore2D;\\n", "platformimage-import-core2d")'''
count = effective.count(old)
if count != 1:
    raise SystemExit("A5_CORE2D_V2_FAIL PlatformImage import rewrite count=%d" % count)
effective = effective.replace(old, new, 1)

code = compile(effective, str(src) + "[v2]", "exec")
globals_dict = {"__name__": "__main__", "__file__": str(src)}
exec(code, globals_dict, globals_dict)
