#!/usr/bin/env python3
import pathlib,re,sys

if len(sys.argv)!=5:
    raise SystemExit('usage: vc7r19_apply_transparency_stability_fix.py <PlatformGraphics.java> <PlatformImage.java> <MobilePlatform.java> <Libretro.java>')

pg=pathlib.Path(sys.argv[1]); pi=pathlib.Path(sys.argv[2]); mp=pathlib.Path(sys.argv[3]); lr=pathlib.Path(sys.argv[4])
s=pg.read_text(encoding='utf-8'); i=pi.read_text(encoding='utf-8'); m=mp.read_text(encoding='utf-8'); l=lr.read_text(encoding='utf-8')

# ---------------------------------------------------------------------------
# 1) Runtime stability: remove diagnostic writes from rendering/frame hot paths.
# VC7R18 only bounded two log sources. Device evidence still produced >20k lines
# because VC7R12/14/16 probes printed on every frame/full-screen flush.
# ---------------------------------------------------------------------------
marker_re = re.compile(r'\n[ \t]*System\.err\.println\("RG35XX-(?:VC7R9|VC7R11|VC7R12|VC7R13|VC7R14|VC7R15|VC7R16|JAVA-DIAG)[^;]*?;\n', re.S)
removed=0
for name,text in [('PlatformGraphics',s),('MobilePlatform',m),('Libretro',l)]:
    new,n=marker_re.subn('\n',text)
    removed+=n
    if name=='PlatformGraphics': s=new
    elif name=='MobilePlatform': m=new
    else: l=new

# Disable VC7R10 per-image file logging entirely. Keep the helper/counters so
# earlier source transforms still compile, but never open/append an SD file.
pat_log=re.compile(r'\tprivate static void rg35xxVC7R10Log\(String message\)\n\t\{.*?\n\t\}\n',re.S)
if not pat_log.search(i):
    raise SystemExit('VC7R19: VC7R10 log helper not found')
i=pat_log.sub('\tprivate static void rg35xxVC7R10Log(String message)\n\t{\n\t\t// VC7R19: disabled on-device image hot-path logging.\n\t}\n',i,1)

# ---------------------------------------------------------------------------
# 2) Transparency: bypass Graphics2D/affine transform for unscaled sprite
# transforms. Device evidence proves transform=0 drawRGB preserves alpha-0
# color-key pixels (e.g. 00F800F8), so reuse that exact software alpha path.
# Only exact-size transforms are intercepted; scaled/DoJa cases keep upstream.
# ---------------------------------------------------------------------------
sig='\tpublic void drawTransformedImage(PlatformImage image, int dx, int dy, int width, int height, int sx, int sy, int swidth, int sheight, int transform)\n\t{\n'
if s.count(sig)!=1:
    raise SystemExit('VC7R19: drawTransformedImage signature count=%d'%s.count(sig))
insert='''\tpublic void drawTransformedImage(PlatformImage image, int dx, int dy, int width, int height, int sx, int sy, int swidth, int sheight, int transform)\n\t{\n\t\tif(rg35xxVC7R19SoftwareTransform(image, dx, dy, width, height, sx, sy, swidth, sheight, transform)) { return; }\n'''
s=s.replace(sig,insert,1)

