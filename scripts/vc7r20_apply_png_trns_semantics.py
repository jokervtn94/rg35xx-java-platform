#!/usr/bin/env python3
import pathlib,re,sys

if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r20_apply_png_trns_semantics.py <PlatformImage.java>')

p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s

# VC7R20 reuses the raw PNG bytes already materialized by VC6's iCCP compatibility
# boundary. Capture standards-defined PNG tRNS metadata before ImageIO sees the
# sanitized stream, then re-apply the alpha semantics after GNU Classpath decode.
# This is intentionally NOT a global "white is transparent" heuristic.
helper_anchor='\tprivate static InputStream rg35xxPngIccpCompat(InputStream input) throws IOException\n'
if s.count(helper_anchor)!=1:
    raise SystemExit('VC7R20: PNG compatibility helper anchor count=%d'%s.count(helper_anchor))

helper='''\tprivate static final ThreadLocal rg35xxVC7R20PngTransparency = new ThreadLocal();
\tprivate static int rg35xxVC7R20TrnsLogCount;

\tprivate static final class RG35XXPngTransparency
\t{
\t\tfinal int[] rgb;
\t\tfinal int[] alpha;
\t\tRG35XXPngTransparency(int[] rgb, int[] alpha) { this.rgb=rgb; this.alpha=alpha; }
\t}

\tprivate static int rg35xxVC7R20U16(byte[] b, int p)
\t{
\t\treturn ((b[p] & 0xFF) << 8) | (b[p+1] & 0xFF);
\t}

\tprivate static int rg35xxVC7R20ChunkLength(byte[] raw, int p)
\t{
\t\tlong n=((long)(raw[p]&0xFF)<<24)|((long)(raw[p+1]&0xFF)<<16)|((long)(raw[p+2]&0xFF)<<8)|(long)(raw[p+3]&0xFF);
\t\treturn (n<0 || n>Integer.MAX_VALUE) ? -1 : (int)n;
\t}

\tprivate static void rg35xxVC7R20CapturePngTransparency(byte[] raw)
\t{
\t\trg35xxVC7R20PngTransparency.set(null);
\t\tif(raw==null || raw.length<33 || (raw[0]&0xFF)!=0x89 || raw[1]!=0x50 || raw[2]!=0x4E || raw[3]!=0x47 ||
\t\t\traw[4]!=0x0D || raw[5]!=0x0A || raw[6]!=0x1A || raw[7]!=0x0A) return;

\t\tint bitDepth=-1, colorType=-1;
\t\tbyte[] plte=null, trns=null;
\t\tint pos=8;
\t\twhile(pos+12<=raw.length)
\t\t{
\t\t\tint len=rg35xxVC7R20ChunkLength(raw,pos);
\t\t\tif(len<0 || pos+12L+len>raw.length) return;
\t\t\tint d=pos+8;
\t\t\tboolean ihdr=raw[pos+4]=='I'&&raw[pos+5]=='H'&&raw[pos+6]=='D'&&raw[pos+7]=='R';
\t\t\tboolean palette=raw[pos+4]=='P'&&raw[pos+5]=='L'&&raw[pos+6]=='T'&&raw[pos+7]=='E';
\t\t\tboolean trans=raw[pos+4]=='t'&&raw[pos+5]=='R'&&raw[pos+6]=='N'&&raw[pos+7]=='S';
\t\t\tboolean iend=raw[pos+4]=='I'&&raw[pos+5]=='E'&&raw[pos+6]=='N'&&raw[pos+7]=='D';
\t\t\tif(ihdr && len>=13) { bitDepth=raw[d+8]&0xFF; colorType=raw[d+9]&0xFF; }
\t\t\telse if(palette) { plte=new byte[len]; System.arraycopy(raw,d,plte,0,len); }
\t\t\telse if(trans) { trns=new byte[len]; System.arraycopy(raw,d,trns,0,len); }
\t\t\tpos+=len+12;
\t\t\tif(iend) break;
\t\t}
\t\tif(trns==null || trns.length==0) return;

\t\tif(colorType==3 && plte!=null)
\t\t{
\t\t\tint count=Math.min(trns.length, plte.length/3);
\t\t\tint[] rgb=new int[count]; int[] alpha=new int[count];
\t\t\tfor(int i=0;i<count;i++)
\t\t\t{
\t\t\t\trgb[i]=((plte[i*3]&0xFF)<<16)|((plte[i*3+1]&0xFF)<<8)|(plte[i*3+2]&0xFF);
\t\t\t\talpha[i]=trns[i]&0xFF;
\t\t\t}
\t\t\trg35xxVC7R20PngTransparency.set(new RG35XXPngTransparency(rgb,alpha));
\t\t}
\t\telse if(colorType==2 && bitDepth==8 && trns.length>=6)
\t\t{
\t\t\tint r=rg35xxVC7R20U16(trns,0)&0xFF, g=rg35xxVC7R20U16(trns,2)&0xFF, b=rg35xxVC7R20U16(trns,4)&0xFF;
\t\t\trg35xxVC7R20PngTransparency.set(new RG35XXPngTransparency(new int[]{(r<<16)|(g<<8)|b},new int[]{0}));
\t\t}
\t\telse if(colorType==0 && bitDepth==8 && trns.length>=2)
\t\t{
\t\t\tint g=rg35xxVC7R20U16(trns,0)&0xFF;
\t\t\trg35xxVC7R20PngTransparency.set(new RG35XXPngTransparency(new int[]{(g<<16)|(g<<8)|g},new int[]{0}));
\t\t}
\t}

\tprivate static int rg35xxVC7R20ApplyPngTransparency(int[] pixels)
\t{
\t\tRG35XXPngTransparency meta=(RG35XXPngTransparency)rg35xxVC7R20PngTransparency.get();
\t\trg35xxVC7R20PngTransparency.set(null);
\t\tif(meta==null || pixels==null) return 0;
\t\tint changed=0;
\t\tfor(int i=0;i<pixels.length;i++)
\t\t{
\t\t\tint rgb=pixels[i]&0x00FFFFFF;
\t\t\tfor(int k=0;k<meta.rgb.length;k++)
\t\t\t{
\t\t\t\tif(rgb==meta.rgb[k])
\t\t\t\t{
\t\t\t\t\tint a=meta.alpha[k];
\t\t\t\t\tint next=(a<<24)|rgb;
\t\t\t\t\tif(next!=pixels[i]) { pixels[i]=next; changed++; }
\t\t\t\t\tbreak;
\t\t\t\t}
\t\t\t}
\t\t}
\t\tif(rg35xxVC7R20TrnsLogCount++<16)
\t\t\tSystem.err.println("RG35XX-VC7R20-PNG-TRNS: keys="+meta.rgb.length+" changed="+changed);
\t\treturn changed;
\t}

'''
s=s.replace(helper_anchor,helper+helper_anchor,1)

