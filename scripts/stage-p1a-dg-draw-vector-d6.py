#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-dg-draw-vector-d6.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_DG_D6_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
parent = s

helper = r'''	private static final int RG35XX_DG_DV_TOP = 1;
	private static final int RG35XX_DG_DV_BOTTOM = 2;
	private static final int RG35XX_DG_DV_LEFT = 4;
	private static final int RG35XX_DG_DV_RIGHT = 8;
	private static final float RG35XX_DG_DV_HALF = 0.5f;
	private static final float RG35XX_DG_DV_MITER_LIMIT_SQ = 25.0f;
	private static final int RG35XX_DG_DV_ERRSTEP_MAX = 0x7fffffff;

	private static int rg35xxDGDrawVectorOutcodeInt(int x, int y, int xmin, int ymin, int xmax, int ymax)
	{
		int code;
		if(y < ymin) code = RG35XX_DG_DV_TOP;
		else if(y > ymax) code = RG35XX_DG_DV_BOTTOM;
		else code = 0;
		if(x < xmin) code |= RG35XX_DG_DV_LEFT;
		else if(x > xmax) code |= RG35XX_DG_DV_RIGHT;
		return code;
	}

	private static boolean rg35xxDGDrawVectorAdjustLine(int[] p, int cxmin, int cymin, int cx2, int cy2)
	{
		int cxmax = cx2 - 1, cymax = cy2 - 1;
		int x1=p[0], y1=p[1], x2=p[2], y2=p[3];
		if(cxmax < cxmin || cymax < cymin) return false;
		if(x1 == x2)
		{
			if(x1 < cxmin || x1 > cxmax) return false;
			if(y1 > y2) { int t=y1; y1=y2; y2=t; }
			if(y1 < cymin) y1=cymin;
			if(y2 > cymax) y2=cymax;
			if(y1 > y2) return false;
			p[1]=y1; p[3]=y2;
		}
		else if(y1 == y2)
		{
			if(y1 < cymin || y1 > cymax) return false;
			if(x1 > x2) { int t=x1; x1=x2; x2=t; }
			if(x1 < cxmin) x1=cxmin;
			if(x2 > cxmax) x2=cxmax;
			if(x1 > x2) return false;
			p[0]=x1; p[2]=x2;
		}
		else
		{
			int dx=x2-x1, dy=y2-y1;
			int ax=dx<0?-dx:dx, ay=dy<0?-dy:dy;
			boolean xmajor=ax>=ay;
			int o1=rg35xxDGDrawVectorOutcodeInt(x1,y1,cxmin,cymin,cxmax,cymax);
			int o2=rg35xxDGDrawVectorOutcodeInt(x2,y2,cxmin,cymin,cxmax,cymax);
			while((o1|o2)!=0)
			{
				int xs,ys;
				if((o1&o2)!=0) return false;
				if(o1!=0)
				{
					if((o1&(RG35XX_DG_DV_TOP|RG35XX_DG_DV_BOTTOM))!=0)
					{
						y1=(o1&RG35XX_DG_DV_TOP)!=0?cymin:cymax;
						ys=y1-p[1]; if(ys<0)ys=-ys;
						xs=2*ys*ax+ay;
						if(xmajor) xs+=ay-ax-1;
						xs=xs/(2*ay); if(dx<0)xs=-xs;
						x1=p[0]+xs;
					}
					else
					{
						x1=(o1&RG35XX_DG_DV_LEFT)!=0?cxmin:cxmax;
						xs=x1-p[0]; if(xs<0)xs=-xs;
						ys=2*xs*ay+ax;
						if(!xmajor)ys+=ax-ay-1;
						ys=ys/(2*ax); if(dy<0)ys=-ys;
						y1=p[1]+ys;
					}
					o1=rg35xxDGDrawVectorOutcodeInt(x1,y1,cxmin,cymin,cxmax,cymax);
				}
				else
				{
					if((o2&(RG35XX_DG_DV_TOP|RG35XX_DG_DV_BOTTOM))!=0)
					{
						y2=(o2&RG35XX_DG_DV_TOP)!=0?cymin:cymax;
						ys=y2-p[3]; if(ys<0)ys=-ys;
						xs=2*ys*ax+ay;
						if(xmajor)xs+=ay-ax; else xs-=1;
						xs=xs/(2*ay); if(dx>0)xs=-xs;
						x2=p[2]+xs;
					}
					else
					{
						x2=(o2&RG35XX_DG_DV_LEFT)!=0?cxmin:cxmax;
						xs=x2-p[2]; if(xs<0)xs=-xs;
						ys=2*xs*ay+ax;
						if(xmajor)ys-=1; else ys+=ax-ay;
						ys=ys/(2*ax); if(dy>0)ys=-ys;
						y2=p[3]+ys;
					}
					o2=rg35xxDGDrawVectorOutcodeInt(x2,y2,cxmin,cymin,cxmax,cymax);
				}
			}
			p[0]=x1; p[1]=y1; p[2]=x2; p[3]=y2;
			p[4]=dx; p[5]=dy; p[6]=ax; p[7]=ay;
		}
		return true;
	}

	private static void rg35xxDGDrawVectorOpaqueLine(int[] dst, int stride, int argb, int[] bp,
		int lox, int loy, int hix, int hiy, int ox1, int oy1, int ox2, int oy2)
	{
		bp[0]=ox1; bp[1]=oy1; bp[2]=ox2; bp[3]=oy2;
		if(!rg35xxDGDrawVectorAdjustLine(bp,lox,loy,hix,hiy)) return;
		int x1=bp[0],y1=bp[1],x2=bp[2],y2=bp[3];
		if(x1==x2)
		{
			if(y1>y2) do { dst[y1*stride+x1]=argb; y1--; } while(y1>=y2);
			else do { dst[y1*stride+x1]=argb; y1++; } while(y1<=y2);
		}
		else if(y1==y2)
		{
			if(x1>x2) do { dst[y1*stride+x1]=argb; x1--; } while(x1>=x2);
			else do { dst[y1*stride+x1]=argb; x1++; } while(x1<=x2);
		}
		else
		{
			int dx=bp[4],dy=bp[5],ax=bp[6],ay=bp[7];
			int steps,bumpmajor,bumpminor,errminor,errmajor,error;
			boolean xmajor;
			if(ax>=ay)
			{
				xmajor=true; errmajor=ay*2; errminor=ax*2;
				bumpmajor=dx<0?-1:1; bumpminor=dy<0?-1:1; ax=-ax; steps=x2-x1;
			}
			else
			{
				xmajor=false; errmajor=ax*2; errminor=ay*2;
				bumpmajor=dy<0?-1:1; bumpminor=dx<0?-1:1; ay=-ay; steps=y2-y1;
			}
			error=-(errminor/2);
			if(y1!=oy1){int ys=y1-oy1;if(ys<0)ys=-ys;error+=ys*ax*2;}
			if(x1!=ox1){int xs=x1-ox1;if(xs<0)xs=-xs;error+=xs*ay*2;}
			if(steps<0)steps=-steps;
			if(xmajor)
			{
				do { dst[y1*stride+x1]=argb; x1+=bumpmajor; error+=errmajor;
					if(error>=0){y1+=bumpminor;error-=errminor;} } while(--steps>=0);
			}
			else
			{
				do { dst[y1*stride+x1]=argb; y1+=bumpmajor; error+=errmajor;
					if(error>=0){x1+=bumpminor;error-=errminor;} } while(--steps>=0);
			}
		}
	}

	private void rg35xxDGDrawVectorOpaque(int[] x, int[] y, int n, int argb)
	{
		if(n<=0)return;
		int pw=platformImage.getRG35XXWidth(), ph=platformImage.getRG35XXHeight();
		int lox=Math.max(0,clipX),loy=Math.max(0,clipY);
		int hix=Math.min(pw,clipX+clipWidth),hiy=Math.min(ph,clipY+clipHeight);
		if(hix<=lox||hiy<=loy)return;
		int[] dst=platformImage.getRG35XXPixels();
		int[] bp=new int[8];
		int mx=x[0]+translateX,my=y[0]+translateY,x1=mx,y1=my;
		for(int i=1;i<n;i++)
		{
			int x2=x[i]+translateX,y2=y[i]+translateY;
			rg35xxDGDrawVectorOpaqueLine(dst,pw,argb,bp,lox,loy,hix,hiy,x1,y1,x2,y2);
			x1=x2;y1=y2;
		}
		if(x1!=mx||y1!=my)rg35xxDGDrawVectorOpaqueLine(dst,pw,argb,bp,lox,loy,hix,hiy,x1,y1,mx,my);
	}

	private static int rg35xxDGDrawVectorFractToInt(double f)
	{
		return (int)(f*(double)RG35XX_DG_DV_ERRSTEP_MAX);
	}

	private static int rg35xxDGDrawVectorAppendEdge(float x0,float y0,float x1,float y1,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		if(y0>y1){float t=x0;x0=x1;x1=t;t=y0;y0=y1;y1=t;}
		int wind=(y0>y1)?-1:1;
		return ec;
	}
'''

