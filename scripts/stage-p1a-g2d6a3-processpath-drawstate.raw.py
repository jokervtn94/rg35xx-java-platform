#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2d6a3-processpath-drawstate.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2D6A3_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
for marker in [
    "rg35xxDrawArcJdk8",
    "rg35xxPPDrawCubicCanonicalSplit",
    "rg35xxPPAdjustLineJdk8",
    "rg35xxPPDrawJdk8Line",
]:
    if marker not in s:
        raise SystemExit("P1A_G2D6A3_STAGE_FAIL parent marker missing: %s" % marker)

if "rg35xxArcProcessMonotonicCubic" in s:
    raise SystemExit("P1A_G2D6A3_STAGE_FAIL already staged")

anchor = "\tprivate void rg35xxDrawArcJdk8(int x, int y, int width, int height, int startAngle, int arcAngle)\n"
pos = s.find(anchor)
if pos < 0:
    raise SystemExit("P1A_G2D6A3_STAGE_FAIL drawArc helper anchor missing")

helpers = r'''\t/*
\t * G2D-6A3: exact DrawProcessHandler state needed by drawArc.
\t * Canonical JDK8 keeps pixelInfo across all cubic pieces in one OPEN path,
\t * classifies each monotonic cubic against the fractional clip box, and
\t * passes checkBounds into processFixedLine(). endSubPath is intentionally
\t * absent here: JDK8 DrawProcessHandler.processFixedLine() does not use it.
\t */
\tprivate void rg35xxArcProcessLine(int fX0, int fY0, int fX1, int fY1,
\t\tboolean checkBounds, int[] pixelInfo, int argb)
\t{
\t\tfinal int MDP_PREC = 10;
\t\tint X0 = fX0 >> MDP_PREC;
\t\tint Y0 = fY0 >> MDP_PREC;
\t\tint X1 = fX1 >> MDP_PREC;
\t\tint Y1 = fY1 >> MDP_PREC;

\t\tint pw = platformImage.getRG35XXWidth();
\t\tint ph = platformImage.getRG35XXHeight();
\t\tint xMin = Math.max(0, clipX);
\t\tint yMin = Math.max(0, clipY);
\t\tint xMax = Math.min(pw, clipX + clipWidth);
\t\tint yMax = Math.min(ph, clipY + clipHeight);

\t\tif(((X0 ^ X1) | (Y0 ^ Y1)) == 0)
\t\t{
\t\t\tif(checkBounds &&
\t\t\t   (yMin > Y0 || yMax <= Y0 || xMin > X0 || xMax <= X0)) return;

\t\t\tif(pixelInfo[0] == 0)
\t\t\t{
\t\t\t\tpixelInfo[0] = 1;
\t\t\t\tpixelInfo[1] = X0; pixelInfo[2] = Y0;
\t\t\t\tpixelInfo[3] = X0; pixelInfo[4] = Y0;
\t\t\t\trg35xxPPPut(X0, Y0, argb);
\t\t\t}
\t\t\telse if((X0 != pixelInfo[3] || Y0 != pixelInfo[4]) &&
\t\t\t        (X0 != pixelInfo[1] || Y0 != pixelInfo[2]))
\t\t\t{
\t\t\t\trg35xxPPPut(X0, Y0, argb);
\t\t\t\tpixelInfo[3] = X0; pixelInfo[4] = Y0;
\t\t\t}
\t\t\treturn;
\t\t}

\t\tif(!checkBounds ||
\t\t   (yMin <= Y0 && yMax > Y0 && xMin <= X0 && xMax > X0))
\t\t{
\t\t\tif(pixelInfo[0] == 1 &&
\t\t\t   ((pixelInfo[1] == X0 && pixelInfo[2] == Y0) ||
\t\t\t    (pixelInfo[3] == X0 && pixelInfo[4] == Y0)))
\t\t\t{
\t\t\t\trg35xxPPPut(X0, Y0, argb);
\t\t\t}
\t\t}

\t\trg35xxPPDrawJdk8Line(X0, Y0, X1, Y1, argb);

\t\tif(pixelInfo[0] == 0)
\t\t{
\t\t\tpixelInfo[0] = 1;
\t\t\tpixelInfo[1] = X0; pixelInfo[2] = Y0;
\t\t\tpixelInfo[3] = X0; pixelInfo[4] = Y0;
\t\t}

\t\tif((pixelInfo[1] == X1 && pixelInfo[2] == Y1) ||
\t\t   (pixelInfo[3] == X1 && pixelInfo[4] == Y1))
\t\t{
\t\t\tif(checkBounds &&
\t\t\t   (yMin > Y1 || yMax <= Y1 || xMin > X1 || xMax <= X1)) return;
\t\t\trg35xxPPPut(X1, Y1, argb);
\t\t}
\t\tpixelInfo[3] = X1; pixelInfo[4] = Y1;
\t}

\tprivate void rg35xxArcProcessPoint(int fX, int fY, boolean checkBounds,
\t\tint[] pixelInfo, int argb)
\t{
\t\tfinal int MDP_PREC = 10;
\t\tint X = fX >> MDP_PREC;
\t\tint Y = fY >> MDP_PREC;
\t\tint pw = platformImage.getRG35XXWidth();
\t\tint ph = platformImage.getRG35XXHeight();
\t\tint xMin = Math.max(0, clipX);
\t\tint yMin = Math.max(0, clipY);
\t\tint xMax = Math.min(pw, clipX + clipWidth);
\t\tint yMax = Math.min(ph, clipY + clipHeight);
\t\tif(checkBounds &&
\t\t   (yMin > Y || yMax <= Y || xMin > X || xMax <= X)) return;

\t\tif(pixelInfo[0] == 0)
\t\t{
\t\t\tpixelInfo[0] = 1;
\t\t\tpixelInfo[1] = X; pixelInfo[2] = Y;
\t\t\tpixelInfo[3] = X; pixelInfo[4] = Y;
\t\t\trg35xxPPPut(X, Y, argb);
\t\t}
\t\telse if((X != pixelInfo[3] || Y != pixelInfo[4]) &&
\t\t        (X != pixelInfo[1] || Y != pixelInfo[2]))
\t\t{
\t\t\trg35xxPPPut(X, Y, argb);
\t\t\tpixelInfo[3] = X; pixelInfo[4] = Y;
\t\t}
\t}

\tprivate void rg35xxArcProcessFixedLine(int x1, int y1, int x2, int y2,
\t\tint[] pixelInfo, boolean checkBounds, int argb)
\t{
\t\tfinal int MDP_PREC = 10;
\t\tfinal int MDP_MULT = 1 << MDP_PREC;
\t\tfinal int MDP_HALF = MDP_MULT >> 1;
\t\tfinal int MDP_W_MASK = -MDP_MULT;
\t\tint c = (x1 ^ x2) | (y1 ^ y2);
\t\tif((c & MDP_W_MASK) == 0)
\t\t{
\t\t\tif(c == 0)
\t\t\t\trg35xxArcProcessPoint(x1 + MDP_HALF, y1 + MDP_HALF,
\t\t\t\t\tcheckBounds, pixelInfo, argb);
\t\t\treturn;
\t\t}

\t\tint rx1, ry1, rx2, ry2;
\t\tif(x1 == x2 || y1 == y2)
\t\t{
\t\t\trx1 = x1 + MDP_HALF; rx2 = x2 + MDP_HALF;
\t\t\try1 = y1 + MDP_HALF; ry2 = y2 + MDP_HALF;
\t\t}
\t\telse
\t\t{
\t\t\tint dx = x2 - x1, dy = y2 - y1;
\t\t\tint fx1 = x1 & MDP_W_MASK, fy1 = y1 & MDP_W_MASK;
\t\t\tint fx2 = x2 & MDP_W_MASK, fy2 = y2 & MDP_W_MASK;

\t\t\tif(fx1 == x1 || fy1 == y1)
\t\t\t{
\t\t\t\trx1 = x1 + MDP_HALF; ry1 = y1 + MDP_HALF;
\t\t\t}
\t\t\telse
\t\t\t{
\t\t\t\tint bx1 = x1 < x2 ? fx1 + MDP_MULT : fx1;
\t\t\t\tint by1 = y1 < y2 ? fy1 + MDP_MULT : fy1;
\t\t\t\tint cross = y1 + ((bx1 - x1) * dy) / dx;
\t\t\t\tif(cross >= fy1 && cross <= fy1 + MDP_MULT)
\t\t\t\t{
\t\t\t\t\trx1 = bx1; ry1 = cross + MDP_HALF;
\t\t\t\t}
\t\t\t\telse
\t\t\t\t{
\t\t\t\t\tcross = x1 + ((by1 - y1) * dx) / dy;
\t\t\t\t\trx1 = cross + MDP_HALF; ry1 = by1;
\t\t\t\t}
\t\t\t}

\t\t\tif(fx2 == x2 || fy2 == y2)
\t\t\t{
\t\t\t\trx2 = x2 + MDP_HALF; ry2 = y2 + MDP_HALF;
\t\t\t}
\t\t\telse
\t\t\t{
\t\t\t\tint bx2 = x1 > x2 ? fx2 + MDP_MULT : fx2;
\t\t\t\tint by2 = y1 > y2 ? fy2 + MDP_MULT : fy2;
\t\t\t\tint cross = y2 + ((bx2 - x2) * dy) / dx;
\t\t\t\tif(cross >= fy2 && cross <= fy2 + MDP_MULT)
\t\t\t\t{
\t\t\t\t\trx2 = bx2; ry2 = cross + MDP_HALF;
\t\t\t\t}
\t\t\t\telse
\t\t\t\t{
\t\t\t\t\tcross = x2 + ((by2 - y2) * dx) / dy;
\t\t\t\t\trx2 = cross + MDP_HALF; ry2 = by2;
\t\t\t\t}
\t\t\t}
\t\t}
\t\trg35xxArcProcessLine(rx1, ry1, rx2, ry2, checkBounds, pixelInfo, argb);
\t}

\tprivate void rg35xxArcDrawMonotonicCubic(float[] c, boolean checkBounds,
\t\tint[] pixelInfo, int argb)
\t{
\t\tfinal int MDP_MULT = 1024;
\t\tfinal int MDP_W_MASK = -1024;
\t\tfinal int DF_CUB_SHIFT = 6;
\t\tfinal int DF_CUB_COUNT = 8;
\t\tint x0 = (int)(c[0] * MDP_MULT);
\t\tint y0 = (int)(c[1] * MDP_MULT);
\t\tint xe = (int)(c[6] * MDP_MULT);
\t\tint ye = (int)(c[7] * MDP_MULT);
\t\tint px = (x0 & (~MDP_W_MASK)) << DF_CUB_SHIFT;
\t\tint py = (y0 & (~MDP_W_MASK)) << DF_CUB_SHIFT;
\t\tint incStepBnd = 1 << 15;
\t\tint decStepBnd = 1 << 18;
\t\tint count = DF_CUB_COUNT;
\t\tint shift = DF_CUB_SHIFT;
\t\tint ax = (int)((-c[0] + 3*c[2] - 3*c[4] + c[6]) * 128.0f);
\t\tint ay = (int)((-c[1] + 3*c[3] - 3*c[5] + c[7]) * 128.0f);
\t\tint bx = (int)((3*c[0] - 6*c[2] + 3*c[4]) * 2048.0f);
\t\tint by = (int)((3*c[1] - 6*c[3] + 3*c[5]) * 2048.0f);
\t\tint cx = (int)((-3*c[0] + 3*c[2]) * 8192.0f);
\t\tint cy = (int)((-3*c[1] + 3*c[3]) * 8192.0f);
\t\tint dddpx = 6 * ax, dddpy = 6 * ay;
\t\tint ddpx = dddpx + bx, ddpy = dddpy + by;
\t\tint dpx = ax + (bx >> 1) + cx, dpy = ay + (by >> 1) + cy;
\t\tint x2 = x0, y2 = y0;
\t\tint x0w = x0 & MDP_W_MASK, y0w = y0 & MDP_W_MASK;
\t\tint dx = xe - x0, dy = ye - y0;

\t\twhile(count > 0)
\t\t{
\t\t\twhile(Math.abs(ddpx) > decStepBnd || Math.abs(ddpy) > decStepBnd)
\t\t\t{
\t\t\t\tddpx = (ddpx << 1) - dddpx; ddpy = (ddpy << 1) - dddpy;
\t\t\t\tdpx = (dpx << 2) - (ddpx >> 1); dpy = (dpy << 2) - (ddpy >> 1);
\t\t\t\tcount <<= 1; decStepBnd <<= 3; incStepBnd <<= 3;
\t\t\t\tpx <<= 3; py <<= 3; shift += 3;
\t\t\t}
\t\t\twhile((count & 1) == 0 && shift > DF_CUB_SHIFT &&
\t\t\t      Math.abs(dpx) <= incStepBnd && Math.abs(dpy) <= incStepBnd)
\t\t\t{
\t\t\t\tdpx = (dpx >> 2) + (ddpx >> 3); dpy = (dpy >> 2) + (ddpy >> 3);
\t\t\t\tddpx = (ddpx + dddpx) >> 1; ddpy = (ddpy + dddpy) >> 1;
\t\t\t\tcount >>= 1; decStepBnd >>= 3; incStepBnd >>= 3;
\t\t\t\tpx >>= 3; py >>= 3; shift -= 3;
\t\t\t}
\t\t\tcount--;
\t\t\tif(count > 0)
\t\t\t{
\t\t\t\tpx += dpx; py += dpy; dpx += ddpx; dpy += ddpy;
\t\t\t\tddpx += dddpx; ddpy += dddpy;
\t\t\t\tint x1 = x2, y1 = y2;
\t\t\t\tx2 = x0w + (px >> shift); y2 = y0w + (py >> shift);
\t\t\t\tif(((xe - x2) ^ dx) < 0) x2 = xe;
\t\t\t\tif(((ye - y2) ^ dy) < 0) y2 = ye;
\t\t\t\trg35xxArcProcessFixedLine(x1, y1, x2, y2, pixelInfo, checkBounds, argb);
\t\t\t}
\t\t\telse
\t\t\t{
\t\t\t\trg35xxArcProcessFixedLine(x2, y2, xe, ye, pixelInfo, checkBounds, argb);
\t\t\t}
\t\t}
\t}

\tprivate void rg35xxArcProcessMonotonicCubic(float[] c, int[] pixelInfo, int argb)
\t{
\t\tfloat xMin=c[0], xMax=c[0], yMin=c[1], yMax=c[1];
\t\tfor(int i=2; i<8; i+=2)
\t\t{
\t\t\tif(c[i] < xMin) xMin=c[i]; if(c[i] > xMax) xMax=c[i];
\t\t\tif(c[i+1] < yMin) yMin=c[i+1]; if(c[i+1] > yMax) yMax=c[i+1];
\t\t}

\t\tint pw=platformImage.getRG35XXWidth(), ph=platformImage.getRG35XXHeight();
\t\tint clipL=Math.max(0,clipX), clipT=Math.max(0,clipY);
\t\tint clipR=Math.min(pw,clipX+clipWidth), clipB=Math.min(ph,clipY+clipHeight);
\t\tif(clipL >= clipR || clipT >= clipB) return;

\t\tfinal float EPSF = 1.0f / 1024.0f;
\t\tfloat xMinf=clipL-0.5f, yMinf=clipT-0.5f;
\t\tfloat xMaxf=clipR-0.5f-EPSF, yMaxf=clipB-0.5f-EPSF;
\t\tif(xMaxf < xMin || xMinf > xMax || yMaxf < yMin || yMinf > yMax) return;

\t\tif(xMax-xMin > 256.0f || yMax-yMin > 256.0f)
\t\t{
\t\t\tfloat[] b=new float[8];
\t\t\tb[6]=c[6]; b[7]=c[7];
\t\t\tb[4]=(c[4]+c[6])/2.0f; b[5]=(c[5]+c[7])/2.0f;
\t\t\tfloat tx=(c[2]+c[4])/2.0f, ty=(c[3]+c[5])/2.0f;
\t\t\tb[2]=(tx+b[4])/2.0f; b[3]=(ty+b[5])/2.0f;
\t\t\tc[2]=(c[0]+c[2])/2.0f; c[3]=(c[1]+c[3])/2.0f;
\t\t\tc[4]=(c[2]+tx)/2.0f; c[5]=(c[3]+ty)/2.0f;
\t\t\tc[6]=b[0]=(c[4]+b[2])/2.0f; c[7]=b[1]=(c[5]+b[3])/2.0f;
\t\t\trg35xxArcProcessMonotonicCubic(c,pixelInfo,argb);
\t\t\trg35xxArcProcessMonotonicCubic(b,pixelInfo,argb);
\t\t\treturn;
\t\t}

\t\tboolean checkBounds =
\t\t\txMinf > xMin || xMaxf < xMax || yMinf > yMin || yMaxf < yMax;
\t\trg35xxArcDrawMonotonicCubic(c,checkBounds,pixelInfo,argb);
\t}

\tprivate void rg35xxArcDrawFirstCanonicalMonotonicPart(float[] c, float t,
\t\tint[] pixelInfo, int argb)
\t{
\t\tfloat[] first=new float[8];
\t\tfloat tx,ty;
\t\tfirst[0]=c[0]; first[1]=c[1];
\t\ttx=c[2]+t*(c[4]-c[2]); ty=c[3]+t*(c[5]-c[3]);
\t\tfirst[2]=c[0]+t*(c[2]-c[0]); first[3]=c[1]+t*(c[3]-c[1]);
\t\tfirst[4]=first[2]+t*(tx-first[2]); first[5]=first[3]+t*(ty-first[3]);
\t\tc[4]=c[4]+t*(c[6]-c[4]); c[5]=c[5]+t*(c[7]-c[5]);
\t\tc[2]=tx+t*(c[4]-tx); c[3]=ty+t*(c[5]-ty);
\t\tc[0]=first[6]=first[4]+t*(c[2]-first[4]);
\t\tc[1]=first[7]=first[5]+t*(c[3]-first[5]);
\t\trg35xxArcProcessMonotonicCubic(first,pixelInfo,argb);
\t}

\tprivate void rg35xxArcDrawCubicCanonicalSplit(float[] c, int[] pixelInfo, int argb)
\t{
\t\tdouble[] params=new double[4];
\t\tdouble[] res=new double[2];
\t\tint cnt=0;

\t\tif((c[0]>c[2] || c[2]>c[4] || c[4]>c[6]) &&
\t\t   (c[0]<c[2] || c[2]<c[4] || c[4]<c[6]))
\t\t{
\t\t\tdouble a=-c[0]+3.0*c[2]-3.0*c[4]+c[6];
\t\t\tdouble b=2.0*(c[0]-2.0*c[2]+c[4]);
\t\t\tdouble cc=-c[0]+c[2];
\t\t\tint nr=rg35xxPPSolveQuadratic(cc,b,a,res);
\t\t\tfor(int i=0;i<nr;i++) if(res[i]>0.0 && res[i]<1.0) params[cnt++]=res[i];
\t\t}
\t\tif((c[1]>c[3] || c[3]>c[5] || c[5]>c[7]) &&
\t\t   (c[1]<c[3] || c[3]<c[5] || c[5]<c[7]))
\t\t{
\t\t\tdouble a=-c[1]+3.0*c[3]-3.0*c[5]+c[7];
\t\t\tdouble b=2.0*(c[1]-2.0*c[3]+c[5]);
\t\t\tdouble cc=-c[1]+c[3];
\t\t\tint nr=rg35xxPPSolveQuadratic(cc,b,a,res);
\t\t\tfor(int i=0;i<nr;i++) if(res[i]>0.0 && res[i]<1.0) params[cnt++]=res[i];
\t\t}
\t\tfor(int i=1;i<cnt;i++)
\t\t{
\t\t\tdouble v=params[i]; int j=i-1;
\t\t\twhile(j>=0 && params[j]>v){params[j+1]=params[j];j--;}
\t\t\tparams[j+1]=v;
\t\t}
\t\tif(cnt>0)
\t\t{
\t\t\trg35xxArcDrawFirstCanonicalMonotonicPart(c,(float)params[0],pixelInfo,argb);
\t\t\tfor(int i=1;i<cnt;i++)
\t\t\t{
\t\t\t\tdouble p=params[i]-params[i-1];
\t\t\t\tif(p>0.0)
\t\t\t\t\trg35xxArcDrawFirstCanonicalMonotonicPart(
\t\t\t\t\t\tc,(float)(p/(1.0-params[i-1])),pixelInfo,argb);
\t\t\t}
\t\t}
\t\trg35xxArcProcessMonotonicCubic(c,pixelInfo,argb);
\t}

'''

