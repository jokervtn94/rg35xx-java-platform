#!/usr/bin/env python3
import pathlib,re,sys

if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r21_apply_legacy_whitekey.py <PlatformImage.java>')

p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s

# VC7R21 handles a second, non-PNG-standard transparency convention observed on
# device: old J2ME assets with no alpha/tRNS but a pure-white background connected
# to the image border. Do NOT make all white pixels transparent. Only border-
# connected pure white is keyed, and only when the border strongly looks like a
# sprite matte. Standards-defined VC7R20 tRNS remains higher priority.
anchor='\tprivate static BufferedImage rg35xxNormalizeDecodedImage(BufferedImage image)\n'
if s.count(anchor)!=1:
    raise SystemExit('VC7R21: normalize anchor count=%d'%s.count(anchor))

helper='''\tprivate static int rg35xxVC7R21WhiteKeyLogCount;\n\n\tprivate static boolean rg35xxVC7R21PureWhite(int pixel)\n\t{\n\t\treturn (pixel & 0x00FFFFFF) == 0x00FFFFFF;\n\t}\n\n\tprivate static int rg35xxVC7R21ApplyLegacyBorderWhiteKey(int[] pixels, int w, int h)\n\t{\n\t\tif(pixels==null || w<2 || h<2 || pixels.length<w*h) return 0;\n\t\t/* Never infer legacy color-key semantics for screen-sized images. */\n\t\tif(w>=240 && h>=240) return 0;\n\n\t\tint borderTotal=(w*2)+((h-2)*2);\n\t\tint borderWhite=0;\n\t\tfor(int x=0;x<w;x++)\n\t\t{\n\t\t\tif(rg35xxVC7R21PureWhite(pixels[x])) borderWhite++;\n\t\t\tif(rg35xxVC7R21PureWhite(pixels[(h-1)*w+x])) borderWhite++;\n\t\t}\n\t\tfor(int y=1;y<h-1;y++)\n\t\t{\n\t\t\tif(rg35xxVC7R21PureWhite(pixels[y*w])) borderWhite++;\n\t\t\tif(rg35xxVC7R21PureWhite(pixels[y*w+w-1])) borderWhite++;\n\t\t}\n\n\t\tint corners=0;\n\t\tif(rg35xxVC7R21PureWhite(pixels[0])) corners++;\n\t\tif(rg35xxVC7R21PureWhite(pixels[w-1])) corners++;\n\t\tif(rg35xxVC7R21PureWhite(pixels[(h-1)*w])) corners++;\n\t\tif(rg35xxVC7R21PureWhite(pixels[h*w-1])) corners++;\n\n\t\t/* Require a strong matte signal: at least two white corners and 35% white\n\t\t * border, or an overwhelmingly white (>=60%) border. */\n\t\tboolean matte=(corners>=2 && borderWhite*100>=borderTotal*35) ||\n\t\t\t(borderWhite*100>=borderTotal*60);\n\t\tif(!matte) return 0;\n\n\t\tint nonWhite=0;\n\t\tfor(int i=0;i<w*h;i++) if(!rg35xxVC7R21PureWhite(pixels[i])) nonWhite++;\n\t\t/* Do not turn blank/near-blank white canvases into transparent images. */\n\t\tif(nonWhite<8 || nonWhite*100 < w*h) return 0;\n\n\t\t/* Preserve VC7R18's opaque repair for all non-key pixels first. */\n\t\tfor(int i=0;i<w*h;i++) pixels[i] |= 0xFF000000;\n\n\t\tint[] queue=new int[w*h];\n\t\tint head=0, tail=0, changed=0;\n\t\t/* Mark a white pixel transparent when queued; alpha=0 doubles as visited. */\n\t\tfor(int x=0;x<w;x++)\n\t\t{\n\t\t\tint a=x, b=(h-1)*w+x;\n\t\t\tif(rg35xxVC7R21PureWhite(pixels[a]) && (pixels[a]>>>24)!=0) { pixels[a]=0x00FFFFFF; queue[tail++]=a; changed++; }\n\t\t\tif(b!=a && rg35xxVC7R21PureWhite(pixels[b]) && (pixels[b]>>>24)!=0) { pixels[b]=0x00FFFFFF; queue[tail++]=b; changed++; }\n\t\t}\n\t\tfor(int y=1;y<h-1;y++)\n\t\t{\n\t\t\tint a=y*w, b=y*w+w-1;\n\t\t\tif(rg35xxVC7R21PureWhite(pixels[a]) && (pixels[a]>>>24)!=0) { pixels[a]=0x00FFFFFF; queue[tail++]=a; changed++; }\n\t\t\tif(b!=a && rg35xxVC7R21PureWhite(pixels[b]) && (pixels[b]>>>24)!=0) { pixels[b]=0x00FFFFFF; queue[tail++]=b; changed++; }\n\t\t}\n\n\t\twhile(head<tail)\n\t\t{\n\t\t\tint q=queue[head++];\n\t\t\tint x=q%w, y=q/w;\n\t\t\tint n;\n\t\t\tif(x>0) { n=q-1; if(rg35xxVC7R21PureWhite(pixels[n]) && (pixels[n]>>>24)!=0) { pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }\n\t\t\tif(x+1<w) { n=q+1; if(rg35xxVC7R21PureWhite(pixels[n]) && (pixels[n]>>>24)!=0) { pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }\n\t\t\tif(y>0) { n=q-w; if(rg35xxVC7R21PureWhite(pixels[n]) && (pixels[n]>>>24)!=0) { pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }\n\t\t\tif(y+1<h) { n=q+w; if(rg35xxVC7R21PureWhite(pixels[n]) && (pixels[n]>>>24)!=0) { pixels[n]=0x00FFFFFF; queue[tail++]=n; changed++; } }\n\t\t}\n\n\t\tif(changed>0 && rg35xxVC7R21WhiteKeyLogCount++<16)\n\t\t\tSystem.err.println("RG35XX-VC7R21-LEGACY-WHITEKEY: size="+w+"x"+h+\n\t\t\t\t" borderWhite="+borderWhite+"/"+borderTotal+" corners="+corners+" changed="+changed);\n\t\treturn changed;\n\t}\n\n'''
s=s.replace(anchor,helper+anchor,1)

