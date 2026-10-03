#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2d6b4-fillpath-scan.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2D6B4_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
for marker in [
    "rg35xxDrawArcJdk8",
    "rg35xxArcNativeProcessLinePreclip",
    "rg35xxFillArcJdk8Lattice",
    "rg35xxPPSolveQuadratic",
]:
    if marker not in s:
        raise SystemExit("P1A_G2D6B4_STAGE_FAIL parent marker missing: %s" % marker)
if "rg35xxFillArcJdk8ProcessPath" in s:
    raise SystemExit("P1A_G2D6B4_STAGE_FAIL already staged")

start = s.find("\tprivate void rg35xxFillArcJdk8Lattice(int x, int y, int width, int height, int startAngle, int arcAngle)\n")
end = s.find("\tpublic void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)\n", start)
if start < 0 or end < 0 or end <= start:
    raise SystemExit("P1A_G2D6B4_STAGE_FAIL fillArc helper anchors")

draw_prefix = s[:start]
public_tail = s[end:]

new = r'''\t/*
\t * G2D-6B4: OpenJDK8 FillPath / ProcessPath-equivalent PIE raster.
\t *
\t * Canonical evidence:
\t *   Arc2D.PIE -> ArcIterator -> Path2D.Float
\t *   -> FillPath(AnyColor, SrcNoEa, AnyInt)
\t *   -> ProcessPath StoreFixedLine -> FillPolygon active-edge scan conversion.
\t *
\t * The 10-bit fixed-point flattening, clipping/clamping, non-zero winding,
\t * half-open edge lifetime and inclusive horizontal spans below are a
\t * specialized port for fillArc only. drawArc remains owned by G2D-6A5.
\t */
\tprivate static final int RG35XX_FILL_CRES_MIN = 0;
\tprivate static final int RG35XX_FILL_CRES_MAX = 1;
\tprivate static final int RG35XX_FILL_CRES_NOT = 3;
\tprivate static final int RG35XX_FILL_CRES_INVISIBLE = 4;

\tprivate static void rg35xxFillEnsurePointCapacity(int[][] p, int[] meta)
\t{
\t\tif(meta[0] < p[0].length) return;
\t\tint nc = p[0].length << 1;
\t\tint[] nx = new int[nc], ny = new int[nc], nl = new int[nc];
\t\tSystem.arraycopy(p[0],0,nx,0,meta[0]);
\t\tSystem.arraycopy(p[1],0,ny,0,meta[0]);
\t\tSystem.arraycopy(p[2],0,nl,0,meta[0]);
\t\tp[0]=nx; p[1]=ny; p[2]=nl;
\t}

\tprivate static void rg35xxFillAddPoint(int[][] p, int[] meta, int x, int y, boolean last)
\t{
\t\trg35xxFillEnsurePointCapacity(p,meta);
\t\tint i=meta[0]++;
\t\tp[0][i]=x; p[1][i]=y; p[2][i]=last?1:0;
\t\tif(i==0) { meta[1]=y; meta[2]=y; }
\t\telse
\t\t{
\t\t\tif(y<meta[1]) meta[1]=y;
\t\t\tif(y>meta[2]) meta[2]=y;
\t\t}
\t}

\tprivate static void rg35xxFillEndSubPath(int[][] p, int[] meta)
\t{
\t\tif(meta[0]>0) p[2][meta[0]-1]=1;
\t}

\tprivate static int rg35xxFillClipFloat(float lo, float hi, float[] c,
\t\tint a1, int b1, int a2, int b2)
\t{
\t\tif(c[a1] < lo || c[a1] > hi)
\t\t{
\t\t\tdouble t;
\t\t\tint r;
\t\t\tif(c[a1] < lo)
\t\t\t{
\t\t\t\tif(c[a2] < lo) return RG35XX_FILL_CRES_INVISIBLE;
\t\t\t\tr=RG35XX_FILL_CRES_MIN; t=lo;
\t\t\t}
\t\t\telse
\t\t\t{
\t\t\t\tif(c[a2] > hi) return RG35XX_FILL_CRES_INVISIBLE;
\t\t\t\tr=RG35XX_FILL_CRES_MAX; t=hi;
\t\t\t}
\t\t\tc[b1]=(float)(c[b1] + (double)(t-c[a1])*(c[b2]-c[b1])/(c[a2]-c[a1]));
\t\t\tc[a1]=(float)t;
\t\t\treturn r;
\t\t}
\t\treturn RG35XX_FILL_CRES_NOT;
\t}

\tprivate static int rg35xxFillClipInt(int lo, int hi, int[] c,
\t\tint a1, int b1, int a2, int b2)
\t{
\t\tif(c[a1] < lo || c[a1] > hi)
\t\t{
\t\t\tdouble t;
\t\t\tint r;
\t\t\tif(c[a1] < lo)
\t\t\t{
\t\t\t\tif(c[a2] < lo) return RG35XX_FILL_CRES_INVISIBLE;
\t\t\t\tr=RG35XX_FILL_CRES_MIN; t=lo;
\t\t\t}
\t\t\telse
\t\t\t{
\t\t\t\tif(c[a2] > hi) return RG35XX_FILL_CRES_INVISIBLE;
\t\t\t\tr=RG35XX_FILL_CRES_MAX; t=hi;
\t\t\t}
\t\t\tc[b1]=(int)(c[b1] + (double)(t-c[a1])*(c[b2]-c[b1])/(c[a2]-c[a1]));
\t\t\tc[a1]=(int)t;
\t\t\treturn r;
\t\t}
\t\treturn RG35XX_FILL_CRES_NOT;
\t}

\tprivate static int rg35xxFillClipClampFloat(float lo, float hi, float[] c,
\t\tint a1, int b1, int a2, int b2, int a3, int b3)
\t{
\t\tc[a3]=c[a1]; c[b3]=c[b1];
\t\tint r=rg35xxFillClipFloat(lo,hi,c,a1,b1,a2,b2);
\t\tif(r==RG35XX_FILL_CRES_MIN) c[a3]=c[a1];
\t\telse if(r==RG35XX_FILL_CRES_MAX) c[a3]=c[a1];
\t\telse if(r==RG35XX_FILL_CRES_INVISIBLE)
\t\t{
\t\t\tif(c[a1] > hi) return RG35XX_FILL_CRES_INVISIBLE;
\t\t\tc[a1]=lo; c[a2]=lo; r=RG35XX_FILL_CRES_NOT;
\t\t}
\t\treturn r;
\t}

\tprivate static int rg35xxFillClipClampInt(int lo, int hi, int[] c,
\t\tint a1, int b1, int a2, int b2, int a3, int b3)
\t{
\t\tc[a3]=c[a1]; c[b3]=c[b1];
\t\tint r=rg35xxFillClipInt(lo,hi,c,a1,b1,a2,b2);
\t\tif(r==RG35XX_FILL_CRES_MIN) c[a3]=c[a1];
\t\telse if(r==RG35XX_FILL_CRES_MAX) c[a3]=c[a1];
\t\telse if(r==RG35XX_FILL_CRES_INVISIBLE)
\t\t{
\t\t\tif(c[a1] > hi) return RG35XX_FILL_CRES_INVISIBLE;
\t\t\tc[a1]=lo; c[a2]=lo; r=RG35XX_FILL_CRES_NOT;
\t\t}
\t\treturn r;
\t}

\tprivate static void rg35xxFillStoreFixedLine(int[][] p, int[] meta,
\t\tint x1, int y1, int x2, int y2, boolean checkBounds, boolean endSubPath,
\t\tfloat[] b)
\t{
\t\tif(checkBounds)
\t\t{
\t\t\tint outXMin=(int)(b[0]*1024.0f), outYMin=(int)(b[1]*1024.0f);
\t\t\tint outXMax=(int)(b[2]*1024.0f), outYMax=(int)(b[3]*1024.0f);
\t\t\tint[] c=new int[]{x1,y1,x2,y2,0,0};
\t\t\tint r=rg35xxFillClipInt(outYMin,outYMax,c,1,0,3,2);
\t\t\tif(r==RG35XX_FILL_CRES_INVISIBLE) return;
\t\t\tr=rg35xxFillClipInt(outYMin,outYMax,c,3,2,1,0);
\t\t\tif(r==RG35XX_FILL_CRES_INVISIBLE) return;
\t\t\tboolean lastClipped=(r==RG35XX_FILL_CRES_MIN || r==RG35XX_FILL_CRES_MAX);

\t\t\tr=rg35xxFillClipClampInt(outXMin,outXMax,c,0,1,2,3,4,5);
\t\t\tif(r==RG35XX_FILL_CRES_MIN)
\t\t\t\trg35xxFillStoreFixedLine(p,meta,c[4],c[5],c[0],c[1],false,lastClipped,b);
\t\t\telse if(r==RG35XX_FILL_CRES_INVISIBLE) return;

\t\t\tr=rg35xxFillClipClampInt(outXMin,outXMax,c,2,3,0,1,4,5);
\t\t\tlastClipped=lastClipped || r==RG35XX_FILL_CRES_MAX;
\t\t\trg35xxFillStoreFixedLine(p,meta,c[0],c[1],c[2],c[3],false,lastClipped,b);
\t\t\tif(r==RG35XX_FILL_CRES_MIN)
\t\t\t\trg35xxFillStoreFixedLine(p,meta,c[2],c[3],c[4],c[5],false,lastClipped,b);
\t\t\treturn;
\t\t}

\t\tif(meta[0]==0 || p[2][meta[0]-1]!=0)
\t\t\trg35xxFillAddPoint(p,meta,x1,y1,false);
\t\trg35xxFillAddPoint(p,meta,x2,y2,false);
\t\tif(endSubPath) rg35xxFillEndSubPath(p,meta);
\t}

\tprivate static void rg35xxFillProcessLine(int[][] p, int[] meta,
\t\tfloat x1, float y1, float x2, float y2, float[] b)
\t{
\t\tfloat[] c=new float[]{x1,y1,x2,y2,0.0f,0.0f};
\t\tint r=rg35xxFillClipFloat(b[1],b[3],c,1,0,3,2);
\t\tif(r==RG35XX_FILL_CRES_INVISIBLE) return;
\t\tr=rg35xxFillClipFloat(b[1],b[3],c,3,2,1,0);
\t\tif(r==RG35XX_FILL_CRES_INVISIBLE) return;
\t\tboolean lastClipped=(r==RG35XX_FILL_CRES_MIN || r==RG35XX_FILL_CRES_MAX);

\t\tr=rg35xxFillClipClampFloat(b[0],b[2],c,0,1,2,3,4,5);
\t\tint X1=(int)(c[0]*1024.0f), Y1=(int)(c[1]*1024.0f);
\t\tif(r==RG35XX_FILL_CRES_MIN)
\t\t{
\t\t\tint X3=(int)(c[4]*1024.0f), Y3=(int)(c[5]*1024.0f);
\t\t\trg35xxFillStoreFixedLine(p,meta,X3,Y3,X1,Y1,false,lastClipped,b);
\t\t}
\t\telse if(r==RG35XX_FILL_CRES_INVISIBLE) return;

\t\tr=rg35xxFillClipClampFloat(b[0],b[2],c,2,3,0,1,4,5);
\t\tlastClipped=lastClipped || r==RG35XX_FILL_CRES_MAX;
\t\tint X2=(int)(c[2]*1024.0f), Y2=(int)(c[3]*1024.0f);
\t\trg35xxFillStoreFixedLine(p,meta,X1,Y1,X2,Y2,false,lastClipped,b);
\t\tif(r==RG35XX_FILL_CRES_MIN)
\t\t{
\t\t\tint X3=(int)(c[4]*1024.0f), Y3=(int)(c[5]*1024.0f);
\t\t\trg35xxFillStoreFixedLine(p,meta,X2,Y2,X3,Y3,false,lastClipped,b);
\t\t}
\t}

\tprivate static void rg35xxFillDrawMonotonicCubic(int[][] p, int[] meta,
\t\tfloat[] c, boolean checkBounds, float[] b)
\t{
\t\tfinal int MDP_MULT=1024, MDP_W_MASK=-1024;
\t\tfinal int DF_CUB_SHIFT=6, DF_CUB_COUNT=8;
\t\tint x0=(int)(c[0]*MDP_MULT), y0=(int)(c[1]*MDP_MULT);
\t\tint xe=(int)(c[6]*MDP_MULT), ye=(int)(c[7]*MDP_MULT);
\t\tint px=(x0 & (~MDP_W_MASK)) << DF_CUB_SHIFT;
\t\tint py=(y0 & (~MDP_W_MASK)) << DF_CUB_SHIFT;
\t\tint incStepBnd=1<<15, decStepBnd=1<<18;
\t\tint count=DF_CUB_COUNT, shift=DF_CUB_SHIFT;
\t\tint ax=(int)((-c[0]+3*c[2]-3*c[4]+c[6])*128.0f);
\t\tint ay=(int)((-c[1]+3*c[3]-3*c[5]+c[7])*128.0f);
\t\tint bx=(int)((3*c[0]-6*c[2]+3*c[4])*2048.0f);
\t\tint by=(int)((3*c[1]-6*c[3]+3*c[5])*2048.0f);
\t\tint cx=(int)((-3*c[0]+3*c[2])*8192.0f);
\t\tint cy=(int)((-3*c[1]+3*c[3])*8192.0f);
\t\tint dddpx=6*ax, dddpy=6*ay;
\t\tint ddpx=dddpx+bx, ddpy=dddpy+by;
\t\tint dpx=ax+(bx>>1)+cx, dpy=ay+(by>>1)+cy;
\t\tint x2=x0, y2=y0;
\t\tint x0w=x0 & MDP_W_MASK, y0w=y0 & MDP_W_MASK;
\t\tint dx=xe-x0, dy=ye-y0;

\t\twhile(count>0)
\t\t{
\t\t\twhile(Math.abs(ddpx)>decStepBnd || Math.abs(ddpy)>decStepBnd)
\t\t\t{
\t\t\t\tddpx=(ddpx<<1)-dddpx; ddpy=(ddpy<<1)-dddpy;
\t\t\t\tdpx=(dpx<<2)-(ddpx>>1); dpy=(dpy<<2)-(ddpy>>1);
\t\t\t\tcount<<=1; decStepBnd<<=3; incStepBnd<<=3;
\t\t\t\tpx<<=3; py<<=3; shift+=3;
\t\t\t}
\t\t\twhile((count&1)==0 && shift>DF_CUB_SHIFT &&
\t\t\t      Math.abs(dpx)<=incStepBnd && Math.abs(dpy)<=incStepBnd)
\t\t\t{
\t\t\t\tdpx=(dpx>>2)+(ddpx>>3); dpy=(dpy>>2)+(ddpy>>3);
\t\t\t\tddpx=(ddpx+dddpx)>>1; ddpy=(ddpy+dddpy)>>1;
\t\t\t\tcount>>=1; decStepBnd>>=3; incStepBnd>>=3;
\t\t\t\tpx>>=3; py>>=3; shift-=3;
\t\t\t}
\t\t\tcount--;
\t\t\tif(count>0)
\t\t\t{
\t\t\t\tpx+=dpx; py+=dpy; dpx+=ddpx; dpy+=ddpy; ddpx+=dddpx; ddpy+=dddpy;
\t\t\t\tint x1=x2, y1=y2;
\t\t\t\tx2=x0w+(px>>shift); y2=y0w+(py>>shift);
\t\t\t\tif(((xe-x2)^dx)<0) x2=xe;
\t\t\t\tif(((ye-y2)^dy)<0) y2=ye;
\t\t\t\trg35xxFillStoreFixedLine(p,meta,x1,y1,x2,y2,checkBounds,false,b);
\t\t\t}
\t\t\telse
\t\t\t\trg35xxFillStoreFixedLine(p,meta,x2,y2,xe,ye,checkBounds,false,b);
\t\t}
\t}

\tprivate static void rg35xxFillProcessMonotonicCubic(int[][] p, int[] meta,
\t\tfloat[] c, float[] b)
\t{
\t\tfloat xMin=c[0], xMax=c[0], yMin=c[1], yMax=c[1];
\t\tfor(int i=2;i<8;i+=2)
\t\t{
\t\t\tif(c[i]<xMin)xMin=c[i]; if(c[i]>xMax)xMax=c[i];
\t\t\tif(c[i+1]<yMin)yMin=c[i+1]; if(c[i+1]>yMax)yMax=c[i+1];
\t\t}
\t\tif(b[3]<yMin || b[1]>yMax || b[2]<xMin) return;
\t\tif(b[0]>xMax) c[0]=c[2]=c[4]=c[6]=b[0];

\t\tif(xMax-xMin>256.0f || yMax-yMin>256.0f)
\t\t{
\t\t\tfloat[] d=new float[8];
\t\t\td[6]=c[6]; d[7]=c[7];
\t\t\td[4]=(c[4]+c[6])/2.0f; d[5]=(c[5]+c[7])/2.0f;
\t\t\tfloat tx=(c[2]+c[4])/2.0f, ty=(c[3]+c[5])/2.0f;
\t\t\td[2]=(tx+d[4])/2.0f; d[3]=(ty+d[5])/2.0f;
\t\t\tc[2]=(c[0]+c[2])/2.0f; c[3]=(c[1]+c[3])/2.0f;
\t\t\tc[4]=(c[2]+tx)/2.0f; c[5]=(c[3]+ty)/2.0f;
\t\t\tc[6]=d[0]=(c[4]+d[2])/2.0f; c[7]=d[1]=(c[5]+d[3])/2.0f;
\t\t\trg35xxFillProcessMonotonicCubic(p,meta,c,b);
\t\t\trg35xxFillProcessMonotonicCubic(p,meta,d,b);
\t\t\treturn;
\t\t}
\t\tboolean checkBounds=b[0]>xMin || b[2]<xMax || b[1]>yMin || b[3]<yMax;
\t\trg35xxFillDrawMonotonicCubic(p,meta,c,checkBounds,b);
\t}

\tprivate static void rg35xxFillFirstMonotonicCubic(int[][] p, int[] meta,
\t\tfloat[] c, float t, float[] b)
\t{
\t\tfloat[] d=new float[8];
\t\tfloat tx,ty;
\t\td[0]=c[0]; d[1]=c[1];
\t\ttx=c[2]+t*(c[4]-c[2]); ty=c[3]+t*(c[5]-c[3]);
\t\td[2]=c[0]+t*(c[2]-c[0]); d[3]=c[1]+t*(c[3]-c[1]);
\t\td[4]=d[2]+t*(tx-d[2]); d[5]=d[3]+t*(ty-d[3]);
\t\tc[4]=c[4]+t*(c[6]-c[4]); c[5]=c[5]+t*(c[7]-c[5]);
\t\tc[2]=tx+t*(c[4]-tx); c[3]=ty+t*(c[5]-ty);
\t\tc[0]=d[6]=d[4]+t*(c[2]-d[4]); c[1]=d[7]=d[5]+t*(c[3]-d[5]);
\t\trg35xxFillProcessMonotonicCubic(p,meta,d,b);
\t}

\tprivate static void rg35xxFillProcessCubic(int[][] p, int[] meta, float[] c, float[] b)
\t{
\t\tdouble[] params=new double[4], res=new double[2];
\t\tint cnt=0;
\t\tif((c[0]>c[2] || c[2]>c[4] || c[4]>c[6]) &&
\t\t   (c[0]<c[2] || c[2]<c[4] || c[4]<c[6]))
\t\t{
\t\t\tdouble a=-c[0]+3.0*c[2]-3.0*c[4]+c[6];
\t\t\tdouble bb=2.0*(c[0]-2.0*c[2]+c[4]);
\t\t\tdouble cc=-c[0]+c[2];
\t\t\tint nr=rg35xxPPSolveQuadratic(cc,bb,a,res);
\t\t\tfor(int i=0;i<nr;i++) if(res[i]>0.0 && res[i]<1.0) params[cnt++]=res[i];
\t\t}
\t\tif((c[1]>c[3] || c[3]>c[5] || c[5]>c[7]) &&
\t\t   (c[1]<c[3] || c[3]<c[5] || c[5]<c[7]))
\t\t{
\t\t\tdouble a=-c[1]+3.0*c[3]-3.0*c[5]+c[7];
\t\t\tdouble bb=2.0*(c[1]-2.0*c[3]+c[5]);
\t\t\tdouble cc=-c[1]+c[3];
\t\t\tint nr=rg35xxPPSolveQuadratic(cc,bb,a,res);
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
\t\t\trg35xxFillFirstMonotonicCubic(p,meta,c,(float)params[0],b);
\t\t\tfor(int i=1;i<cnt;i++)
\t\t\t{
\t\t\t\tdouble q=params[i]-params[i-1];
\t\t\t\tif(q>0.0)
\t\t\t\t\trg35xxFillFirstMonotonicCubic(p,meta,c,
\t\t\t\t\t\t(float)(q/(1.0-params[i-1])),b);
\t\t\t}
\t\t}
\t\trg35xxFillProcessMonotonicCubic(p,meta,c,b);
\t}

\tprivate static int rg35xxFillInsertEdge(int head, int seg, int cy, int[][] p,
\t\tint[] active, int[] ex, int[] edx, int[] edir, int[] enext, int[] eprev)
\t{
\t\tint x1=p[0][seg], y1=p[1][seg], x2=p[0][seg+1], y2=p[1][seg+1];
\t\tif(y1==y2) return head;
\t\tint dX=x2-x1, dY=y2-y1, x0, dy, dir;
\t\tif(y1<y2) { x0=x1; dy=cy-y1; dir=-1; }
\t\telse { x0=x2; dy=cy-y2; dir=1; }
\t\tif(Math.abs(dX) > (1<<(30-10)))
\t\t{
\t\t\tedx[seg]=(int)((((double)dX)*1024.0)/(double)dY);
\t\t\tx0+=(int)((((double)dX)*(double)dy)/(double)dY);
\t\t}
\t\telse
\t\t{
\t\t\tedx[seg]=(dX<<10)/dY;
\t\t\tx0+=(dX*dy)/dY;
\t\t}
\t\tex[seg]=x0; edir[seg]=dir; active[seg]=1;
\t\tenext[seg]=head; eprev[seg]=-1;
\t\tif(head>=0) eprev[head]=seg;
\t\treturn seg;
\t}

\tprivate static int rg35xxFillDeleteEdge(int head, int seg, int[] active,
\t\tint[] enext, int[] eprev)
\t{
\t\tint pr=eprev[seg], nx=enext[seg];
\t\tif(pr>=0) enext[pr]=nx; else head=nx;
\t\tif(nx>=0) eprev[nx]=pr;
\t\tactive[seg]=0; enext[seg]=-1; eprev[seg]=-1;
\t\treturn head;
\t}

\tprivate static int rg35xxFillSortEdges(int head, int[] ex, int[] enext, int[] eprev)
\t{
\t\tif(head<0) return -1;
\t\tint s=-1;
\t\tboolean wasSwap=true;
\t\twhile(s!=enext[head] && wasSwap)
\t\t{
\t\t\tint r=head, p=head, q=enext[p];
\t\t\twasSwap=false;
\t\t\twhile(p!=s)
\t\t\t{
\t\t\t\tif(q<0) break;
\t\t\t\tif(ex[p]>=ex[q])
\t\t\t\t{
\t\t\t\t\twasSwap=true;
\t\t\t\t\tif(p==head)
\t\t\t\t\t{
\t\t\t\t\t\tint temp=enext[q];
\t\t\t\t\t\tenext[q]=p; enext[p]=temp; head=q; r=q;
\t\t\t\t\t}
\t\t\t\t\telse
\t\t\t\t\t{
\t\t\t\t\t\tint temp=enext[q];
\t\t\t\t\t\tenext[q]=p; enext[p]=temp; enext[r]=q; r=q;
\t\t\t\t\t}
\t\t\t\t}
\t\t\t\telse
\t\t\t\t{
\t\t\t\t\tr=p; p=enext[p];
\t\t\t\t}
\t\t\t\tq=enext[p];
\t\t\t\tif(q==s) s=p;
\t\t\t}
\t\t}
\t\tint p=head, prev=-1;
\t\twhile(p>=0)
\t\t{
\t\t\teprev[p]=prev; prev=p; p=enext[p];
\t\t}
\t\treturn head;
\t}

\tprivate void rg35xxFillPolygon(int[][] p, int[] meta, int clipL, int clipT,
\t\tint clipR, int clipB, int argb)
\t{
\t\tint n=meta[0];
\t\tif(n<=1) return;
\t\tint yMin=meta[1], yMax=meta[2];
\t\tint hashSize=((yMax-yMin)>>10)+4;
\t\tif(hashSize<=0) return;
\t\tint hashOffset=(yMin-1)&-1024;
\t\tint[] yHash=new int[hashSize], nextByY=new int[n];
\t\tfor(int i=0;i<hashSize;i++) yHash[i]=-1;
\t\tfor(int i=0;i<n;i++) nextByY[i]=-1;
\t\tfor(int i=0;i<n;i++)
\t\t{
\t\t\tint hi=(p[1][i]-hashOffset-1)>>10;
\t\t\tif(hi<0 || hi>=hashSize) continue;
\t\t\tnextByY[i]=yHash[hi]; yHash[hi]=i;
\t\t}

\t\tint[] active=new int[n], ex=new int[n], edx=new int[n], edir=new int[n];
\t\tint[] enext=new int[n], eprev=new int[n];
\t\tfor(int i=0;i<n;i++){enext[i]=-1;eprev[i]=-1;}
\t\tint head=-1;
\t\tint pw=platformImage.getRG35XXWidth();
\t\tint[] pixels=platformImage.getRG35XXPixels();

\t\tfor(int yy=hashOffset+1024,k=0; yy<=yMax && k<hashSize; yy+=1024,k++)
\t\t{
\t\t\tfor(int pt=yHash[k];pt>=0;pt=nextByY[pt])
\t\t\t{
\t\t\t\tif(pt>0 && p[2][pt-1]==0)
\t\t\t\t{
\t\t\t\t\tint seg=pt-1;
\t\t\t\t\tif(active[seg]!=0 && p[1][seg]<=yy)
\t\t\t\t\t\thead=rg35xxFillDeleteEdge(head,seg,active,enext,eprev);
\t\t\t\t\telse if(p[1][seg]>yy)
\t\t\t\t\t\thead=rg35xxFillInsertEdge(head,seg,yy,p,active,ex,edx,edir,enext,eprev);
\t\t\t\t}
\t\t\t\tif(pt+1<n && p[2][pt]==0)
\t\t\t\t{
\t\t\t\t\tint seg=pt;
\t\t\t\t\tif(active[seg]!=0 && p[1][pt+1]<=yy)
\t\t\t\t\t\thead=rg35xxFillDeleteEdge(head,seg,active,enext,eprev);
\t\t\t\t\telse if(p[1][pt+1]>yy)
\t\t\t\t\t\thead=rg35xxFillInsertEdge(head,seg,yy,p,active,ex,edx,edir,enext,eprev);
\t\t\t\t}
\t\t\t}
\t\t\tif(head<0) continue;
\t\t\thead=rg35xxFillSortEdges(head,ex,enext,eprev);
\t\t\tint counter=0, xl=clipL;
\t\t\tboolean drawing=false;
\t\t\tfor(int e=head;e>=0;e=enext[e])
\t\t\t{
\t\t\t\tcounter+=edir[e];
\t\t\t\tif(counter!=0 && !drawing)
\t\t\t\t{
\t\t\t\t\txl=(ex[e]+1023)>>10; drawing=true;
\t\t\t\t}
\t\t\t\tif(counter==0 && drawing)
\t\t\t\t{
\t\t\t\t\tint xr=(ex[e]-1)>>10;
\t\t\t\t\tint row=yy>>10;
\t\t\t\t\tint l=xl<clipL?clipL:xl, r=xr>=clipR?clipR-1:xr;
\t\t\t\t\tif(row>=clipT && row<clipB && l<=r)
\t\t\t\t\t\tfor(int xx=l;xx<=r;xx++) pixels[row*pw+xx]=argb;
\t\t\t\t\tdrawing=false;
\t\t\t\t}
\t\t\t}
\t\t\tif(drawing)
\t\t\t{
\t\t\t\tint row=yy>>10, l=xl<clipL?clipL:xl, r=clipR-1;
\t\t\t\tif(row>=clipT && row<clipB && l<=r)
\t\t\t\t\tfor(int xx=l;xx<=r;xx++) pixels[row*pw+xx]=argb;
\t\t\t}
\t\t\tfor(int e=head;e>=0;e=enext[e]) ex[e]+=edx[e];
\t\t}
\t}

\tprivate void rg35xxFillArcJdk8ProcessPath(int x, int y, int width, int height,
\t\tint startAngle, int arcAngle)
\t{
\t\tif(width<=0 || height<=0 || arcAngle==0) return;
\t\tint pw=platformImage.getRG35XXWidth(), ph=platformImage.getRG35XXHeight();
\t\tint clipL=Math.max(0,clipX), clipT=Math.max(0,clipY);
\t\tint clipR=Math.min(pw,clipX+clipWidth), clipB=Math.min(ph,clipY+clipHeight);
\t\tif(clipL>=clipR || clipT>=clipB) return;
\t\tfinal float EPSF=1.0f/1024.0f;
\t\tfloat[] bounds=new float[]{
\t\t\tclipL-0.5f, clipT-0.5f,
\t\t\tclipR-0.5f-EPSF, clipB-0.5f-EPSF
\t\t};

\t\tdouble aw=((double)width)/2.0, ah=((double)height)/2.0;
\t\tdouble cx=((double)x)+aw, cy=((double)y)+ah;
\t\tdouble angle=-Math.toRadians((double)startAngle);
\t\tdouble ext=-((double)arcAngle);
\t\tint arcSegs;
\t\tdouble increment, cv;
\t\tif(ext>=360.0 || ext<=-360.0)
\t\t{
\t\t\tarcSegs=4; increment=Math.PI/2.0; cv=0.5522847498307933;
\t\t\tif(ext<0.0){increment=-increment;cv=-cv;}
\t\t}
\t\telse
\t\t{
\t\t\tarcSegs=(int)Math.ceil(Math.abs(ext)/90.0);
\t\t\tif(arcSegs==0) return;
\t\t\tincrement=Math.toRadians(ext/(double)arcSegs);
\t\t\tcv=rg35xxArcBtan(increment);
\t\t\tif(cv==0.0) return;
\t\t}

\t\tint[][] pts=new int[][]{new int[128],new int[128],new int[128]};
\t\tint[] meta=new int[]{0,0,0};
\t\tfloat tx=(float)translateX, ty=(float)translateY;
\t\tfloat sx=(float)(cx+Math.cos(angle)*aw)+tx;
\t\tfloat sy=(float)(cy+Math.sin(angle)*ah)+ty;
\t\tfloat px=sx, py=sy;

\t\tfor(int i=0;i<arcSegs;i++)
\t\t{
\t\t\tdouble a0=angle+increment*(double)i;
\t\t\tdouble r0x=Math.cos(a0), r0y=Math.sin(a0);
\t\t\tdouble a1=a0+increment;
\t\t\tdouble r1x=Math.cos(a1), r1y=Math.sin(a1);
\t\t\tfloat[] q=new float[8];
\t\t\tq[0]=px; q[1]=py;
\t\t\tq[2]=(float)(cx+(r0x-cv*r0y)*aw)+tx;
\t\t\tq[3]=(float)(cy+(r0y+cv*r0x)*ah)+ty;
\t\t\tq[4]=(float)(cx+(r1x+cv*r1y)*aw)+tx;
\t\t\tq[5]=(float)(cy+(r1y-cv*r1x)*ah)+ty;
\t\t\tq[6]=(float)(cx+r1x*aw)+tx;
\t\t\tq[7]=(float)(cy+r1y*ah)+ty;
\t\t\tfloat ex=q[6], ey=q[7];
\t\t\trg35xxFillProcessCubic(pts,meta,q,bounds);
\t\t\tpx=ex; py=ey;
\t\t}

\t\tfloat centerX=(float)cx+tx, centerY=(float)cy+ty;
\t\trg35xxFillProcessLine(pts,meta,px,py,centerX,centerY,bounds);
\t\tif(centerX!=sx || centerY!=sy)
\t\t\trg35xxFillProcessLine(pts,meta,centerX,centerY,sx,sy,bounds);
\t\trg35xxFillEndSubPath(pts,meta);

\t\tint argb=0xFF000000 | (color & 0x00FFFFFF);
\t\trg35xxFillPolygon(pts,meta,clipL,clipT,clipR,clipB,argb);
\t}

'''
out = draw_prefix + new + public_tail
old_call = "\t\t\trg35xxFillArcJdk8Lattice(x, y, width, height, startAngle, arcAngle);\n"
new_call = "\t\t\trg35xxFillArcJdk8ProcessPath(x, y, width, height, startAngle, arcAngle);\n"
if out.count(old_call) != 1:
    raise SystemExit("P1A_G2D6B4_STAGE_FAIL public fillArc call count=%d" % out.count(old_call))
