#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2d6a5-native-processline-preclip.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2D6A5_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
for marker in [
    "rg35xxArcProcessLine",
    "rg35xxArcProcessMonotonicCubic",
    "rg35xxPPDrawJdk8Line",
    "rg35xxFillArcJdk8Lattice",
]:
    if marker not in s:
        raise SystemExit("P1A_G2D6A5_STAGE_FAIL parent marker missing: %s" % marker)
if "rg35xxArcNativeProcessLinePreclip" in s:
    raise SystemExit("P1A_G2D6A5_STAGE_FAIL already staged")

fill_pos = s.find("\tprivate void rg35xxFillArcJdk8Lattice")
if fill_pos < 0:
    raise SystemExit("P1A_G2D6A5_STAGE_FAIL fillArc anchor missing")
fill_tail = s[fill_pos:]

method_anchor = "\tprivate void rg35xxArcProcessLine(int fX0, int fY0, int fX1, int fY1,\n"
method_pos = s.find(method_anchor)
if method_pos < 0:
    raise SystemExit("P1A_G2D6A5_STAGE_FAIL processLine anchor missing")

helpers = '''\t/*
\t * G2D-6A5: native OpenJDK8 ProcessPath.c PROCESS_LINE pre-clip.
\t * G2D-6A4D proved this is the first framebuffer divergence for FUZZ_68.
\t */
\tprivate static boolean rg35xxArcNativeClipOne(int[] b, int ai, int bi,
\t\tint a2i, int b2i, float lineMin, float lineMax)
\t{
\t\tint a1=b[ai], b1=b[bi], a2=b[a2i], b2=b[b2i];
\t\tif(a1 < lineMin || a1 > lineMax)
\t\t{
\t\t\tdouble t;
\t\t\tif(a1 < lineMin)
\t\t\t{
\t\t\t\tif(a2 < lineMin) return false;
\t\t\t\tt=(double)lineMin;
\t\t\t}
\t\t\telse
\t\t\t{
\t\t\t\tif(a2 > lineMax) return false;
\t\t\t\tt=(double)lineMax;
\t\t\t}
\t\t\tb1=(int)(b1 + ((t-a1)*(b2-b1))/(a2-a1));
\t\t\ta1=(int)t;
\t\t\tb[ai]=a1; b[bi]=b1;
\t\t}
\t\treturn true;
\t}

\tprivate static boolean rg35xxArcNativeProcessLinePreclip(int[] b,
\t\tfloat xMinf, float yMinf, float xMaxf, float yMaxf)
\t{
\t\tif(!rg35xxArcNativeClipOne(b,1,0,3,2,yMinf,yMaxf)) return false;
\t\tif(!rg35xxArcNativeClipOne(b,3,2,1,0,yMinf,yMaxf)) return false;
\t\tif(!rg35xxArcNativeClipOne(b,0,1,2,3,xMinf,xMaxf)) return false;
\t\tif(!rg35xxArcNativeClipOne(b,2,3,0,1,xMinf,xMaxf)) return false;
\t\treturn true;
\t}

'''
s = s[:method_pos] + helpers + s[method_pos:]

bounds_anchor = '''\t\tint xMax = Math.min(pw, clipX + clipWidth);
\t\tint yMax = Math.min(ph, clipY + clipHeight);

'''
if s.count(bounds_anchor) < 2:
    raise SystemExit("P1A_G2D6A5_STAGE_FAIL bounds anchor unexpectedly scarce=%d" % s.count(bounds_anchor))

# Replace only the first bounds block, which belongs to rg35xxArcProcessLine.
preclip = bounds_anchor + '''\t\tif(checkBounds)
\t\t{
\t\t\tfinal float EPSF = 1.0f / 1024.0f;
\t\t\tint[] rg35xxNativeLine = new int[]{X0,Y0,X1,Y1};
\t\t\tif(!rg35xxArcNativeProcessLinePreclip(rg35xxNativeLine,
\t\t\t   (float)xMin, (float)yMin, (float)xMax-EPSF, (float)yMax-EPSF)) return;
\t\t\tX0=rg35xxNativeLine[0]; Y0=rg35xxNativeLine[1];
\t\t\tX1=rg35xxNativeLine[2]; Y1=rg35xxNativeLine[3];
\t\t}

'''
s = s.replace(bounds_anchor, preclip, 1)

for token in [
    "rg35xxArcNativeClipOne",
    "rg35xxArcNativeProcessLinePreclip",
    "(float)xMax-EPSF",
    "X0=rg35xxNativeLine[0]",
]:
    if token not in s:
        raise SystemExit("P1A_G2D6A5_STAGE_FAIL output token missing: %s" % token)
if s[s.find("\tprivate void rg35xxFillArcJdk8Lattice"):] != fill_tail:
    raise SystemExit("P1A_G2D6A5_STAGE_FAIL fillArc tail changed")

pg.write_text(s, encoding="utf-8")
print("P1A_G2D6A5_STAGE=PASS")
print("P1A_G2D6A5_OWNER=OPENJDK8_NATIVE_PROCESSPATH_PROCESS_LINE_CHECKBOUNDS_PRECLIP")
print("P1A_G2D6A5_PROOF=G2D6A4D_FUZZ68_RUNTIME_BITEXACT")
print("P1A_G2D6A5_ARCITERATOR=UNCHANGED")
print("P1A_G2D6A5_CUBIC_SPLIT=UNCHANGED")
print("P1A_G2D6A5_BRESENHAM=UNCHANGED")
print("P1A_G2D6A5_FILLARC=UNCHANGED_REJECTED_PENDING_G2D6B")
print("P1A_G2D6A5_CORE2D_CHANGE=NO")
print("P1A_G2D6A5_PHYSICAL_TEST=NO_MODULE_INTEGRATION_PENDING")
