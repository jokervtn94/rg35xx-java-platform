#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2d-arc-family-jdk8-raster-v2.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2D_V2_STAGE_FAIL staged PlatformGraphics missing")
s = pg.read_text(encoding="utf-8")

for marker in [
    "rg35xxDrawArcJdk8",
    "rg35xxFillArcJdk8Lattice",
    "rg35xxPPDrawMonotonicCubic",
    "rg35xxPPDrawCubic",
]:
    if marker not in s:
        raise SystemExit("P1A_G2D_V2_STAGE_FAIL parent marker missing: %s" % marker)
if "rg35xxPPProcessCubicJdk8" in s or "rg35xxFillProcessCubicJdk8" in s:
    raise SystemExit("P1A_G2D_V2_STAGE_FAIL v2 already staged")

# ArcIterator cubics can cross X/Y extrema.  G2C's helper is the exact
# ProcessMonotonicCubic subset and is only valid after ProcessCubic splitting.
anchor = "\tprivate void rg35xxDrawArcJdk8(int x, int y, int width, int height, int startAngle, int arcAngle)\n"
if s.count(anchor) != 1:
    raise SystemExit("P1A_G2D_V2_STAGE_FAIL draw helper anchor")

draw_split = r'''	private void rg35xxPPProcessFirstMonotonicCubicJdk8(float[] c, int argb, float t)
	{
		float[] c1 = new float[8];
		float tx, ty;
		c1[0] = c[0]; c1[1] = c[1];
		tx = c[2] + t * (c[4] - c[2]);
		ty = c[3] + t * (c[5] - c[3]);
		c1[2] = c[0] + t * (c[2] - c[0]);
		c1[3] = c[1] + t * (c[3] - c[1]);
		c1[4] = c1[2] + t * (tx - c1[2]);
		c1[5] = c1[3] + t * (ty - c1[3]);
		c[4] = c[4] + t * (c[6] - c[4]);
		c[5] = c[5] + t * (c[7] - c[5]);
		c[2] = tx + t * (c[4] - tx);
		c[3] = ty + t * (c[5] - ty);
		c[0] = c1[6] = c1[4] + t * (c[2] - c1[4]);
		c[1] = c1[7] = c1[5] + t * (c[3] - c1[5]);
		rg35xxPPDrawCubic(c1, argb);
	}

	private void rg35xxPPProcessCubicJdk8(float[] c, int argb)
	{
		double[] params = new double[4];
		double[] eqn = new double[3];
		double[] res = new double[2];
		int cnt = 0;

		if((c[0] > c[2] || c[2] > c[4] || c[4] > c[6]) &&
		   (c[0] < c[2] || c[2] < c[4] || c[4] < c[6]))
		{
			eqn[2] = -c[0] + 3*c[2] - 3*c[4] + c[6];
			eqn[1] = 2*(c[0] - 2*c[2] + c[4]);
			eqn[0] = -c[0] + c[2];
			int nr = java.awt.geom.QuadCurve2D.solveQuadratic(eqn, res);
			for(int i=0; i<nr; i++) if(res[i] > 0.0 && res[i] < 1.0) params[cnt++] = res[i];
		}
		if((c[1] > c[3] || c[3] > c[5] || c[5] > c[7]) &&
		   (c[1] < c[3] || c[3] < c[5] || c[5] < c[7]))
		{
			eqn[2] = -c[1] + 3*c[3] - 3*c[5] + c[7];
			eqn[1] = 2*(c[1] - 2*c[3] + c[5]);
			eqn[0] = -c[1] + c[3];
			int nr = java.awt.geom.QuadCurve2D.solveQuadratic(eqn, res);
			for(int i=0; i<nr; i++) if(res[i] > 0.0 && res[i] < 1.0) params[cnt++] = res[i];
		}
		if(cnt > 0)
		{
			java.util.Arrays.sort(params, 0, cnt);
			rg35xxPPProcessFirstMonotonicCubicJdk8(c, argb, (float)params[0]);
			for(int i=1; i<cnt; i++)
			{
				double p = params[i] - params[i-1];
				if(p > 0.0) rg35xxPPProcessFirstMonotonicCubicJdk8(c, argb, (float)(p / (1.0 - params[i-1])));
			}
		}
		rg35xxPPDrawCubic(c, argb);
	}

'''
s = s.replace(anchor, draw_split + anchor, 1)
old_call = "\t\t\trg35xxPPDrawCubic(q, argb);\n"
if s.count(old_call) != 1:
    raise SystemExit("P1A_G2D_V2_STAGE_FAIL arc cubic call count=%d" % s.count(old_call))
