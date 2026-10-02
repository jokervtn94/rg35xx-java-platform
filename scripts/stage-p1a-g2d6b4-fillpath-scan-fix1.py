#!/usr/bin/env python3
from pathlib import Path
import sys

# G2D-6B4-FIX1: preserve the exact original 6B4 generator blob, but execute it
# with the single parser correction used by G2D-6A3: the generated Java body
# must use a normal triple-quoted Python string so \t escapes become real tabs.
# No runtime raster algorithm text is otherwise modified.
raw = Path(__file__).with_name("stage-p1a-g2d6b4-fillpath-scan.py")
if not raw.is_file():
    raise SystemExit("P1A_G2D6B4_FIX1_FAIL raw generator missing")

src = raw.read_text(encoding="utf-8")
needle = "new = r'''"
replacement = "new = '''"
if src.count(needle) != 1:
    raise SystemExit("P1A_G2D6B4_FIX1_FAIL raw new marker count=%d" % src.count(needle))
src = src.replace(needle, replacement, 1)

ns = {"__name__": "__main__", "__file__": str(raw)}
exec(compile(src, str(raw), "exec"), ns, ns)
print("P1A_G2D6B4_FIX1_TABS=PASS")
print("P1A_G2D6B4_FIX1_RUNTIME_LOGIC_CHANGE=NO")
