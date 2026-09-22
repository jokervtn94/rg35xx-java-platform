#!/usr/bin/env python3
"""R2C transparency semantics on top of R2A.

Preserve R2A direct getRGB normalization, then:
1) recover standards-defined PNG tRNS metadata from the raw PNG bytes before
   GNU Classpath ImageIO sees the sanitized stream;
2) re-apply tRNS alpha after decode;
3) for old no-alpha/no-tRNS sprite assets only, conservatively key a
   border-connected pure-white matte.

Global white-as-transparent is forbidden.
"""
from pathlib import Path
import re, sys

if len(sys.argv)!=2:
    raise SystemExit("usage: r2c_apply_transparency_semantics.py <PlatformImage.java>")

p=Path(sys.argv[1])
s=p.read_text(encoding="utf-8")
orig=s

if "RG35XX-R2C-PNG-TRNS" in s:
    raise SystemExit("R2C TRANSPARENCY FAIL: already patched")

# Insert tRNS metadata helpers before existing R1 PNG iCCP helper.
anchor="\tprivate static InputStream rg35xxPngIccpCompat(InputStream input) throws IOException\n"
if s.count(anchor)!=1:
    raise SystemExit("R2C TRANSPARENCY FAIL: PNG helper anchor count=%d"%s.count(anchor))

