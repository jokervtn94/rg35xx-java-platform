#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 3:
    raise SystemExit('usage: vc7r11_apply_graphics_state_probe.py <PlatformGraphics.java> <RG35XXGoldenFrameTransport.java>')

g = pathlib.Path(sys.argv[1])
t = pathlib.Path(sys.argv[2])
s = g.read_text(encoding='utf-8')
u = t.read_text(encoding='utf-8')
orig_s, orig_u = s, u

if 'RG35XX-VC7R11-GFXSTATE' in s or 'RG35XX-VC7R11-FRAME-BIND' in u:
    raise SystemExit('VC7R11 probe already applied')

def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit('VC7R11 FAIL %s count=%d' % (label, n))
    return text.replace(old, new, 1)

# Add bounded diagnostic counters beside the existing FPS state.
s = once(s,
'''\tprivate static int frameCount = 0;\n''',
'''\tprivate static int frameCount = 0;\n\t/* RG35XX-VC7R11-GFXSTATE: diagnostic only; rendering semantics unchanged. */\n\tprivate static int vc7r11CtorCount = 0;\n\tprivate static int vc7r11ResetCount = 0;\n\tprivate static int vc7r11DrawRgbCount = 0;\n''',
'counter fields')

# Constructor binding: exact PlatformImage/BufferedImage/int[] identities and initial clip.
s = once(s,
'''\t\tcanvasData = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\n\t\t// This command is always required for MascotCapsuleV3 command lists, and DoJa does not initialize it.''',
'''\t\tcanvasData = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\n\t\tif(vc7r11CtorCount < 64)\n\t\t{\n\t\t\tvc7r11CtorCount++;\n\t\t\tSystem.err.println("RG35XX-VC7R11-GFXSTATE: CTOR n=" + vc7r11CtorCount\n\t\t\t\t+ " gfxId=" + System.identityHashCode(this)\n\t\t\t\t+ " baseImageId=" + System.identityHashCode(baseImage)\n\t\t\t\t+ " canvasId=" + System.identityHashCode(canvas)\n\t\t\t\t+ " dataId=" + System.identityHashCode(canvasData)\n\t\t\t\t+ " size=" + canvasWidth + "x" + canvasHeight);\n\t\t}\n\n\t\t// This command is always required for MascotCapsuleV3 command lists, and DoJa does not initialize it.''',
'constructor binding')

# Reset state after origin and clip have both been established.
s = once(s,
'''\t\tsetClip(clipx, clipy, clipw, cliph);\n\t\tsetColor(0,0,0);''',
'''\t\tsetClip(clipx, clipy, clipw, cliph);\n\t\tif(vc7r11ResetCount < 96)\n\t\t{\n\t\t\tvc7r11ResetCount++;\n\t\t\tSystem.err.println("RG35XX-VC7R11-GFXSTATE: RESET n=" + vc7r11ResetCount\n\t\t\t\t+ " gfxId=" + System.identityHashCode(this)\n\t\t\t\t+ " baseImageId=" + System.identityHashCode(baseImage)\n\t\t\t\t+ " dataId=" + System.identityHashCode(canvasData)\n\t\t\t\t+ " translate=" + translateX + "," + translateY\n\t\t\t\t+ " clipFields=" + clipX + "," + clipY + "," + clipWidth + "," + clipHeight\n\t\t\t\t+ " clipGet=" + getClipX() + "," + getClipY() + "," + getClipWidth() + "," + getClipHeight());\n\t\t}\n\t\tsetColor(0,0,0);''',
'reset state')