raw_anchor='\t\tbyte[] raw = rawOut.toByteArray();\n'
if s.count(raw_anchor)!=1:
    raise SystemExit('VC7R20: raw PNG anchor count=%d'%s.count(raw_anchor))
s=s.replace(raw_anchor,raw_anchor+'\t\trg35xxVC7R20CapturePngTransparency(raw);\n',1)

# Replace VC7R10/18 normalization method wholesale. Preserve direct getRGB and
# the VC7R18 no-alpha repair, but ONLY after tRNS semantics have had priority.
pat=re.compile(r'\tprivate static BufferedImage rg35xxNormalizeDecodedImage\(BufferedImage image\)\n\t\{.*?\n\t\}\n\n(?=\tpublic PlatformImage\(int Width, int Height\))',re.S)
m=pat.search(s)
if not m:
    raise SystemExit('VC7R20: normalization method not found')
method='''\tprivate static BufferedImage rg35xxNormalizeDecodedImage(BufferedImage image)
\t{
\t\tfinal int w=image.getWidth();
\t\tfinal int h=image.getHeight();
\t\tfinal boolean sourceHasAlpha=image.getColorModel().hasAlpha();
\t\tfinal int[] pixels=image.getRGB(0,0,w,h,null,0,w);
\t\tfinal int trnsChanged=rg35xxVC7R20ApplyPngTransparency(pixels);

\t\t/* VC7R20 policy: PNG tRNS wins over the old opaque repair. Only images
\t\t * with neither a real alpha channel nor recovered tRNS metadata are made
\t\t * opaque. This avoids turning standards-defined transparent palette/key
\t\t * pixels into 0xFFFFFFFF while keeping VC7R18's GNU Classpath workaround
\t\t * for genuinely opaque TYPE_CUSTOM/RGB images. */
\t\tif(!sourceHasAlpha && trnsChanged==0)
\t\t{
\t\t\tfor(int i=0;i<pixels.length;i++) pixels[i] |= 0xFF000000;
\t\t}

\t\tfinal BufferedImage normalized=new BufferedImage(w,h,BufferedImage.TYPE_INT_ARGB);
\t\tfinal int[] dst=((DataBufferInt)normalized.getRaster().getDataBuffer()).getData();
\t\tSystem.arraycopy(pixels,0,dst,0,pixels.length);
\t\treturn normalized;
\t}

'''
s=s[:m.start()]+method+s[m.end():]

for token in ('RG35XX-VC7R20-PNG-TRNS','rg35xxVC7R20CapturePngTransparency(raw)','trnsChanged==0','rg35xxVC7R20ApplyPngTransparency(pixels)'):
    if token not in s:
        raise SystemExit('VC7R20 missing token '+token)
if 'if(!sourceHasAlpha)\n\t\t{' in s:
    raise SystemExit('VC7R20: unconditional VC7R18 opaque repair survived')
if s==orig:
    raise SystemExit('VC7R20: no mutation')

p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R20_PNG_TRNS_SEMANTICS=PASS')
print('POLICY=TRNS_METADATA_FIRST_THEN_OPAQUE_REPAIR')
print('WHITE_COLOR_HEURISTIC=DISABLED')
