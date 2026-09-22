#!/usr/bin/env python3
"""R2D metric-scaled Unicode bitmap text renderer.

Bypasses GNU Classpath AWT/OpenType glyph rasterization on the normal MIDP/DoJa
text path while preserving upstream font metrics for layout.
"""
from pathlib import Path
import sys

if len(sys.argv)!=2:
    raise SystemExit("usage: r2d_apply_metric_bitmap_font.py <PlatformGraphics.java>")

p=Path(sys.argv[1])
s=p.read_text(encoding="utf-8")
orig=s

if "RG35XX-R2D-METRIC-BITMAP-FONT" in s:
    raise SystemExit("R2D FONT FAIL: already patched")

ctor="\tpublic PlatformGraphics(PlatformImage image)\n"
if s.count(ctor)!=1:
    raise SystemExit("R2D FONT FAIL: constructor anchor count=%d"%s.count(ctor))

block=r'''
	/* RG35XX-R2D-METRIC-BITMAP-FONT
	 *
	 * Normal text never enters GNU Classpath drawGlyphVector/drawString.
	 * The Unicode bitmap resource keeps the recovered Golden record/index
	 * contract, while each glyph is scaled into the active MIDP font metrics.
	 * This avoids both the compound-glyph crashes and the old fixed-advance
	 * layout mismatch.
	 */
	private static final String RG35XX_R2D_FONT_RESOURCE="/org/recompile/mobile/rg35xx-font.bin";
	private static final int RG35XX_R2D_FONT_BYTES=727008;
	private static final int RG35XX_R2D_GLYPH_BYTES=32;
	private static final int RG35XX_R2D_GLYPH_COUNT=22719;
	private static final int[] rg35xxR2DRangeStart={
		0x0020,0x00A0,0x0370,0x0400,0x1E00,0x3000,0x3040,0x30A0,0x4E00,0xFF00
	};
	private static final int[] rg35xxR2DRangeEnd={
		0x007E,0x024F,0x03FF,0x052F,0x1EFF,0x303F,0x309F,0x30FF,0x9FFF,0xFFEF
	};
	private static final int[] rg35xxR2DRangeOffset={
		0,95,527,671,975,1231,1295,1391,1487,22479
	};
	private static boolean rg35xxR2DFontTried=false;
	private static byte[] rg35xxR2DFontData=null;

	private static synchronized void rg35xxR2DEnsureFont()
	{
		if(rg35xxR2DFontTried) return;
		rg35xxR2DFontTried=true;
		java.io.InputStream in=null;
		try
		{
			in=PlatformGraphics.class.getResourceAsStream(RG35XX_R2D_FONT_RESOURCE);
			if(in==null)
			{
				System.err.println("RG35XX-R2D-FONT: resource missing");
				return;
			}
			byte[] data=new byte[RG35XX_R2D_FONT_BYTES];
			int used=0;
			while(used<data.length)
			{
				int n=in.read(data,used,data.length-used);
				if(n<0) break;
				if(n==0) continue;
				used+=n;
			}
			if(used!=data.length)
			{
				System.err.println("RG35XX-R2D-FONT: short read bytes="+used);
				return;
			}
			rg35xxR2DFontData=data;
			System.err.println("RG35XX-R2D-FONT: ready bytes="+data.length);
		}
		catch(Throwable t)
		{
			System.err.println("RG35XX-R2D-FONT: load failed "+t);
		}
		finally
		{
			if(in!=null) try { in.close(); } catch(Throwable ignored) { }
		}
	}

	private static int rg35xxR2DGlyphIndex(char ch)
	{
		int c=ch;
		for(int i=0;i<rg35xxR2DRangeStart.length;i++)
		{
			if(c>=rg35xxR2DRangeStart[i] && c<=rg35xxR2DRangeEnd[i])
			{
				int index=rg35xxR2DRangeOffset[i]+c-rg35xxR2DRangeStart[i];
				if(index>=0 && index<RG35XX_R2D_GLYPH_COUNT) return index;
				break;
			}
		}
		return 31;
	}

	private static boolean rg35xxR2DWide(char ch)
	{
		int c=ch;
		return (c>=0x3000&&c<=0x30FF)||(c>=0x4E00&&c<=0x9FFF)||(c>=0xFF00&&c<=0xFFEF);
	}

	private int rg35xxR2DCharAdvance(char ch)
	{
		int w;
		if(Mobile.isDoJa) w=dojaFont.stringWidth(String.valueOf(ch));
		else w=font.charWidth(ch);
		return w>0 ? w : 1;
	}

	private int rg35xxR2DFontHeight()
	{
		int h=Mobile.isDoJa ? dojaFont.getHeight() : font.getHeight();
		return h>0 ? h : 1;
	}

	private void rg35xxR2DPutPixel(int x,int y,int argb,int minX,int minY,int maxX,int maxY)
	{
		if(x<minX||x>=maxX||y<minY||y>=maxY||x<0||x>=canvasWidth||y<0||y>=canvasHeight) return;
		int idx=y*canvasWidth+x;
		if(((argb>>>24)&0xFF)==255) canvasData[idx]=argb;
		else canvasData[idx]=blendPixels(argb,canvasData[idx]);
	}

	private void rg35xxR2DDrawQuestion(int x,int y,int w,int h,int argb,int minX,int minY,int maxX,int maxY)
	{
		final int[] rows={14,17,1,2,4,0,4};
		for(int dy=0;dy<h;dy++)
		{
			int sy=(dy*7)/h;
			int bits=rows[sy];
			for(int dx=0;dx<w;dx++)
			{
				int sx=(dx*5)/w;
				if((bits&(1<<(4-sx)))!=0)
					rg35xxR2DPutPixel(x+dx,y+dy,argb,minX,minY,maxX,maxY);
			}
		}
	}

	private void rg35xxR2DDrawMetricText(String str,int x,int topY)
	{
		if(str==null||str.length()==0) return;
		rg35xxR2DEnsureFont();

		int penX=x+translateX;
		int py0=topY+translateY;
		int minX=Math.max(0,getClipX()+translateX);
		int minY=Math.max(0,getClipY()+translateY);
		int maxX=Math.min(canvasWidth,getClipX()+translateX+getClipWidth());
		int maxY=Math.min(canvasHeight,getClipY()+translateY+getClipHeight());
		int h=rg35xxR2DFontHeight();
		int argb=getColor();
		if(!Mobile.isDoJa) argb=(getAlphaComponent()<<24)|(argb&0x00FFFFFF);
		else argb|=0xFF000000;

		for(int i=0;i<str.length();i++)
		{
			char ch=str.charAt(i);
			int adv=rg35xxR2DCharAdvance(ch);
			if(ch==' ') { penX+=adv; continue; }
			int srcW=rg35xxR2DWide(ch)?12:8;
			int glyph=rg35xxR2DGlyphIndex(ch);

			if(rg35xxR2DFontData==null || glyph<0 || glyph>=RG35XX_R2D_GLYPH_COUNT)
			{
				rg35xxR2DDrawQuestion(penX,py0,adv,h,argb,minX,minY,maxX,maxY);
				penX+=adv;
				continue;
			}

			int base=glyph*RG35XX_R2D_GLYPH_BYTES;
			for(int dy=0;dy<h;dy++)
			{
				int sy=(dy*16)/h;
				int off=base+sy*2;
				int mask=((rg35xxR2DFontData[off]&0xFF)<<8)|(rg35xxR2DFontData[off+1]&0xFF);
				for(int dx=0;dx<adv;dx++)
				{
					int sx=(dx*srcW)/adv;
					if((mask&(1<<(15-sx)))!=0)
						rg35xxR2DPutPixel(penX+dx,py0+dy,argb,minX,minY,maxX,maxY);
				}
			}
			penX+=adv;
		}
	}

'''
s=s.replace(ctor,block+ctor,1)