pat=re.compile(r'\tprivate static BufferedImage rg35xxNormalizeDecodedImage\(BufferedImage image\)\n\t\{.*?\n\t\}\n\n(?=\tpublic PlatformImage\(int Width, int Height\))',re.S)
m=pat.search(s)
if not m:
    raise SystemExit('VC7R21: normalization method not found')
method='''\tprivate static BufferedImage rg35xxNormalizeDecodedImage(BufferedImage image)\n\t{\n\t\tfinal int w=image.getWidth();\n\t\tfinal int h=image.getHeight();\n\t\tfinal boolean sourceHasAlpha=image.getColorModel().hasAlpha();\n\t\tfinal boolean hasTrns=rg35xxVC7R20PngTransparency.get()!=null;\n\t\tfinal int[] pixels=image.getRGB(0,0,w,h,null,0,w);\n\t\tfinal int trnsChanged=rg35xxVC7R20ApplyPngTransparency(pixels);\n\n\t\t/* VC7R21 policy order:\n\t\t * 1. real alpha channel -> preserve decoder alpha;\n\t\t * 2. PNG tRNS metadata -> VC7R20 exact semantics;\n\t\t * 3. only for no-alpha/no-tRNS legacy assets, conservatively recognize a\n\t\t *    border-connected pure-white sprite matte;\n\t\t * 4. otherwise use VC7R18 opaque repair. */\n\t\tif(!sourceHasAlpha && !hasTrns)\n\t\t{\n\t\t\tfinal int legacyChanged=rg35xxVC7R21ApplyLegacyBorderWhiteKey(pixels,w,h);\n\t\t\tif(legacyChanged==0)\n\t\t\t\tfor(int i=0;i<pixels.length;i++) pixels[i] |= 0xFF000000;\n\t\t}\n\n\t\tfinal BufferedImage normalized=new BufferedImage(w,h,BufferedImage.TYPE_INT_ARGB);\n\t\tfinal int[] dst=((DataBufferInt)normalized.getRaster().getDataBuffer()).getData();\n\t\tSystem.arraycopy(pixels,0,dst,0,pixels.length);\n\t\treturn normalized;\n\t}\n\n'''
s=s[:m.start()]+method+s[m.end():]

for token in ('RG35XX-VC7R21-LEGACY-WHITEKEY','rg35xxVC7R21ApplyLegacyBorderWhiteKey','final boolean hasTrns=rg35xxVC7R20PngTransparency.get()!=null','!sourceHasAlpha && !hasTrns'):
    if token not in s:
        raise SystemExit('VC7R21 missing token '+token)
if s==orig:
    raise SystemExit('VC7R21: no mutation')

p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R21_LEGACY_BORDER_WHITEKEY=PASS')
print('POLICY=REAL_ALPHA_THEN_TRNS_THEN_CONSERVATIVE_BORDER_WHITEKEY_THEN_OPAQUE')
print('GLOBAL_WHITE_TRANSPARENCY=FORBIDDEN')