# drawRGB state: after translation but before clipping. This is the common software blit path.
s = once(s,
'''\t\tx += translateX;\n\t\ty += translateY;\n\n\t\tfinal int clipLeft = Math.max(x, Math.max(0, getClipX() + translateX));''',
'''\t\tx += translateX;\n\t\ty += translateY;\n\n\t\tif(vc7r11DrawRgbCount < 192)\n\t\t{\n\t\t\tvc7r11DrawRgbCount++;\n\t\t\tfinal int vc7r11Left = Math.max(x, Math.max(0, getClipX() + translateX));\n\t\t\tfinal int vc7r11Top = Math.max(y, Math.max(0, getClipY() + translateY));\n\t\t\tfinal int vc7r11Right = Math.min(x + width, Math.min(canvasWidth, getClipWidth() + getClipX() + translateX));\n\t\t\tfinal int vc7r11Bottom = Math.min(y + height, Math.min(canvasHeight, getClipHeight() + getClipY() + translateY));\n\t\t\tSystem.err.println("RG35XX-VC7R11-GFXSTATE: DRAWRGB n=" + vc7r11DrawRgbCount\n\t\t\t\t+ " gfxId=" + System.identityHashCode(this)\n\t\t\t\t+ " baseImageId=" + System.identityHashCode(baseImage)\n\t\t\t\t+ " canvasId=" + System.identityHashCode(canvas)\n\t\t\t\t+ " dataId=" + System.identityHashCode(canvasData)\n\t\t\t\t+ " canvas=" + canvasWidth + "x" + canvasHeight\n\t\t\t\t+ " dstTranslated=" + x + "," + y + " size=" + width + "x" + height\n\t\t\t\t+ " translate=" + translateX + "," + translateY\n\t\t\t\t+ " clipFields=" + clipX + "," + clipY + "," + clipWidth + "," + clipHeight\n\t\t\t\t+ " clipGet=" + getClipX() + "," + getClipY() + "," + getClipWidth() + "," + getClipHeight()\n\t\t\t\t+ " effective=" + vc7r11Left + "," + vc7r11Top + "," + vc7r11Right + "," + vc7r11Bottom\n\t\t\t\t+ " srcDataId=" + System.identityHashCode(rgbData) + " offset=" + offset + " scan=" + scanlength\n\t\t\t\t+ " alpha=" + processAlpha);\n\t\t}\n\n\t\tfinal int clipLeft = Math.max(x, Math.max(0, getClipX() + translateX));''',
'drawRGB state')

# requestFrame already has a stable diagnostic line from the verified-clean transport.
old = 'System.err.println("RG35XX-JAVA-DIAG: requestFrame ENTER " + w + "x" + h + " data=" + (data == null ? -1 : data.length) + " lock=" + (lock == null ? "null" : lock.getClass().getName()));'
new = 'System.err.println("RG35XX-JAVA-DIAG: requestFrame ENTER " + w + "x" + h + " data=" + (data == null ? -1 : data.length) + " lock=" + (lock == null ? "null" : lock.getClass().getName()) + " RG35XX-VC7R11-FRAME-BIND dataId=" + System.identityHashCode(data) + " lockId=" + System.identityHashCode(lock));'
if u.count(old) != 1:
    raise SystemExit('VC7R11 FAIL requestFrame diagnostic anchor count=%d' % u.count(old))
u = u.replace(old, new, 1)

for req in ('RG35XX-VC7R11-GFXSTATE', 'CTOR n=', 'RESET n=', 'DRAWRGB n=', 'effective=', 'dataId='):
    if req not in s:
        raise SystemExit('VC7R11 FAIL missing PlatformGraphics marker ' + req)
if 'RG35XX-VC7R11-FRAME-BIND' not in u:
    raise SystemExit('VC7R11 FAIL frame binding marker missing')
if s == orig_s or u == orig_u:
    raise SystemExit('VC7R11 FAIL no mutation')

g.write_text(s, encoding='utf-8', newline='\n')
t.write_text(u, encoding='utf-8', newline='\n')
print('VC7R11_GRAPHICS_STATE_PROBE=PASS')
print('SCOPE=GFX_OBJECT,BASEIMAGE,CANVAS,DATABUFFER,RESET,CLIP,TRANSLATE,EFFECTIVE_DRAWRGB,FRAME_BINDING')
