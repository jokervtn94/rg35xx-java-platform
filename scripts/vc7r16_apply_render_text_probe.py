#!/usr/bin/env python3
import pathlib,re,sys

if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r16_apply_render_text_probe.py <PlatformGraphics.java>')
p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
if 'RG35XX-VC7R16-TRANSFORM' in s or 'RG35XX-VC7R16-TEXT' in s:
    raise SystemExit('VC7R16 probe already applied')

# Add bounded counters near the existing static frame counter.
anchor='\tprivate static int frameCount = 0;\n'
if s.count(anchor)!=1:
    raise SystemExit('VC7R16 frame counter anchor mismatch')
s=s.replace(anchor,anchor+'\tprivate static int vc7r16TransformCount = 0;\n\tprivate static int vc7r16TextCount = 0;\n',1)

# MIDP drawRegion probe. Keep semantics unchanged; only observe non-TRANS_NONE calls.
pat=re.compile(r'(\tpublic void drawRegion\(Image image, int sx, int sy, int swidth, int sheight, int transform, int x, int y, int anchor\)\n\t\{\n)')
m=pat.search(s)
if not m:
    raise SystemExit('VC7R16 drawRegion signature not found')
block=m.group(1)+'''\t\tif(transform != Sprite.TRANS_NONE && vc7r16TransformCount < 256)\n\t\t{\n\t\t\tvc7r16TransformCount++;\n\t\t\tPlatformImage pi = (image == null ? null : image.platformImage);\n\t\t\tint[] src = (pi == null ? null : pi.getDataBuffer());\n\t\t\tint sn = (src == null ? 0 : src.length);\n\t\t\tint s0 = sn > 0 ? src[0] : 0;\n\t\t\tint sm = sn > 0 ? src[sn/2] : 0;\n\t\t\tint sl = sn > 0 ? src[sn-1] : 0;\n\t\t\tSystem.err.println("RG35XX-VC7R16-TRANSFORM: n=" + vc7r16TransformCount\n\t\t\t\t+ " transform=" + transform + " srcRect=" + sx + "," + sy + "," + swidth + "," + sheight\n\t\t\t\t+ " dst=" + x + "," + y + " anchor=" + anchor\n\t\t\t\t+ " srcImageId=" + System.identityHashCode(pi)\n\t\t\t\t+ " srcDataId=" + System.identityHashCode(src)\n\t\t\t\t+ " dstImageId=" + System.identityHashCode(baseImage)\n\t\t\t\t+ " dstDataId=" + System.identityHashCode(canvasData)\n\t\t\t\t+ " clip=" + getClipX() + "," + getClipY() + "," + getClipWidth() + "," + getClipHeight()\n\t\t\t\t+ " trans=" + getTranslateX() + "," + getTranslateY()\n\t\t\t\t+ " sample=" + Integer.toHexString(s0) + "," + Integer.toHexString(sm) + "," + Integer.toHexString(sl));\n\t\t}\n'''
s=s[:m.start()]+block+s[m.end():]

# Text probe at drawStringSingleLine entry. Log Unicode codepoints without changing raster path.
pat2=re.compile(r'(\tprivate void drawStringSingleLine\(String str, int x, int y, int anchor\)\n\t\{\n)')
m=pat2.search(s)
if not m:
    raise SystemExit('VC7R16 drawStringSingleLine signature not found')
block2=m.group(1)+'''\t\tif(str != null && str.length() > 0 && vc7r16TextCount < 256)\n\t\t{\n\t\t\tvc7r16TextCount++;\n\t\t\tStringBuffer cp = new StringBuffer();\n\t\t\tint lim = Math.min(str.length(), 16);\n\t\t\tfor(int i=0;i<lim;i++)\n\t\t\t{\n\t\t\t\tif(i>0) cp.append(',');\n\t\t\t\tcp.append(Integer.toHexString((int)str.charAt(i)));\n\t\t\t}\n\t\t\tSystem.err.println("RG35XX-VC7R16-TEXT: n=" + vc7r16TextCount\n\t\t\t\t+ " len=" + str.length() + " cps=" + cp.toString()\n\t\t\t\t+ " x=" + x + " y=" + y + " anchor=" + anchor\n\t\t\t\t+ " fontH=" + (Mobile.isDoJa ? dojaFont.getHeight() : font.getHeight())\n\t\t\t\t+ " color=" + Integer.toHexString(getColor())\n\t\t\t\t+ " clip=" + getClipX() + "," + getClipY() + "," + getClipWidth() + "," + getClipHeight());\n\t\t}\n'''
s=s[:m.start()]+block2+s[m.end():]

for tok in ('RG35XX-VC7R16-TRANSFORM','RG35XX-VC7R16-TEXT'):
    if tok not in s:
        raise SystemExit('VC7R16 missing marker '+tok)
p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R16_RENDER_TEXT_PROBE=PASS')
