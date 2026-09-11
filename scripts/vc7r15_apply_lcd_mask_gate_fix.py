#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit('usage: vc7r15_apply_lcd_mask_gate_fix.py <PlatformGraphics.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

if 'RG35XX-VC7R15-LCD-MASK' in s:
    raise SystemExit('VC7R15 already applied')

def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit('VC7R15 FAIL %s count=%d' % (label, n))
    return text.replace(old, new, 1)

# FreeJ2ME upstream currently leaves the renderLCDMask test commented out here.
# With Mobile.maskIndex defaulting to 1 (green), the libretro headless path can
# therefore tint every flush even though Mobile.renderLCDMask is false.
old = 'fastBlit = (/*!Mobile.renderLCDMask || */ Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;'
new = '''fastBlit = (!Mobile.renderLCDMask || Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;\n\t\t\tif(vc7r14FlushCount <= 128)\n\t\t\t{\n\t\t\t\tSystem.err.println("RG35XX-VC7R15-LCD-MASK: render=" + Mobile.renderLCDMask\n\t\t\t\t\t+ " maskIndex=" + Mobile.maskIndex\n\t\t\t\t\t+ " maskColor=" + Integer.toHexString(Mobile.lcdMaskColors[Mobile.maskIndex])\n\t\t\t\t\t+ " funLights=" + Mobile.funLightsEnabled\n\t\t\t\t\t+ " fastBlit=" + fastBlit);\n\t\t\t}'''
s = once(s, old, new, 'fastBlit gate')

# If the slow path is active only because FunLights are enabled, do not apply an
# LCD tint unless renderLCDMask explicitly requests it.
old = 'canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & Mobile.lcdMaskColors[Mobile.maskIndex]; //(Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);'
new = 'canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & (Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);'
s = once(s, old, new, 'slow-path mask gate')

for req in (
    'RG35XX-VC7R15-LCD-MASK',
    '(!Mobile.renderLCDMask || Mobile.maskIndex == 0)',
    '(Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF)',
):
    if req not in s:
        raise SystemExit('VC7R15 missing marker/gate ' + req)

if s == orig:
    raise SystemExit('VC7R15 no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('VC7R15_LCD_MASK_GATE_FIX=PASS')
print('SCOPE=PLATFORMGRAPHICS_FLUSH_RENDERLCDMASK_GATE_ONLY')