# Replace the intentionally short placeholder tail above with the complete alpha helper.
helper = helper[:helper.rfind("\tprivate static int rg35xxDGDrawVectorAppendEdge")] + r'''	private static int rg35xxDGDrawVectorAppendEdge(float x0,float y0,float x1,float y1,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		int wind;
		if(y0>y1){float t=x0;x0=x1;x1=t;t=y0;y0=y1;y1=t;wind=-1;}else wind=1;
		int sy=(int)Math.ceil((double)(y0-0.5f));
		int ly=(int)Math.ceil((double)(y1-0.5f));
		if(sy>=ly||sy>=hiy||ly<=loy)return ec;
		if(ec>=ex.length)throw new IllegalStateException("RG35XX draw-vector edge capacity");
		float dx=x1-x0,dy=y1-y0,slope=dx/dy;
		float yb=((float)sy)+0.5f-y0;
		x0+=yb*dx/dy;
		int sx=(int)Math.ceil((double)(x0-0.5f));
		double sf=Math.floor((double)slope);
		ex[ec]=sx;ey[ec]=sy;elast[ec]=ly;
		ebx[ec]=(int)sf;
		ebe[ec]=rg35xxDGDrawVectorFractToInt(((double)slope)-sf);
		eerr[ec]=rg35xxDGDrawVectorFractToInt((double)(x0-(((float)sx)-0.5f)));
		ewind[ec]=wind;
		return ec+1;
	}

	private static int rg35xxDGDrawVectorSinkLine(float x,float y,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		if(have[0]==0)throw new IllegalStateException("RG35XX draw-vector line without move");
		float x0=ps[0],y0=ps[1];
		float minx=x0<x?x0:x,maxx=x0<x?x:x0,miny=y0<y?y0:y,maxy=y0<y?y:y0;
		if(!(maxy<=(float)loy||miny>=(float)hiy||minx>=(float)hix))
		{
			if(maxx<=(float)lox)ec=rg35xxDGDrawVectorAppendEdge(maxx,y0,maxx,y,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
			else ec=rg35xxDGDrawVectorAppendEdge(x0,y0,x,y,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		}
		ps[0]=x;ps[1]=y;
		return ec;
	}

	private static int rg35xxDGDrawVectorSinkClose(float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		if(have[0]==0)return ec;
		if(ps[0]!=ps[2]||ps[1]!=ps[3])ec=rg35xxDGDrawVectorSinkLine(ps[2],ps[3],ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		have[0]=0;return ec;
	}

	private static int rg35xxDGDrawVectorSinkMove(float x,float y,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		if(have[0]!=0)ec=rg35xxDGDrawVectorSinkClose(ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ps[0]=ps[2]=x;ps[1]=ps[3]=y;have[0]=1;return ec;
	}

	private static void rg35xxDGDrawVectorOffset(float dx,float dy,float[] o)
	{
		float len=(float)Math.sqrt(dx*dx+dy*dy);
		if(len==0.0f){o[0]=o[1]=0.0f;return;}
		o[0]=(dy*RG35XX_DG_DV_HALF)/len;o[1]=-(dx*RG35XX_DG_DV_HALF)/len;
	}

	private static boolean rg35xxDGDrawVectorCW(float dx1,float dy1,float dx2,float dy2)
	{
		return dx1*dy2<=dy1*dx2;
	}

	private static void rg35xxDGDrawVectorIntersection(float x0,float y0,float x1,float y1,
		float x0p,float y0p,float x1p,float y1p,float[] m)
	{
		float x10=x1-x0,y10=y1-y0,x10p=x1p-x0p,y10p=y1p-y0p;
		float den=x10*y10p-x10p*y10;
		float t=x10p*(y0-y0p)-y10p*(x0-x0p);t/=den;
		m[0]=x0+t*x10;m[1]=y0+t*y10;
	}

	private static int rg35xxDGDrawVectorEmit(float x,float y,boolean reverse,
		float[] rx,float[] ry,int[] rc,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		if(reverse){if(rc[0]>=rx.length)throw new IllegalStateException("RG35XX draw-vector reverse capacity");rx[rc[0]]=x;ry[rc[0]]=y;rc[0]++;return ec;}
		return rg35xxDGDrawVectorSinkLine(x,y,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
	}

	private static int rg35xxDGDrawVectorEmitReverse(float[] rx,float[] ry,int[] rc,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		while(rc[0]>0){rc[0]--;ec=rg35xxDGDrawVectorSinkLine(rx[rc[0]],ry[rc[0]],ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);}return ec;
	}

	private static int rg35xxDGDrawVectorJoin(float pdx,float pdy,float x0,float y0,float dx,float dy,
		float omx,float omy,float mx,float my,float[] st,int[] prev,float[] miter,
		float[] rx,float[] ry,int[] rc,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		if(prev[0]!=1)
		{
			ec=rg35xxDGDrawVectorSinkMove(x0+mx,y0+my,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
			st[2]=dx;st[3]=dy;st[8]=mx;st[9]=my;
		}
		else
		{
			boolean cw=rg35xxDGDrawVectorCW(pdx,pdy,dx,dy);
			float aomx=omx,aomy=omy,amx=mx,amy=my;
			if(!((amx==aomx&&amy==aomy)||(pdx==0.0f&&pdy==0.0f)||(dx==0.0f&&dy==0.0f)))
			{
				if(cw){aomx=-aomx;aomy=-aomy;amx=-amx;amy=-amy;}
				rg35xxDGDrawVectorIntersection((x0-pdx)+aomx,(y0-pdy)+aomy,x0+aomx,y0+aomy,
					(dx+x0)+amx,(dy+y0)+amy,x0+amx,y0+amy,miter);
				float ddx=miter[0]-x0,ddy=miter[1]-y0;
				if(ddx*ddx+ddy*ddy<RG35XX_DG_DV_MITER_LIMIT_SQ)
					ec=rg35xxDGDrawVectorEmit(miter[0],miter[1],cw,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
			}
			ec=rg35xxDGDrawVectorEmit(x0,y0,!cw,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		}
		prev[0]=1;return ec;
	}

	private static int rg35xxDGDrawVectorStrokeLineTo(float x1,float y1,float[] st,int[] prev,float[] off,float[] miter,
		float[] rx,float[] ry,int[] rc,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		float dx=x1-st[4],dy=y1-st[5];if(dx==0.0f&&dy==0.0f)dx=1.0f;
		rg35xxDGDrawVectorOffset(dx,dy,off);float mx=off[0],my=off[1];
		ec=rg35xxDGDrawVectorJoin(st[6],st[7],st[4],st[5],dx,dy,st[10],st[11],mx,my,st,prev,miter,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(st[4]+mx,st[5]+my,false,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(x1+mx,y1+my,false,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(st[4]-mx,st[5]-my,true,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(x1-mx,y1-my,true,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		st[10]=mx;st[11]=my;st[6]=dx;st[7]=dy;st[4]=x1;st[5]=y1;prev[0]=1;return ec;
	}

	private static int rg35xxDGDrawVectorFinish(float[] st,int[] prev,float[] rx,float[] ry,int[] rc,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		ec=rg35xxDGDrawVectorEmit(st[4]-st[11]+st[10],st[5]+st[10]+st[11],false,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(st[4]-st[11]-st[10],st[5]+st[10]-st[11],false,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmitReverse(rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(st[0]+st[9]-st[8],st[1]-st[8]-st[9],false,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(st[0]+st[9]+st[8],st[1]-st[8]+st[9],false,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorSinkClose(ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);return ec;
	}

	private static int rg35xxDGDrawVectorStrokeClose(float[] st,int[] prev,float[] off,float[] miter,
		float[] rx,float[] ry,int[] rc,float[] ps,int[] have,
		int lox,int loy,int hix,int hiy,
		int[] ex,int[] ey,int[] elast,int[] eerr,int[] ebx,int[] ebe,int[] ewind,int ec)
	{
		if(prev[0]!=1)
		{
			if(prev[0]==2)return ec;
			ec=rg35xxDGDrawVectorSinkMove(st[4],st[5]-RG35XX_DG_DV_HALF,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
			st[10]=st[8]=0.0f;st[11]=st[9]=-RG35XX_DG_DV_HALF;st[6]=st[2]=1.0f;st[7]=st[3]=0.0f;
			return rg35xxDGDrawVectorFinish(st,prev,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		}
		if(st[4]!=st[0]||st[5]!=st[1])ec=rg35xxDGDrawVectorStrokeLineTo(st[0],st[1],st,prev,off,miter,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorJoin(st[6],st[7],st[4],st[5],st[2],st[3],st[10],st[11],st[8],st[9],st,prev,miter,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmit(st[0]+st[8],st[1]+st[9],false,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorSinkMove(st[0]-st[8],st[1]-st[9],ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		ec=rg35xxDGDrawVectorEmitReverse(rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		prev[0]=2;return rg35xxDGDrawVectorSinkClose(ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
	}

	private static boolean rg35xxDGDrawVectorEdgeLess(int a,int b,int[] ex,int[] ey,int[] elast)
	{
		if(ey[a]!=ey[b])return ey[a]<ey[b];if(ex[a]!=ex[b])return ex[a]<ex[b];return elast[a]<elast[b];
	}

	private void rg35xxDGDrawVectorAlpha(int[] x,int[] y,int n,int argb)
	{
		if(n<=0)return;
		int pw=platformImage.getRG35XXWidth(),ph=platformImage.getRG35XXHeight();
		int lox=Math.max(0,clipX),loy=Math.max(0,clipY),hix=Math.min(pw,clipX+clipWidth),hiy=Math.min(ph,clipY+clipHeight);
		if(hix<=lox||hiy<=loy)return;
		long capLong=(long)n*16L+64L;if(capLong>2147483647L)throw new OutOfMemoryError();int cap=(int)capLong;
		long revLong=(long)n*8L+32L;if(revLong>2147483647L)throw new OutOfMemoryError();int rcap=(int)revLong;
		int[] ex=new int[cap],ey=new int[cap],elast=new int[cap],eerr=new int[cap],ebx=new int[cap],ebe=new int[cap],ewind=new int[cap];
		float[] rx=new float[rcap],ry=new float[rcap],ps=new float[4],st=new float[12],off=new float[2],miter=new float[2];
		int[] rc=new int[]{0},have=new int[]{0},prev=new int[]{2};
		float sx=(float)Math.floor(((float)(x[0]+translateX))+0.25f)+0.25f;
		float sy=(float)Math.floor(((float)(y[0]+translateY))+0.25f)+0.25f;
		st[0]=st[4]=sx;st[1]=st[5]=sy;st[6]=st[2]=1.0f;st[7]=st[3]=0.0f;prev[0]=0;
		int ec=0;
		for(int i=1;i<n;i++)
		{
			float nx=(float)Math.floor(((float)(x[i]+translateX))+0.25f)+0.25f;
			float ny=(float)Math.floor(((float)(y[i]+translateY))+0.25f)+0.25f;
			ec=rg35xxDGDrawVectorStrokeLineTo(nx,ny,st,prev,off,miter,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		}
		ec=rg35xxDGDrawVectorStrokeClose(st,prev,off,miter,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		if(prev[0]==1)ec=rg35xxDGDrawVectorFinish(st,prev,rx,ry,rc,ps,have,lox,loy,hix,hiy,ex,ey,elast,eerr,ebx,ebe,ewind,ec);
		if(ec==0)return;
		int[] order=new int[ec];for(int i=0;i<ec;i++)order[i]=i;
		for(int i=1;i<ec;i++){int v=order[i],k=i-1;while(k>=0&&rg35xxDGDrawVectorEdgeLess(v,order[k],ex,ey,elast)){order[k+1]=order[k];k--;}order[k+1]=v;}
		int cur=0;while(cur<ec&&elast[order[cur]]<=loy)cur++;int lo=cur,hi=cur,scanY=loy-1;
		int[] dst=platformImage.getRG35XXPixels();
		while(lo<ec)
		{
			if(cur<hi)
			{
				int ei=order[cur],x0=ex[ei];if(x0>=hix){cur=hi;continue;}if(x0<lox)x0=lox;
				int wind=ewind[ei];cur++;int x1;
				while(true){if(cur>=hi){x1=hix;break;}ei=order[cur++];wind+=ewind[ei];if(wind==0){x1=ex[ei];break;}}
				if(x1>hix)x1=hix;if(x1<=x0)continue;
				int base=scanY*pw;for(int px=x0;px<x1;px++){int di=base+px;dst[di]=rg35xxCopyAreaSourceOver(argb,dst[di]);}
				continue;
			}
			scanY++;if(scanY>=hiy)break;
			cur=hi;int newLo=hi;while(--cur>=lo){int ei=order[cur];if(elast[ei]>scanY)order[--newLo]=ei;}lo=newLo;
			if(lo==hi&&lo<ec){int ei=order[lo];if(scanY<ey[ei])scanY=ey[ei];}
			while(hi<ec&&ey[order[hi]]<=scanY)hi++;
			for(cur=lo;cur<hi;cur++)
			{
				int ei=order[cur],x0=ex[ei],y0=ey[ei],err=eerr[ei];y0++;
				if(y0==scanY){x0+=ebx[ei];err+=ebe[ei];x0-=(err>>31);err&=RG35XX_DG_DV_ERRSTEP_MAX;}
				else{long steps=(long)scanY-((long)y0-1L);y0=scanY;x0+=(int)(steps*(long)ebx[ei]);steps=(long)err+steps*(long)ebe[ei];x0+=(int)(steps>>31);err=((int)steps)&RG35XX_DG_DV_ERRSTEP_MAX;}
				ex[ei]=x0;ey[ei]=y0;eerr[ei]=err;
				int pos=cur;while(pos>lo&&ex[order[pos-1]]>x0){order[pos]=order[pos-1];pos--;}order[pos]=ei;
			}
			cur=lo;
		}
	}

	private void rg35xxDGDrawVector(int[] x,int[] y,int n,int argb)
	{
		if(((argb>>>24)&0xFF)==255)rg35xxDGDrawVectorOpaque(x,y,n,argb);else rg35xxDGDrawVectorAlpha(x,y,n,argb);
	}

'''