helper_anchor='\tpublic void drawTransformedImage(PlatformImage image, int dx, int dy, int width, int height, int sx, int sy, int swidth, int sheight, int transform)\n'
helper='''\t/* VC7R19: exact-size software sprite transform. Keeps raw ARGB values and\n\t * delegates final compositing to drawRGB(processAlpha=true), whose alpha-0\n\t * behavior is device-proven. No Graphics2D is used on this path. */\n\tprivate boolean rg35xxVC7R19SoftwareTransform(PlatformImage image, int dx, int dy, int width, int height,\n\t\tint sx, int sy, int swidth, int sheight, int transform)\n\t{\n\t\tif(image == null || transform == FLIP_NONE || swidth <= 0 || sheight <= 0) return false;\n\t\tif(sx < 0 || sy < 0 || sx + swidth > image.getWidth() || sy + sheight > image.getHeight()) return false;\n\n\t\tfinal boolean rotate90 = (transform == FLIP_ROTATE_RIGHT || transform == FLIP_ROTATE_LEFT ||\n\t\t\ttransform == FLIP_ROTATE_RIGHT_VERTICAL || transform == FLIP_ROTATE_RIGHT_HORIZONTAL);\n\t\tfinal int outW = rotate90 ? sheight : swidth;\n\t\tfinal int outH = rotate90 ? swidth : sheight;\n\t\tif(width != outW || height != outH) return false; // scaling stays upstream\n\n\t\tfinal int[] src = image.getDataBuffer();\n\t\tif(src == null) return false;\n\t\tfinal int[] out = new int[outW * outH];\n\t\tfinal int srcStride = image.getWidth();\n\n\t\tfor(int y=0; y<sheight; y++)\n\t\t{\n\t\t\tint srcRow=(sy+y)*srcStride+sx;\n\t\t\tfor(int x=0; x<swidth; x++)\n\t\t\t{\n\t\t\t\tint ox=x, oy=y;\n\t\t\t\tswitch(transform)\n\t\t\t\t{\n\t\t\t\t\tcase FLIP_HORIZONTAL: ox=swidth-1-x; oy=y; break;\n\t\t\t\t\tcase FLIP_VERTICAL: ox=x; oy=sheight-1-y; break;\n\t\t\t\t\tcase FLIP_ROTATE: ox=swidth-1-x; oy=sheight-1-y; break;\n\t\t\t\t\tcase FLIP_ROTATE_RIGHT: ox=sheight-1-y; oy=x; break;\n\t\t\t\t\tcase FLIP_ROTATE_LEFT: ox=y; oy=swidth-1-x; break;\n\t\t\t\t\tcase FLIP_ROTATE_RIGHT_VERTICAL: ox=sheight-1-y; oy=swidth-1-x; break;\n\t\t\t\t\tcase FLIP_ROTATE_RIGHT_HORIZONTAL: ox=y; oy=x; break;\n\t\t\t\t\tdefault: return false;\n\t\t\t\t}\n\t\t\t\tout[oy*outW+ox]=src[srcRow+x];\n\t\t\t}\n\t\t}\n\n\t\tdrawRGB(out, 0, outW, dx, dy, outW, outH, true);\n\t\treturn true;\n\t}\n\n'''
idx=s.find(helper_anchor)
if idx<0: raise SystemExit('VC7R19: helper insertion anchor missing')
s=s[:idx]+helper+s[idx:]

# Clean up two VC7R18 diagnostics that are not useful after device diagnosis.
# Leave functional alpha repair exactly intact.
i=i.replace(' + " RG35XX-VC7R18-ALPHA"','')

for tok in ('rg35xxVC7R19SoftwareTransform(', 'drawRGB(out, 0, outW, dx, dy, outW, outH, true)', 'pixels[i] |= 0xFF000000'):
    if tok not in s+i:
        raise SystemExit('VC7R19 required token missing: '+tok)

# Prohibit the known hot-path diagnostic markers in assembled Java sources.
combined=s+'\n'+i+'\n'+m+'\n'+l
for bad in ('RG35XX-VC7R14-FLUSH-BRIDGE','RG35XX-VC7R14-MOBILE-FLUSH','RG35XX-VC7R12-FRAME-BIND: REQUEST','RG35XX-VC7R16-TRANSFORM','RG35XX-VC7R16-TEXT','RG35XX-JAVA-DIAG:'):
    if 'System.err.println("'+bad in combined:
        raise SystemExit('VC7R19 hot-path logger survived: '+bad)

pg.write_text(s,encoding='utf-8',newline='\n')
pi.write_text(i,encoding='utf-8',newline='\n')
mp.write_text(m,encoding='utf-8',newline='\n')
lr.write_text(l,encoding='utf-8',newline='\n')
print('VC7R19_TRANSPARENCY_STABILITY_FIX=PASS')
print('HOT_PATH_DIAGNOSTIC_WRITES_REMOVED=%d'%removed)
print('TRANSFORM_ALPHA_PATH=SOFTWARE_EXACT_SIZE_ONLY')
print('SCALED_TRANSFORMS=UPSTREAM_FALLBACK')
