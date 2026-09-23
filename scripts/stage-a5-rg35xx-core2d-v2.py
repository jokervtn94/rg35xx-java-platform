#!/usr/bin/env python3
"""Execute the A5 core2D stage after removing one nonessential rewrite whose
anchor exists both in Aweigit's commented legacy block and active Font code.
This keeps all functional A5 rewrites fail-closed without broadening matching.
"""
import sys
from pathlib import Path

src = Path(__file__).with_name("stage-a5-rg35xx-core2d.py")
text = src.read_text(encoding="utf-8")
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
code = compile(effective, str(src) + "[v2]", "exec")
globals_dict = {"__name__": "__main__", "__file__": str(src)}
exec(code, globals_dict, globals_dict)