s = s.replace(old_call, "\t\t\trg35xxPPProcessCubicJdk8(q, argb);\n", 1)

# Replace the rejected analytical fill shortcut with a specialized copy of the
# pinned JDK8 ProcessPath fill machinery.  Primitive arrays are used instead of
# helper classes so PlatformGraphics.class remains the only changed JAR entry.
start = s.find("\tprivate void rg35xxFillArcJdk8Lattice(")
end = s.find("\n\tpublic void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)\n", start)
if start < 0 or end < 0:
    raise SystemExit("P1A_G2D_V2_STAGE_FAIL fill helper block")

fill_impl = r'''	private int[] rg35xxFillPX;
	private int[] rg35xxFillPY;
	private boolean[] rg35xxFillLast;
	private int rg35xxFillCount;
	private int rg35xxFillYMin;
	private int rg35xxFillYMax;
	private int rg35xxFillClipL;
	private int rg35xxFillClipT;
	private int rg35xxFillClipR;
	private int rg35xxFillClipB;

	private void rg35xxFillInit()
	{
		rg35xxFillPX = new int[256];
		rg35xxFillPY = new int[256];
		rg35xxFillLast = new boolean[256];
		rg35xxFillCount = 0;
		int pw = platformImage.getRG35XXWidth();
		int ph = platformImage.getRG35XXHeight();
		rg35xxFillClipL = Math.max(0, clipX);
		rg35xxFillClipT = Math.max(0, clipY);
		rg35xxFillClipR = Math.min(pw, clipX + clipWidth);
		rg35xxFillClipB = Math.min(ph, clipY + clipHeight);
	}

	private void rg35xxFillGrow()
	{
		int n = rg35xxFillPX.length << 1;
		int[] nx = new int[n];
		int[] ny = new int[n];
		boolean[] nl = new boolean[n];
		System.arraycopy(rg35xxFillPX, 0, nx, 0, rg35xxFillCount);
		System.arraycopy(rg35xxFillPY, 0, ny, 0, rg35xxFillCount);
		System.arraycopy(rg35xxFillLast, 0, nl, 0, rg35xxFillCount);
		rg35xxFillPX = nx; rg35xxFillPY = ny; rg35xxFillLast = nl;
	}

	private void rg35xxFillAddPoint(int x, int y, boolean last)
	{
		if(rg35xxFillCount == rg35xxFillPX.length) rg35xxFillGrow();
		if(rg35xxFillCount == 0) rg35xxFillYMin = rg35xxFillYMax = y;
		else
		{
			if(y < rg35xxFillYMin) rg35xxFillYMin = y;
			if(y > rg35xxFillYMax) rg35xxFillYMax = y;
		}
		rg35xxFillPX[rg35xxFillCount] = x;
		rg35xxFillPY[rg35xxFillCount] = y;
		rg35xxFillLast[rg35xxFillCount] = last;
		rg35xxFillCount++;
	}

	private void rg35xxFillSetEnded()
	{
		if(rg35xxFillCount > 0) rg35xxFillLast[rg35xxFillCount - 1] = true;
	}

	private int rg35xxFillTestAndClipI(int lo, int hi, int[] c, int a1, int b1, int a2, int b2)
	{
		final int MIN=0, MAX=1, OK=3, INV=4;
		int r = OK;
		if(c[a1] < lo || c[a1] > hi)
		{
			double t;
			if(c[a1] < lo) { if(c[a2] < lo) return INV; r=MIN; t=lo; }
			else { if(c[a2] > hi) return INV; r=MAX; t=hi; }
			c[b1] = (int)(c[b1] + (double)(t-c[a1]) * (c[b2]-c[b1]) / (c[a2]-c[a1]));
			c[a1] = (int)t;
		}
		return r;
	}

	private int rg35xxFillClipClampI(int lo, int hi, int[] c, int a1, int b1, int a2, int b2, int a3, int b3)
	{
		final int MIN=0, MAX=1, OK=3, INV=4;
		c[a3]=c[a1]; c[b3]=c[b1];
		int r=rg35xxFillTestAndClipI(lo,hi,c,a1,b1,a2,b2);
		if(r==MIN) c[a3]=c[a1];
		else if(r==MAX) { c[a3]=c[a1]; r=MAX; }
		else if(r==INV)
		{
			if(c[a1] > hi) r=INV;
			else { c[a1]=lo; c[a2]=lo; r=OK; }
		}
		return r;
	}

	private int rg35xxFillTestAndClipF(float lo, float hi, float[] c, int a1, int b1, int a2, int b2)
	{
		final int MIN=0, MAX=1, OK=3, INV=4;
		int r=OK;
		if(c[a1] < lo || c[a1] > hi)
		{
			double t;
			if(c[a1] < lo) { if(c[a2] < lo) return INV; r=MIN; t=lo; }
			else { if(c[a2] > hi) return INV; r=MAX; t=hi; }
			c[b1]=(float)(c[b1] + (double)(t-c[a1]) * (c[b2]-c[b1]) / (c[a2]-c[a1]));
			c[a1]=(float)t;
		}
		return r;
	}

	private int rg35xxFillClipClampF(float lo, float hi, float[] c, int a1, int b1, int a2, int b2, int a3, int b3)
	{
		final int MIN=0, MAX=1, OK=3, INV=4;
		c[a3]=c[a1]; c[b3]=c[b1];
		int r=rg35xxFillTestAndClipF(lo,hi,c,a1,b1,a2,b2);
		if(r==MIN) c[a3]=c[a1];
		else if(r==MAX) { c[a3]=c[a1]; r=MAX; }
		else if(r==INV)
		{
			if(c[a1] > hi) r=INV;
			else { c[a1]=lo; c[a2]=lo; r=OK; }
		}
		return r;
	}

	private void rg35xxFillProcessFixedLine(int x1, int y1, int x2, int y2, boolean checkBounds, boolean endSubPath)
	{
		final int MIN=0, MAX=1, INV=4;
		if(checkBounds)
		{
			int[] c = new int[]{x1,y1,x2,y2,0,0};
			int outXMin=(int)((rg35xxFillClipL-0.5f)*1024.0f);
			int outXMax=(int)((rg35xxFillClipR-0.5f-(1.0f/1024.0f))*1024.0f);
			int outYMin=(int)((rg35xxFillClipT-0.5f)*1024.0f);
			int outYMax=(int)((rg35xxFillClipB-0.5f-(1.0f/1024.0f))*1024.0f);
			int r=rg35xxFillTestAndClipI(outYMin,outYMax,c,1,0,3,2);
			if(r==INV) return;
			r=rg35xxFillTestAndClipI(outYMin,outYMax,c,3,2,1,0);
			if(r==INV) return;
			boolean lastClipped=(r==MIN || r==MAX);
			r=rg35xxFillClipClampI(outXMin,outXMax,c,0,1,2,3,4,5);
			if(r==MIN) rg35xxFillProcessFixedLine(c[4],c[5],c[0],c[1],false,lastClipped);
			else if(r==INV) return;
			r=rg35xxFillClipClampI(outXMin,outXMax,c,2,3,0,1,4,5);
			lastClipped = lastClipped || r==MAX;
			rg35xxFillProcessFixedLine(c[0],c[1],c[2],c[3],false,lastClipped);
			if(r==MIN) rg35xxFillProcessFixedLine(c[2],c[3],c[4],c[5],false,lastClipped);
			return;
		}
		if(rg35xxFillCount==0 || rg35xxFillLast[rg35xxFillCount-1]) rg35xxFillAddPoint(x1,y1,false);
		rg35xxFillAddPoint(x2,y2,false);
		if(endSubPath) rg35xxFillSetEnded();
	}

	private void rg35xxFillProcessLine(float x1, float y1, float x2, float y2)
	{
		final int MIN=0, MAX=1, INV=4;
		float xMin=rg35xxFillClipL-0.5f, yMin=rg35xxFillClipT-0.5f;
		float xMax=rg35xxFillClipR-0.5f-(1.0f/1024.0f);
		float yMax=rg35xxFillClipB-0.5f-(1.0f/1024.0f);
		float[] c=new float[]{x1,y1,x2,y2,0,0};
		int r=rg35xxFillTestAndClipF(yMin,yMax,c,1,0,3,2); if(r==INV)return;
		r=rg35xxFillTestAndClipF(yMin,yMax,c,3,2,1,0); if(r==INV)return;
		boolean lastClipped=(r==MIN || r==MAX);
		r=rg35xxFillClipClampF(xMin,xMax,c,0,1,2,3,4,5);
		int X1=(int)(c[0]*1024.0f), Y1=(int)(c[1]*1024.0f);
		if(r==MIN) rg35xxFillProcessFixedLine((int)(c[4]*1024.0f),(int)(c[5]*1024.0f),X1,Y1,false,lastClipped);
		else if(r==INV)return;
		r=rg35xxFillClipClampF(xMin,xMax,c,2,3,0,1,4,5);
		lastClipped=lastClipped || r==MAX;
		int X2=(int)(c[2]*1024.0f), Y2=(int)(c[3]*1024.0f);
		rg35xxFillProcessFixedLine(X1,Y1,X2,Y2,false,lastClipped);
		if(r==MIN) rg35xxFillProcessFixedLine(X2,Y2,(int)(c[4]*1024.0f),(int)(c[5]*1024.0f),false,lastClipped);
	}

	private void rg35xxFillDrawMonotonicCubic(float[] c, boolean checkBounds)
	{
		final int MDP_MULT=1024, MDP_W_MASK=-1024, DF_CUB_SHIFT=6;
		int x0=(int)(c[0]*MDP_MULT), y0=(int)(c[1]*MDP_MULT);
		int xe=(int)(c[6]*MDP_MULT), ye=(int)(c[7]*MDP_MULT);
		int px=(x0 & (~MDP_W_MASK)) << DF_CUB_SHIFT;
		int py=(y0 & (~MDP_W_MASK)) << DF_CUB_SHIFT;
		int incStepBnd=1<<15, decStepBnd=1<<18, count=8, shift=DF_CUB_SHIFT;
		int ax=(int)((-c[0]+3*c[2]-3*c[4]+c[6])*128.0f);
		int ay=(int)((-c[1]+3*c[3]-3*c[5]+c[7])*128.0f);
		int bx=(int)((3*c[0]-6*c[2]+3*c[4])*2048.0f);
		int by=(int)((3*c[1]-6*c[3]+3*c[5])*2048.0f);
		int cx=(int)((-3*c[0]+3*c[2])*8192.0f);
		int cy=(int)((-3*c[1]+3*c[3])*8192.0f);
		int dddpx=6*ax, dddpy=6*ay;
		int ddpx=dddpx+bx, ddpy=dddpy+by;
		int dpx=ax+(bx>>1)+cx, dpy=ay+(by>>1)+cy;
		int x2=x0,y2=y0,x0w=x0&MDP_W_MASK,y0w=y0&MDP_W_MASK,dx=xe-x0,dy=ye-y0;
		while(count>0)
		{
			while(Math.abs(ddpx)>decStepBnd || Math.abs(ddpy)>decStepBnd)
			{
				ddpx=(ddpx<<1)-dddpx; ddpy=(ddpy<<1)-dddpy;
				dpx=(dpx<<2)-(ddpx>>1); dpy=(dpy<<2)-(ddpy>>1);
				count<<=1; decStepBnd<<=3; incStepBnd<<=3; px<<=3; py<<=3; shift+=3;
			}
			while((count&1)==0 && shift>DF_CUB_SHIFT && Math.abs(dpx)<=incStepBnd && Math.abs(dpy)<=incStepBnd)
			{
				dpx=(dpx>>2)+(ddpx>>3); dpy=(dpy>>2)+(ddpy>>3);
				ddpx=(ddpx+dddpx)>>1; ddpy=(ddpy+dddpy)>>1;
				count>>=1; decStepBnd>>=3; incStepBnd>>=3; px>>=3; py>>=3; shift-=3;
			}
			count--;
			if(count>0)
			{
				px+=dpx;py+=dpy;dpx+=ddpx;dpy+=ddpy;ddpx+=dddpx;ddpy+=dddpy;
				int x1=x2,y1=y2;
				x2=x0w+(px>>shift);y2=y0w+(py>>shift);
				if(((xe-x2)^dx)<0)x2=xe;if(((ye-y2)^dy)<0)y2=ye;
				rg35xxFillProcessFixedLine(x1,y1,x2,y2,checkBounds,false);
			}
			else rg35xxFillProcessFixedLine(x2,y2,xe,ye,checkBounds,false);
		}
	}

	private void rg35xxFillProcessMonotonicCubic(float[] c)
	{
		float minX=c[0],maxX=c[0],minY=c[1],maxY=c[1];
		for(int i=2;i<8;i+=2)
		{
			if(c[i]<minX)minX=c[i];if(c[i]>maxX)maxX=c[i];
			if(c[i+1]<minY)minY=c[i+1];if(c[i+1]>maxY)maxY=c[i+1];
		}
		float xMin=rg35xxFillClipL-0.5f,yMin=rg35xxFillClipT-0.5f;
		float xMax=rg35xxFillClipR-0.5f-(1.0f/1024.0f),yMax=rg35xxFillClipB-0.5f-(1.0f/1024.0f);
		if(yMax<minY || yMin>maxY || xMax<minX)return;
		if(xMin>maxX)c[0]=c[2]=c[4]=c[6]=xMin;
		if(maxX-minX>256.0f || maxY-minY>256.0f)
		{
			float[] c1=new float[8];
			c1[6]=c[6];c1[7]=c[7];c1[4]=(c[4]+c[6])/2.0f;c1[5]=(c[5]+c[7])/2.0f;
			float tx=(c[2]+c[4])/2.0f,ty=(c[3]+c[5])/2.0f;
			c1[2]=(tx+c1[4])/2.0f;c1[3]=(ty+c1[5])/2.0f;
			c[2]=(c[0]+c[2])/2.0f;c[3]=(c[1]+c[3])/2.0f;
			c[4]=(c[2]+tx)/2.0f;c[5]=(c[3]+ty)/2.0f;
			c[6]=c1[0]=(c[4]+c1[2])/2.0f;c[7]=c1[1]=(c[5]+c1[3])/2.0f;
			rg35xxFillProcessMonotonicCubic(c);rg35xxFillProcessMonotonicCubic(c1);
		}
		else rg35xxFillDrawMonotonicCubic(c, xMin>minX || xMax<maxX || yMin>minY || yMax<maxY);
	}

	private void rg35xxFillProcessFirstMonotonicCubic(float[] c, float t)
	{
		float[] c1=new float[8];float tx,ty;
		c1[0]=c[0];c1[1]=c[1];tx=c[2]+t*(c[4]-c[2]);ty=c[3]+t*(c[5]-c[3]);
		c1[2]=c[0]+t*(c[2]-c[0]);c1[3]=c[1]+t*(c[3]-c[1]);
		c1[4]=c1[2]+t*(tx-c1[2]);c1[5]=c1[3]+t*(ty-c1[3]);
		c[4]=c[4]+t*(c[6]-c[4]);c[5]=c[5]+t*(c[7]-c[5]);
		c[2]=tx+t*(c[4]-tx);c[3]=ty+t*(c[5]-ty);
		c[0]=c1[6]=c1[4]+t*(c[2]-c1[4]);c[1]=c1[7]=c1[5]+t*(c[3]-c1[5]);
		rg35xxFillProcessMonotonicCubic(c1);
	}

	private void rg35xxFillProcessCubicJdk8(float[] c)
	{
		double[] params=new double[4],eqn=new double[3],res=new double[2];int cnt=0;
		if((c[0]>c[2]||c[2]>c[4]||c[4]>c[6])&&(c[0]<c[2]||c[2]<c[4]||c[4]<c[6]))
		{
			eqn[2]=-c[0]+3*c[2]-3*c[4]+c[6];eqn[1]=2*(c[0]-2*c[2]+c[4]);eqn[0]=-c[0]+c[2];
			int nr=java.awt.geom.QuadCurve2D.solveQuadratic(eqn,res);for(int i=0;i<nr;i++)if(res[i]>0.0&&res[i]<1.0)params[cnt++]=res[i];
		}
		if((c[1]>c[3]||c[3]>c[5]||c[5]>c[7])&&(c[1]<c[3]||c[3]<c[5]||c[5]<c[7]))
		{
			eqn[2]=-c[1]+3*c[3]-3*c[5]+c[7];eqn[1]=2*(c[1]-2*c[3]+c[5]);eqn[0]=-c[1]+c[3];
			int nr=java.awt.geom.QuadCurve2D.solveQuadratic(eqn,res);for(int i=0;i<nr;i++)if(res[i]>0.0&&res[i]<1.0)params[cnt++]=res[i];
		}
		if(cnt>0)
		{
			java.util.Arrays.sort(params,0,cnt);rg35xxFillProcessFirstMonotonicCubic(c,(float)params[0]);
			for(int i=1;i<cnt;i++){double p=params[i]-params[i-1];if(p>0.0)rg35xxFillProcessFirstMonotonicCubic(c,(float)(p/(1.0-params[i-1])));}
		}
		rg35xxFillProcessMonotonicCubic(c);
	}

	private void rg35xxFillDrawScanline(int x0, int x1, int y, int argb)
	{
		if(y<rg35xxFillClipT || y>=rg35xxFillClipB)return;
		if(x0<rg35xxFillClipL)x0=rg35xxFillClipL;if(x1>=rg35xxFillClipR)x1=rg35xxFillClipR-1;
		if(x0>x1)return;
		int[] p=platformImage.getRG35XXPixels();int pw=platformImage.getRG35XXWidth();
		int off=y*pw+x0;for(int x=x0;x<=x1;x++)p[off++]=argb;
	}

	private void rg35xxFillPolygonJdk8(int argb)
	{
		final int M=1024, WM=-1024, CALC=1<<20;
		int n=rg35xxFillCount;if(n<=1)return;
		int yMin=rg35xxFillYMin,yMax=rg35xxFillYMax;
		int hashSize=((yMax-yMin)>>10)+4,hashOffset=((yMin-1)&WM);
		int[] prev=new int[n],next=new int[n],nextY=new int[n],pointEdge=new int[n],hash=new int[hashSize];
		int[] ex=new int[n],edx=new int[n],edir=new int[n],eprev=new int[n],enext=new int[n];
		java.util.Arrays.fill(prev,-1);java.util.Arrays.fill(next,-1);java.util.Arrays.fill(nextY,-1);java.util.Arrays.fill(pointEdge,-1);
		java.util.Arrays.fill(hash,-1);java.util.Arrays.fill(eprev,-1);java.util.Arrays.fill(enext,-1);
		for(int i=0;i<n-1;i++)
		{
			int hi=(rg35xxFillPY[i]-hashOffset-1)>>10;nextY[i]=hash[hi];hash[hi]=i;next[i]=i+1;prev[i+1]=i;
		}
		int hi=(rg35xxFillPY[n-1]-hashOffset-1)>>10;nextY[n-1]=hash[hi];hash[hi]=n-1;
		int head=-1,rightBnd=rg35xxFillClipR-1;
		for(int y=hashOffset+M,k=0;y<=yMax && k<hashSize;y+=M,k++)
		{
			for(int pt=hash[k];pt!=-1;pt=nextY[pt])
			{
				int pv=prev[pt];
				if(pv!=-1 && !rg35xxFillLast[pv])
				{
					int e=pointEdge[pv];
					if(e!=-1 && rg35xxFillPY[pv]<=y)
					{
						int a=eprev[e],b=enext[e];if(a!=-1)enext[a]=b;else head=b;if(b!=-1)eprev[b]=a;pointEdge[pv]=-1;
					}
					else if(rg35xxFillPY[pv]>y)
					{
						int np=next[pv],Y1=rg35xxFillPY[pv],Y2=rg35xxFillPY[np];
						if(Y1!=Y2)
						{
							int X1=rg35xxFillPX[pv],X2=rg35xxFillPX[np],dX=X2-X1,dY=Y2-Y1,x0,dy,dir;
							if(Y1<Y2){x0=X1;dy=y-Y1;dir=-1;}else{x0=X2;dy=y-Y2;dir=1;}
							if(dX>CALC||dX<-CALC){edx[pv]=(int)((((double)dX)*M)/dY);x0+=(int)((((double)dX)*dy)/dY);}else{edx[pv]=(dX<<10)/dY;x0+=(dX*dy)/dY;}
							ex[pv]=x0;edir[pv]=dir;enext[pv]=head;eprev[pv]=-1;if(head!=-1)eprev[head]=pv;head=pv;pointEdge[pv]=pv;
						}
					}
				}
				if(!rg35xxFillLast[pt] && next[pt]!=-1)
				{
					int e=pointEdge[pt];
					if(e!=-1 && rg35xxFillPY[next[pt]]<=y)
					{
						int a=eprev[e],b=enext[e];if(a!=-1)enext[a]=b;else head=b;if(b!=-1)eprev[b]=a;pointEdge[pt]=-1;
					}
					else if(rg35xxFillPY[next[pt]]>y)
					{
						int np=next[pt],Y1=rg35xxFillPY[pt],Y2=rg35xxFillPY[np];
						if(Y1!=Y2)
						{
							int X1=rg35xxFillPX[pt],X2=rg35xxFillPX[np],dX=X2-X1,dY=Y2-Y1,x0,dy,dir;
							if(Y1<Y2){x0=X1;dy=y-Y1;dir=-1;}else{x0=X2;dy=y-Y2;dir=1;}
							if(dX>CALC||dX<-CALC){edx[pt]=(int)((((double)dX)*M)/dY);x0+=(int)((((double)dX)*dy)/dY);}else{edx[pt]=(dX<<10)/dY;x0+=(dX*dy)/dY;}
							ex[pt]=x0;edir[pt]=dir;enext[pt]=head;eprev[pt]=-1;if(head!=-1)eprev[head]=pt;head=pt;pointEdge[pt]=pt;
						}
					}
				}
			}
			if(head==-1)continue;

			// Exact linked-list bubble ordering used by ProcessPath.ActiveEdgeList.
			int s=-1;boolean swapped=true;
			while(enext[head]!=s && swapped)
			{
				int r=head,p=head,q=enext[p];swapped=false;
				while(p!=s && q!=-1)
				{
					if(ex[p]>=ex[q])
					{
						swapped=true;
						if(p==head){int t=enext[q];enext[q]=p;enext[p]=t;head=q;r=q;}
						else{int t=enext[q];enext[q]=p;enext[p]=t;enext[r]=q;r=q;}
					}
					else{r=p;p=enext[p];}
					q=enext[p];if(q==s)s=p;
				}
			}
			int p=head,q=-1;while(p!=-1){eprev[p]=q;q=p;p=enext[p];}

			int counter=0,xl=rg35xxFillClipL;boolean drawing=false;
			for(int e=head;e!=-1;e=enext[e])
			{
				counter+=edir[e];
				if(counter!=0 && !drawing){xl=(ex[e]+M-1)>>10;drawing=true;}
				if(counter==0 && drawing)
				{
					int xr=(ex[e]-1)>>10;if(xl<=xr)rg35xxFillDrawScanline(xl,xr,y>>10,argb);drawing=false;
				}
				ex[e]+=edx[e];
			}
			if(drawing && xl<=rightBnd)rg35xxFillDrawScanline(xl,rightBnd,y>>10,argb);
		}
	}

	private void rg35xxFillArcJdk8ProcessPath(int x, int y, int width, int height, int startAngle, int arcAngle)
	{
		if(width<=0 || height<=0 || arcAngle==0)return;
		rg35xxFillInit();if(rg35xxFillClipL>=rg35xxFillClipR || rg35xxFillClipT>=rg35xxFillClipB)return;
		double aw=((double)width)/2.0,ah=((double)height)/2.0,cx=((double)x)+aw,cy=((double)y)+ah;
		double angle=-Math.toRadians((double)startAngle),ext=-((double)arcAngle),inc,cv;int segs;
		if(ext>=360.0||ext<=-360.0){segs=4;inc=Math.PI/2.0;cv=0.5522847498307933;if(ext<0.0){inc=-inc;cv=-cv;}}
		else{segs=(int)Math.ceil(Math.abs(ext)/90.0);if(segs==0)return;inc=Math.toRadians(ext/(double)segs);cv=rg35xxArcBtan(inc);if(cv==0.0)return;}
		float tx=(float)translateX,ty=(float)translateY;
		float sx=(float)(cx+Math.cos(angle)*aw)+tx,sy=(float)(cy+Math.sin(angle)*ah)+ty,px=sx,py=sy;
		for(int i=0;i<segs;i++)
		{
			double a0=angle+inc*(double)i,r0x=Math.cos(a0),r0y=Math.sin(a0),a1=a0+inc,r1x=Math.cos(a1),r1y=Math.sin(a1);
			float[] q=new float[8];q[0]=px;q[1]=py;
			q[2]=(float)(cx+(r0x-cv*r0y)*aw)+tx;q[3]=(float)(cy+(r0y+cv*r0x)*ah)+ty;
			q[4]=(float)(cx+(r1x+cv*r1y)*aw)+tx;q[5]=(float)(cy+(r1y-cv*r1x)*ah)+ty;
			q[6]=(float)(cx+r1x*aw)+tx;q[7]=(float)(cy+r1y*ah)+ty;
			rg35xxFillProcessCubicJdk8(q);px=q[6];py=q[7];
		}
		float mx=(float)cx+tx,my=(float)cy+ty;
		rg35xxFillProcessLine(px,py,mx,my);rg35xxFillProcessLine(mx,my,sx,sy);rg35xxFillSetEnded();
		rg35xxFillPolygonJdk8(0xFF000000 | (color & 0x00FFFFFF));
	}
'''
s = s[:start] + fill_impl + s[end:]
s = s.replace("rg35xxFillArcJdk8Lattice(x, y, width, height, startAngle, arcAngle);",
              "rg35xxFillArcJdk8ProcessPath(x, y, width, height, startAngle, arcAngle);", 1)

for token in [
    "rg35xxPPProcessCubicJdk8",
    "rg35xxFillProcessCubicJdk8",
    "rg35xxFillPolygonJdk8",
    "rg35xxFillArcJdk8ProcessPath",
]:
    if token not in s:
        raise SystemExit("P1A_G2D_V2_STAGE_FAIL output token missing: %s" % token)
if "rg35xxFillArcJdk8Lattice" in s:
    raise SystemExit("P1A_G2D_V2_STAGE_FAIL rejected lattice helper survived")
pg.write_text(s, encoding="utf-8")
print("P1A_G2D_V2_STAGE=PASS")
print("P1A_G2D_V2_DRAW=ARCITERATOR_PLUS_PROCESSCUBIC_EXTREMA_SPLIT")
print("P1A_G2D_V2_FILL=ARCITERATOR_PIE_PLUS_PROCESSPATH_FILL_ACTIVE_EDGE")
print("P1A_G2D_V2_REJECTED_LATTICE=REMOVED")
print("P1A_G2D_V2_NEW_CLASS=NO")