new_draw_polygon = r'''	public void drawPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)
	{
		int temp = color;
		int[] x = new int[nPoints];
		int[] y = new int[nPoints];
		for(int i=0; i<nPoints; i++)
		{
			x[i] = xPoints[xOffset+i];
			y[i] = yPoints[yOffset+i];
		}
		if(platformImage != null && platformImage.isRG35XXRaw())
		{
			rg35xxDGDrawVector(x, y, nPoints, argbColor);
			return;
		}
		setAlphaRGB(argbColor);
		gc.drawPolygon(x, y, nPoints);
		setColor(temp);
	}
'''

new_draw_triangle = r'''	public void drawTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)
	{
		//System.out.println("drawTriange");
		int temp = color;
		if(platformImage != null && platformImage.isRG35XXRaw())
		{
			rg35xxDGDrawVector(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3, argbColor);
			return;
		}
		setAlphaRGB(argbColor);
		gc.drawPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);
		setColor(temp);
	}
'''

draw_poly_sig = "\tpublic void drawPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n"
draw_tri_sig = "\tpublic void drawTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)\n"
fill_poly_sig = "\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n"
for sig,label in [(draw_poly_sig,"drawPolygon"),(draw_tri_sig,"drawTriangle"),(fill_poly_sig,"fillPolygon")]:
    if s.count(sig) != 1:
        raise SystemExit("P1A_DG_D6_STAGE_FAIL %s signature count=%d" % (label,s.count(sig)))

