#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2d6a4d-fuzz68-fixedline-trace.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("G2D6A4D_STAGE_FAIL PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
sig = "\tprivate void rg35xxArcProcessLine(int fX0, int fY0, int fX1, int fY1,"
pos = s.find(sig)
if pos < 0:
    raise SystemExit("G2D6A4D_STAGE_FAIL rg35xxArcProcessLine missing")
end = s.find("\n\t}\n", pos)
if end < 0:
    raise SystemExit("G2D6A4D_STAGE_FAIL function end missing")
block = s[pos:end]
anchor = "\t\tint X1 = fX1 >> MDP_PREC;\n\t\tint Y1 = fY1 >> MDP_PREC;\n"
if block.count(anchor) != 1:
    raise SystemExit("G2D6A4D_STAGE_FAIL endpoint anchor count=%d" % block.count(anchor))
inject = anchor + (
    "\t\tSystem.out.println(\"G2D6A4D_SEG X0=\"+X0+\" Y0=\"+Y0+"
    "\" X1=\"+X1+\" Y1=\"+Y1+\" CHECK=\"+checkBounds);\n"
)
block2 = block.replace(anchor, inject, 1)
out = s[:pos] + block2 + s[end:]
if out.count("G2D6A4D_SEG X0=") != 1:
    raise SystemExit("G2D6A4D_STAGE_FAIL trace injection")
pg.write_text(out, encoding="utf-8")
print("G2D6A4D_FIXEDLINE_TRACE_STAGE=PASS")
print("G2D6A4D_RUNTIME_SEMANTICS_CHANGE=NO_DIAGNOSTIC_PRINT_ONLY")
