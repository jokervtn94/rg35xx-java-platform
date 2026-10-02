#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2d6a-generalrenderer-lineclip.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2D6A_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
for marker in ["rg35xxDrawArcJdk8", "rg35xxPPDrawCubicCanonicalSplit", "rg35xxPPDrawJdk8Line", "rg35xxPPProcessFixedLine"]:
    if marker not in s:
        raise SystemExit("P1A_G2D6A_STAGE_FAIL parent marker missing: %s" % marker)
if "rg35xxPPAdjustLineJdk8" in s:
    raise SystemExit("P1A_G2D6A_STAGE_FAIL already staged")

start = s.find("\tprivate void rg35xxPPDrawJdk8Line(int x1, int y1, int x2, int y2, int argb)\n")
end = s.find("\tprivate void rg35xxPPProcessFixedLine", start)
if start < 0 or end < 0 or end <= start:
    raise SystemExit("P1A_G2D6A_STAGE_FAIL line helper anchors")

new = r'''	private static int rg35xxPPOutcodeJdk8(int x, int y, int xmin, int ymin, int xmax, int ymax)
	{
		int code;
		if(y < ymin) code = 1;
		else if(y > ymax) code = 2;
		else code = 0;
		if(x < xmin) code |= 4;
		else if(x > xmax) code |= 8;
		return code;
	}

	/* Exact integer clipping used by JDK8 GeneralRenderer.adjustLine(). */
	private static boolean rg35xxPPAdjustLineJdk8(int[] b, int cxmin, int cymin, int cx2, int cy2)
	{
		int cxmax = cx2 - 1;
		int cymax = cy2 - 1;
		int x1=b[0], y1=b[1], x2=b[2], y2=b[3];
		if(cxmax < cxmin || cymax < cymin) return false;

		if(x1 == x2)
		{
			if(x1 < cxmin || x1 > cxmax) return false;
			if(y1 > y2) { int t=y1; y1=y2; y2=t; }
			if(y1 < cymin) y1=cymin;
			if(y2 > cymax) y2=cymax;
			if(y1 > y2) return false;
			b[1]=y1; b[3]=y2;
		}
		else if(y1 == y2)
		{
			if(y1 < cymin || y1 > cymax) return false;
			if(x1 > x2) { int t=x1; x1=x2; x2=t; }
			if(x1 < cxmin) x1=cxmin;
			if(x2 > cxmax) x2=cxmax;
			if(x1 > x2) return false;
			b[0]=x1; b[2]=x2;
		}
		else
		{
			int dx=x2-x1, dy=y2-y1;
			int ax=dx<0?-dx:dx, ay=dy<0?-dy:dy;
			boolean xmajor=ax>=ay;
			int o1=rg35xxPPOutcodeJdk8(x1,y1,cxmin,cymin,cxmax,cymax);
			int o2=rg35xxPPOutcodeJdk8(x2,y2,cxmin,cymin,cxmax,cymax);
			while((o1|o2)!=0)
			{
				int xs,ys;
				if((o1&o2)!=0) return false;
				if(o1!=0)
				{
					if((o1&3)!=0)
					{
						y1=(o1&1)!=0?cymin:cymax;
						ys=y1-b[1]; if(ys<0) ys=-ys;
						xs=2*ys*ax+ay;
						if(xmajor) xs+=ay-ax-1;
						xs=xs/(2*ay);
						if(dx<0) xs=-xs;
						x1=b[0]+xs;
					}
					else
					{
						x1=(o1&4)!=0?cxmin:cxmax;
						xs=x1-b[0]; if(xs<0) xs=-xs;
						ys=2*xs*ay+ax;
						if(!xmajor) ys+=ax-ay-1;
						ys=ys/(2*ax);
						if(dy<0) ys=-ys;
						y1=b[1]+ys;
					}
					o1=rg35xxPPOutcodeJdk8(x1,y1,cxmin,cymin,cxmax,cymax);
				}
				else
				{
					if((o2&3)!=0)
					{
						y2=(o2&1)!=0?cymin:cymax;
						ys=y2-b[3]; if(ys<0) ys=-ys;
						xs=2*ys*ax+ay;
						if(xmajor) xs+=ay-ax; else xs-=1;
						xs=xs/(2*ay);
						if(dx>0) xs=-xs;
						x2=b[2]+xs;
					}
					else
					{
						x2=(o2&4)!=0?cxmin:cxmax;
						xs=x2-b[2]; if(xs<0) xs=-xs;
						ys=2*xs*ay+ax;
						if(xmajor) ys-=1; else ys+=ax-ay;
						ys=ys/(2*ax);
						if(dy>0) ys=-ys;
						y2=b[3]+ys;
					}
					o2=rg35xxPPOutcodeJdk8(x2,y2,cxmin,cymin,cxmax,cymax);
				}
			}
			b[0]=x1; b[1]=y1; b[2]=x2; b[3]=y2;
			b[4]=dx; b[5]=dy; b[6]=ax; b[7]=ay;
		}
		return true;
	}

	/*
	 * JDK8 path drawing does not simply crop pixels after Bresenham.
	 * GeneralRenderer clips the integer line endpoints first, then preserves
	 * the error phase of the original unclipped line. This matters by one pixel
	 * at framebuffer/clip boundaries and is exactly what G2D fuzz exposed.
	 */
	private void rg35xxPPDrawJdk8Line(int origx1, int origy1, int origx2, int origy2, int argb)
	{
		int pw=platformImage.getRG35XXWidth(), ph=platformImage.getRG35XXHeight();
		int cl=Math.max(0,clipX), ct=Math.max(0,clipY);
		int cr=Math.min(pw,clipX+clipWidth), cb=Math.min(ph,clipY+clipHeight);
		int[] b=new int[]{origx1,origy1,origx2,origy2,0,0,0,0};
		if(!rg35xxPPAdjustLineJdk8(b,cl,ct,cr,cb)) return;
		int x1=b[0], y1=b[1], x2=b[2], y2=b[3];

		if(x1==x2)
		{
			if(y1>y2) { int t=y1; y1=y2; y2=t; }
			for(int yy=y1;yy<=y2;yy++) rg35xxPPPut(x1,yy,argb);
			return;
		}
		if(y1==y2)
		{
			if(x1>x2) { int t=x1; x1=x2; x2=t; }
			for(int xx=x1;xx<=x2;xx++) rg35xxPPPut(xx,y1,argb);
			return;
		}

		int dx=b[4], dy=b[5], ax=b[6], ay=b[7];
		boolean xmajor;
		int errmajor,errminor,bumpmajor,bumpminor,steps;
		if(ax>=ay)
		{
			xmajor=true; errmajor=ay*2; errminor=ax*2;
			bumpmajor=dx<0?-1:1; bumpminor=dy<0?-1:1;
			ax=-ax; steps=x2-x1;
		}
		else
		{
			xmajor=false; errmajor=ax*2; errminor=ay*2;
			bumpmajor=dy<0?-1:1; bumpminor=dx<0?-1:1;
			ay=-ay; steps=y2-y1;
		}
		int error=-(errminor/2);
		if(y1!=origy1) { int ys=y1-origy1; if(ys<0) ys=-ys; error+=ys*ax*2; }
		if(x1!=origx1) { int xs=x1-origx1; if(xs<0) xs=-xs; error+=xs*ay*2; }
		if(steps<0) steps=-steps;
		if(xmajor)
		{
			do { rg35xxPPPut(x1,y1,argb); x1+=bumpmajor; error+=errmajor; if(error>=0){y1+=bumpminor;error-=errminor;} } while(--steps>=0);
		}
		else
		{
			do { rg35xxPPPut(x1,y1,argb); y1+=bumpmajor; error+=errmajor; if(error>=0){x1+=bumpminor;error-=errminor;} } while(--steps>=0);
		}
	}

'''

out = s[:start] + new + s[end:]
for token in ["rg35xxPPAdjustLineJdk8", "JDK8 path drawing does not simply crop pixels", "error+=ys*ax*2", "error+=xs*ay*2"]:
    if token not in out:
        raise SystemExit("P1A_G2D6A_STAGE_FAIL output token missing: %s" % token)
for marker in ["rg35xxDrawArcJdk8", "rg35xxFillArcJdk8Lattice", "rg35xxPPDrawCubicCanonicalSplit"]:
    if marker not in out:
        raise SystemExit("P1A_G2D6A_STAGE_FAIL parent lost: %s" % marker)

pg.write_text(out, encoding="utf-8")
print("P1A_G2D6A_STAGE=PASS")
print("P1A_G2D6A_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G2D6A_FIX=OPENJDK8_GENERALRENDERER_ADJUSTLINE_ERROR_PHASE")
print("P1A_G2D6A_FILLARC=UNCHANGED_REJECTED_PENDING_G2D6B")
print("P1A_G2D6A_PHYSICAL_TEST=NO_MODULE_INTEGRATION_PENDING")