p0=s.index(draw_poly_sig)
p1=s.index(draw_tri_sig,p0)
p2=s.index(fill_poly_sig,p1)
if not (p0<p1<p2):
    raise SystemExit("P1A_DG_D6_STAGE_FAIL method ordering")

s = s[:p0] + helper + new_draw_polygon + "\n" + new_draw_triangle + "\n" + s[p2:]

required = [
    "rg35xxDGDrawVectorOpaque(",
    "rg35xxDGDrawVectorAdjustLine(",
    "rg35xxDGDrawVectorAlpha(",
    "rg35xxDGDrawVectorStrokeLineTo(",
    "rg35xxDGDrawVectorSinkClose(",
    "rg35xxCopyAreaSourceOver(argb,dst[di])",
    "if(((argb>>>24)&0xFF)==255)",
    "rg35xxDGDrawVector(x, y, nPoints, argbColor);",
    "rg35xxDGDrawVector(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3, argbColor);",
]
for token in required:
    if token not in s:
        raise SystemExit("P1A_DG_D6_STAGE_FAIL missing semantic token: %s" % token)

for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if s.count(forbidden) != parent.count(forbidden):
        raise SystemExit("P1A_DG_D6_STAGE_FAIL game-specific marker delta: %s" % forbidden)

# D6 must not rewrite D4 fill-vector methods or any other source file.
if s.count("rg35xxDGFillPolygonSSI(") != parent.count("rg35xxDGFillPolygonSSI("):
    raise SystemExit("P1A_DG_D6_STAGE_FAIL D4 fill-vector helper drift")

pg.write_text(s, encoding="utf-8")
print("P1A_DG_D6_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_DG_D6_CHANGED_SOURCE=org/recompile/mobile/PlatformGraphics.java")
print("P1A_DG_D6_METHODS=DirectGraphics.drawPolygon,DirectGraphics.drawTriangle")
print("P1A_DG_D6_OPAQUE_BACKEND=OPENJDK8_GENERALRENDERER_DODRAWPOLY_DODRAWLINE_ADJUSTLINE")
print("P1A_DG_D6_ALPHA_BACKEND=D53B_LINE_ONLY_CLOSED_MITER_W1_QUARTER_NORMALIZED_SOFTWARE_SSI")
print("P1A_DG_D6_ALPHA_COMPOSITE=G1_EXACT_8BIT_SRCOVER")
print("P1A_DG_D6_CORE2D_CHANGE=NO")
print("P1A_DG_D6_NATIVE_CHANGE=NO")
print("P1A_DG_D6_GAME_SPECIFIC_MARKER_DELTA=NO")
print("P1A_DG_D6_STAGE=PASS")