out = s[:pos] + helpers + s[pos:]

old_argb = "\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\n\t\tfor(int i=0; i<arcSegs; i++)"
new_argb = "\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\t\tint[] rg35xxPixelInfo = new int[5];\n\n\t\tfor(int i=0; i<arcSegs; i++)"
if out.count(old_argb) != 1:
    raise SystemExit("P1A_G2D6A3_STAGE_FAIL drawArc argb anchor count=%d" % out.count(old_argb))
out = out.replace(old_argb, new_argb, 1)

old_call = "\t\t\trg35xxPPDrawCubicCanonicalSplit(q, argb);\n"
new_call = "\t\t\trg35xxArcDrawCubicCanonicalSplit(q, rg35xxPixelInfo, argb);\n"
if out.count(old_call) != 1:
    raise SystemExit("P1A_G2D6A3_STAGE_FAIL drawArc cubic call count=%d" % out.count(old_call))
out = out.replace(old_call, new_call, 1)

for token in [
    "rg35xxArcProcessMonotonicCubic",
    "rg35xxArcProcessFixedLine",
    "rg35xxArcDrawCubicCanonicalSplit",
    "int[] rg35xxPixelInfo = new int[5];",
    "xMaxf=clipR-0.5f-EPSF",
    "boolean checkBounds =",
]:
    if token not in out:
        raise SystemExit("P1A_G2D6A3_STAGE_FAIL output token missing: %s" % token)

before_fill = s[s.find("\tprivate void rg35xxFillArcJdk8Lattice"):]
after_fill = out[out.find("\tprivate void rg35xxFillArcJdk8Lattice"):]
if before_fill != after_fill:
    raise SystemExit("P1A_G2D6A3_STAGE_FAIL fillArc tail changed")

pg.write_text(out, encoding="utf-8")
print("P1A_G2D6A3_STAGE=PASS")
print("P1A_G2D6A3_OWNER=RG35XX_GRAPHICS_BOUNDARY_DRAWARC_PROCESSPATH_STATE")
print("P1A_G2D6A3_DRAWSTATE=PROCESSMONOTONICCUBIC_CHECKBOUNDS_PIXELINFO")
print("P1A_G2D6A3_ENDSUBPATH=NOT_PORTED_CANONICAL_DRAWHANDLER_DOES_NOT_USE_IT")
print("P1A_G2D6A3_FILLARC=UNCHANGED_REJECTED_PENDING_G2D6B")
print("P1A_G2D6A3_CORE2D_CHANGE=NO")
print("P1A_G2D6A3_PHYSICAL_TEST=NO_MODULE_INTEGRATION_PENDING")