helper=r'''
	private static final ThreadLocal rg35xxR2CTransparency = new ThreadLocal();
	private static int rg35xxR2CLogBudget = 24;

	private static final class RG35XXR2CTransparency
	{
		final int[] rgb;
		final int[] alpha;
		RG35XXR2CTransparency(int[] rgb, int[] alpha) { this.rgb=rgb; this.alpha=alpha; }
	}

	private static int rg35xxR2CU16(byte[] b, int p)
	{
		return ((b[p]&0xFF)<<8)|(b[p+1]&0xFF);
	}

	private static int rg35xxR2CChunkLength(byte[] raw, int p)
	{
		long n=((long)(raw[p]&0xFF)<<24)|((long)(raw[p+1]&0xFF)<<16)|
		       ((long)(raw[p+2]&0xFF)<<8)|(long)(raw[p+3]&0xFF);
		return (n<0 || n>Integer.MAX_VALUE) ? -1 : (int)n;
	}

	private static void rg35xxR2CCaptureTransparency(byte[] raw)
	{
		rg35xxR2CTransparency.set(null);
		if(raw==null || raw.length<33 ||
		   (raw[0]&0xFF)!=0x89 || raw[1]!=0x50 || raw[2]!=0x4E || raw[3]!=0x47 ||
		   raw[4]!=0x0D || raw[5]!=0x0A || raw[6]!=0x1A || raw[7]!=0x0A) return;

		int bitDepth=-1, colorType=-1;
		byte[] plte=null, trns=null;
		int pos=8;
		while(pos+12<=raw.length)
		{
			int len=rg35xxR2CChunkLength(raw,pos);
			if(len<0 || pos+12L+len>raw.length) return;
			int d=pos+8;
			boolean ihdr=raw[pos+4]=='I'&&raw[pos+5]=='H'&&raw[pos+6]=='D'&&raw[pos+7]=='R';
			boolean palette=raw[pos+4]=='P'&&raw[pos+5]=='L'&&raw[pos+6]=='T'&&raw[pos+7]=='E';
			boolean trans=raw[pos+4]=='t'&&raw[pos+5]=='R'&&raw[pos+6]=='N'&&raw[pos+7]=='S';
			boolean iend=raw[pos+4]=='I'&&raw[pos+5]=='E'&&raw[pos+6]=='N'&&raw[pos+7]=='D';
			if(ihdr && len>=13) { bitDepth=raw[d+8]&0xFF; colorType=raw[d+9]&0xFF; }
			else if(palette) { plte=new byte[len]; System.arraycopy(raw,d,plte,0,len); }
			else if(trans) { trns=new byte[len]; System.arraycopy(raw,d,trns,0,len); }
			pos+=len+12;
			if(iend) break;
		}
		if(trns==null || trns.length==0) return;

		if(colorType==3 && plte!=null)
		{
			int count=Math.min(trns.length,plte.length/3);
			int[] rgb=new int[count]; int[] alpha=new int[count];
			for(int i=0;i<count;i++)
			{
				rgb[i]=((plte[i*3]&0xFF)<<16)|((plte[i*3+1]&0xFF)<<8)|(plte[i*3+2]&0xFF);
				alpha[i]=trns[i]&0xFF;
			}
			rg35xxR2CTransparency.set(new RG35XXR2CTransparency(rgb,alpha));
		}
		else if(colorType==2 && bitDepth==8 && trns.length>=6)
		{
			int r=rg35xxR2CU16(trns,0)&0xFF;
			int g=rg35xxR2CU16(trns,2)&0xFF;
			int b=rg35xxR2CU16(trns,4)&0xFF;
			rg35xxR2CTransparency.set(new RG35XXR2CTransparency(
				new int[]{(r<<16)|(g<<8)|b},new int[]{0}));
		}
		else if(colorType==0 && bitDepth==8 && trns.length>=2)
		{
			int g=rg35xxR2CU16(trns,0)&0xFF;
			rg35xxR2CTransparency.set(new RG35XXR2CTransparency(
				new int[]{(g<<16)|(g<<8)|g},new int[]{0}));
		}
	}

	private static int rg35xxR2CApplyPngTransparency(int[] pixels)
	{
		RG35XXR2CTransparency meta=(RG35XXR2CTransparency)rg35xxR2CTransparency.get();
		rg35xxR2CTransparency.set(null);
		if(meta==null || pixels==null) return -1;
		int changed=0;
		for(int i=0;i<pixels.length;i++)
		{
			int rgb=pixels[i]&0x00FFFFFF;
			for(int k=0;k<meta.rgb.length;k++)
			{
				if(rgb==meta.rgb[k])
				{
					int next=(meta.alpha[k]<<24)|rgb;
					if(next!=pixels[i]) { pixels[i]=next; changed++; }
					break;
				}
			}
		}
		return changed;
	}

	private static boolean rg35xxR2CPureWhite(int pixel)
	{
		return (pixel&0x00FFFFFF)==0x00FFFFFF;
	}

	private static int rg35xxR2CApplyLegacyBorderWhiteKey(int[] pixels,int w,int h)
	{
		if(pixels==null || w<2 || h<2 || pixels.length<w*h) return 0;
		if(w>=240 && h>=240) return 0;

		int borderTotal=(w*2)+((h-2)*2);
		int borderWhite=0;
		for(int x=0;x<w;x++)
		{
			if(rg35xxR2CPureWhite(pixels[x])) borderWhite++;
			if(rg35xxR2CPureWhite(pixels[(h-1)*w+x])) borderWhite++;
		}
		for(int y=1;y<h-1;y++)
		{
			if(rg35xxR2CPureWhite(pixels[y*w])) borderWhite++;
			if(rg35xxR2CPureWhite(pixels[y*w+w-1])) borderWhite++;
		}
		int corners=0;
		if(rg35xxR2CPureWhite(pixels[0])) corners++;
		if(rg35xxR2CPureWhite(pixels[w-1])) corners++;
		if(rg35xxR2CPureWhite(pixels[(h-1)*w])) corners++;
		if(rg35xxR2CPureWhite(pixels[h*w-1])) corners++;

		boolean matte=(corners>=2 && borderWhite*100>=borderTotal*35) ||
		              (borderWhite*100>=borderTotal*60);
		if(!matte) return 0;

		int nonWhite=0;
		for(int i=0;i<w*h;i++) if(!rg35xxR2CPureWhite(pixels[i])) nonWhite++;
		if(nonWhite<8 || nonWhite*100 < w*h) return 0;

		int[] queue=new int[w*h];
		int head=0,tail=0,changed=0;
		for(int x=0;x<w;x++)
		{
			int a=x,b=(h-1)*w+x;
			if(rg35xxR2CPureWhite(pixels[a]) && (pixels[a]>>>24)!=0)
			{ pixels[a]=0x00FFFFFF; queue[tail++]=a; changed++; }
			if(b!=a && rg35xxR2CPureWhite(pixels[b]) && (pixels[b]>>>24)!=0)
			{ pixels[b]=0x00FFFFFF; queue[tail++]=b; changed++; }
		}
		for(int y=1;y<h-1;y++)
		{
			int a=y*w,b=y*w+w-1;
			if(rg35xxR2CPureWhite(pixels[a]) && (pixels[a]>>>24)!=0)
			{ pixels[a]=0x00FFFFFF; queue[tail++]=a; changed++; }
			if(b!=a && rg35xxR2CPureWhite(pixels[b]) && (pixels[b]>>>24)!=0)
			{ pixels[b]=0x00FFFFFF; queue[tail++]=b; changed++; }
		}
		while(head<tail)
		{
			int q=queue[head++],x=q%w,y=q/w,n;
			if(x>0) { n=q-1; if(rg35xxR2CPureWhite(pixels[n])&&(pixels[n]>>>24)!=0)
				{ pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }
			if(x+1<w) { n=q+1; if(rg35xxR2CPureWhite(pixels[n])&&(pixels[n]>>>24)!=0)
				{ pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }
			if(y>0) { n=q-w; if(rg35xxR2CPureWhite(pixels[n])&&(pixels[n]>>>24)!=0)
				{ pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }
			if(y+1<h) { n=q+w; if(rg35xxR2CPureWhite(pixels[n])&&(pixels[n]>>>24)!=0)
				{ pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }
		}
		return changed;
	}

'''
s=s.replace(anchor,helper+anchor,1)

