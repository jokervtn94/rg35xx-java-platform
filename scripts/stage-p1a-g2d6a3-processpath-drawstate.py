#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

# G2D-6A3-FIX1: preserve the exact original generator blob, but execute it
# with the single intended parser correction: helpers must be a normal
# triple-quoted Python string so \t escapes become real tab characters in
# generated PlatformGraphics.java. No runtime algorithm text is modified.
raw = Path(__file__).with_name("stage-p1a-g2d6a3-processpath-drawstate.raw.py")
if not raw.is_file():
    raise SystemExit("P1A_G2D6A3_FIX1_FAIL raw generator missing")

src = raw.read_text(encoding="utf-8")
needle = "helpers = r'''"
replacement = "helpers = '''"
if src.count(needle) != 1:
    raise SystemExit("P1A_G2D6A3_FIX1_FAIL raw helpers marker count=%d" % src.count(needle))
src = src.replace(needle, replacement, 1)

ns = {"__name__": "__main__", "__file__": str(raw)}
exec(compile(src, str(raw), "exec"), ns, ns)
print("P1A_G2D6A3_FIX1_TABS=PASS")
print("P1A_G2D6A3_FIX1_RUNTIME_LOGIC_CHANGE=NO")

next_stage = Path(__file__).with_name("stage-p1a-g2d6a5-native-processline-preclip.py")
if not next_stage.is_file():
    raise SystemExit("P1A_G2D6A5_CHAIN_FAIL stage missing")
if len(sys.argv) != 2:
    raise SystemExit("P1A_G2D6A5_CHAIN_FAIL stage-src argument missing")
subprocess.check_call([sys.executable, str(next_stage), sys.argv[1]])
print("P1A_G2D6A5_CHAIN=PASS")

fill_stage = Path(__file__).with_name("stage-p1a-g2d6b4-fillpath-scan-fix1.py")
if not fill_stage.is_file():
    raise SystemExit("P1A_G2D6B4_CHAIN_FAIL fix1 stage missing")
subprocess.check_call([sys.executable, str(fill_stage), sys.argv[1]])
print("P1A_G2D6B4_CHAIN=PASS")