out = out.replace(old_call, new_call, 1)

for token in [
    "rg35xxFillArcJdk8ProcessPath",
    "rg35xxFillStoreFixedLine",
    "rg35xxFillProcessCubic",
    "rg35xxFillPolygon",
    "RG35XX_FILL_CRES_INVISIBLE",
]:
    if token not in out:
        raise SystemExit("P1A_G2D6B4_STAGE_FAIL output token missing: %s" % token)
if "rg35xxFillArcJdk8Lattice" in out:
    raise SystemExit("P1A_G2D6B4_STAGE_FAIL rejected lattice helper still present")
if out[:len(draw_prefix)] != draw_prefix:
    raise SystemExit("P1A_G2D6B4_STAGE_FAIL drawArc prefix changed")

pg.write_text(out, encoding="utf-8")
print("P1A_G2D6B4_STAGE=PASS")
print("P1A_G2D6B4_OWNER=OPENJDK8_FILLPATH_PROCESSPATH_ACTIVE_EDGE_SCAN")
print("P1A_G2D6B4_PROOF=G2D6B1_FILLPATH_PRIMITIVE+G2D6B3_FIXED_EDGE_BITEXACT")
print("P1A_G2D6B4_DRAWARC=UNCHANGED_G2D6A5_HOST_PASS")
print("P1A_G2D6B4_FILLARC=PIE_FIXEDPOINT_NONZERO_ACTIVE_EDGE_SCAN")
print("P1A_G2D6B4_CORE2D_CHANGE=NO")
print("P1A_G2D6B4_PHYSICAL_TEST=NO_MODULE_INTEGRATION_PENDING")