raw_anchor="\t\tbyte[] raw = rawOut.toByteArray();\n"
if s.count(raw_anchor)!=1:
    raise SystemExit("R2C TRANSPARENCY FAIL: raw PNG anchor count=%d"%s.count(raw_anchor))
s=s.replace(raw_anchor,raw_anchor+"\t\trg35xxR2CCaptureTransparency(raw);\n",1)

# Replace the R2A normalization method.
pat=re.compile(r'\tprivate static BufferedImage rg35xxR2ANormalizeDecodedImage\(BufferedImage image\)\n\t\{.*?\n\t\}\n\n',re.S)
m=pat.search(s)
if not m:
    raise SystemExit("R2C TRANSPARENCY FAIL: R2A normalize method not found")
method=r'''	private static BufferedImage rg35xxR2ANormalizeDecodedImage(BufferedImage image)
	{
		if(image==null) { rg35xxR2CTransparency.set(null); return null; }
		final int w=image.getWidth();
		final int h=image.getHeight();
		if(w<=0 || h<=0) { rg35xxR2CTransparency.set(null); return image; }

		final boolean hasTrns=rg35xxR2CTransparency.get()!=null;
		final int type=image.getType();
		final int[] pixels=image.getRGB(0,0,w,h,null,0,w);

		boolean meaningfulAlpha=false;
		int alphaZero=0, alphaPartial=0;
		for(int i=0;i<pixels.length;i++)
		{
			int a=(pixels[i]>>>24)&0xFF;
			if(a!=0xFF) meaningfulAlpha=true;
			if(a==0) alphaZero++;
			else if(a!=0xFF) alphaPartial++;
		}

		final int trnsChanged=rg35xxR2CApplyPngTransparency(pixels);
		int whiteKeyChanged=0;
		if(!meaningfulAlpha && !hasTrns)
			whiteKeyChanged=rg35xxR2CApplyLegacyBorderWhiteKey(pixels,w,h);

		final BufferedImage normalized=new BufferedImage(w,h,BufferedImage.TYPE_INT_ARGB);
		final int[] dst=((DataBufferInt)normalized.getRaster().getDataBuffer()).getData();
		System.arraycopy(pixels,0,dst,0,pixels.length);

		if(rg35xxR2CLogBudget>0)
		{
			rg35xxR2CLogBudget--;
			System.err.println("RG35XX-R2C-TRANSPARENCY size="+w+"x"+h+
				" type="+type+" alpha0="+alphaZero+" alphaPartial="+alphaPartial+
				" trns="+hasTrns+" trnsChanged="+trnsChanged+
				" whiteKeyChanged="+whiteKeyChanged);
		}
		return normalized;
	}

'''
s=s[:m.start()]+method+s[m.end():]

required=(
 "RG35XX-R2C-TRANSPARENCY",
 "rg35xxR2CCaptureTransparency(raw)",
 "rg35xxR2CApplyPngTransparency(pixels)",
 "rg35xxR2CApplyLegacyBorderWhiteKey",
 "whiteKeyChanged",
 "GLOBAL_WHITE_TRANSPARENCY" # only checked below through absence comment? don't require
)
for tok in required[:-1]:
    if tok not in s: raise SystemExit("R2C TRANSPARENCY FAIL missing "+tok)

if s.count("ImageIO.read(rg35xxPngIccpCompat(stream))")!=3:
    raise SystemExit("R2C TRANSPARENCY FAIL: PNG decode boundaries changed")
if "ImageIO.read(stream)" in s:
    raise SystemExit("R2C TRANSPARENCY FAIL: unguarded ImageIO survived")
if "pixels[i] = 0x00FFFFFF" in s:
    # exact global rewrite pattern would be suspicious; flood-fill writes named indices only.
    raise SystemExit("R2C TRANSPARENCY FAIL: suspicious global white-key rewrite")
if s==orig:
    raise SystemExit("R2C TRANSPARENCY FAIL: no mutation")

p.write_text(s,encoding="utf-8",newline="\n")
print("R2C_TRANSPARENCY_PATCH=PASS")
print("ORDER=MEANINGFUL_ALPHA_THEN_PNG_TRNS_THEN_BORDER_WHITEKEY")
print("GLOBAL_WHITE_TRANSPARENCY=FORBIDDEN")
