#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="$ROOT/scripts/stage-p1a-dg-draw-vector-d6.py"
BACKUP="$(mktemp)"
cp "$STAGE" "$BACKUP"
cleanup(){ cp "$BACKUP" "$STAGE"; rm -f "$BACKUP"; }
trap cleanup EXIT

python3 - "$STAGE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
old='''draw_poly_sig = "\\tpublic void drawPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\\n"
draw_tri_sig = "\\tpublic void drawTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)\\n"
fill_poly_sig = "\\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\\n"
for sig,label in [(draw_poly_sig,"drawPolygon"),(draw_tri_sig,"drawTriangle"),(fill_poly_sig,"fillPolygon")]:
    if s.count(sig) != 1:
        raise SystemExit("P1A_DG_D6_STAGE_FAIL %s signature count=%d" % (label,s.count(sig)))

p0=s.index(draw_poly_sig)
p1=s.index(draw_tri_sig,p0)
p2=s.index(fill_poly_sig,p1)
if not (p0<p1<p2):
    raise SystemExit("P1A_DG_D6_STAGE_FAIL method ordering")

s = s[:p0] + helper + new_draw_polygon + "\\n" + new_draw_triangle + "\\n" + s[p2:]
'''
new='''draw_poly_sig = "\\tpublic void drawPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\\n"
draw_tri_sig = "\\tpublic void drawTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)\\n"
d4_helper_sig = "\\tprivate static int rg35xxDGSSIOutcode(float x, float y, int lox, int loy, int hix, int hiy)\\n"
fill_poly_sig = "\\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\\n"
for sig,label in [(draw_poly_sig,"drawPolygon"),(draw_tri_sig,"drawTriangle"),(d4_helper_sig,"D4 helper"),(fill_poly_sig,"fillPolygon")]:
    if s.count(sig) != 1:
        raise SystemExit("P1A_DG_D6_STAGE_FAIL %s signature count=%d" % (label,s.count(sig)))

p0=s.index(draw_poly_sig)
p1=s.index(draw_tri_sig,p0)
p2=s.index(d4_helper_sig,p1)
p3=s.index(fill_poly_sig,p2)
if not (p0<p1<p2<p3):
    raise SystemExit("P1A_DG_D6_STAGE_FAIL method/D4-helper ordering")

d4_tail = parent[p2:]
s = s[:p0] + helper + new_draw_polygon + "\\n" + new_draw_triangle + "\\n" + s[p2:]
new_d4_pos = s.index(d4_helper_sig)
if s[new_d4_pos:] != d4_tail:
    raise SystemExit("P1A_DG_D6_STAGE_FAIL D4 tail drift")
'''
if s.count(old) != 1:
    raise SystemExit('P1A_DG_D6_V2_PATCH_FAIL staging-boundary block count=%d' % s.count(old))
p.write_text(s.replace(old,new),encoding='utf-8')
print('P1A_DG_D6_V2_STAGE_BOUNDARY_PATCH=PASS')
print('P1A_DG_D6_V2_RUNTIME_SEMANTIC_DELTA=NONE')
PY

JAVA8="${JAVA8:-${JAVA_HOME:-}}" bash "$ROOT/scripts/build-p1a-dg-draw-vector-d6.sh"