draw="\t\t\tgc.drawString(str, x, y);\n"
if s.count(draw)!=1:
    raise SystemExit("R2D FONT FAIL: gc.drawString boundary count=%d"%s.count(draw))
s=s.replace(draw,"\t\t\trg35xxR2DDrawMetricText(str, x, y - ascent);\n",1)

required=(
 "RG35XX-R2D-METRIC-BITMAP-FONT",
 "rg35xxR2DDrawMetricText(str, x, y - ascent);",
 "font.charWidth(ch)",
 "dojaFont.stringWidth(String.valueOf(ch))",
 "RG35XX_R2D_FONT_BYTES=727008",
 "rg35xxR2DPutPixel"
)
for tok in required:
    if tok not in s: raise SystemExit("R2D FONT FAIL missing "+tok)
if "gc.drawString(str, x, y);" in s:
    raise SystemExit("R2D FONT FAIL: AWT normal text boundary survived")
if s==orig:
    raise SystemExit("R2D FONT FAIL: no mutation")

p.write_text(s,encoding="utf-8",newline="\n")
print("R2D_METRIC_BITMAP_FONT_PATCH=PASS")
print("AWT_GLYPH_RASTER=NORMAL_PATH_BYPASSED")
print("LAYOUT=ACTIVE_MIDP_METRICS")
print("RESOURCE=RECONSTRUCTED_OR_EXACT_GOLDEN_CONTRACT")
