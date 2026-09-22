#!/usr/bin/env python3
import pathlib, sys
if len(sys.argv)!=2:
    raise SystemExit('usage: b4_apply_nomask_green_tint_fix.py <PlatformGraphics.java>')
p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s
old1='fastBlit = (/*!Mobile.renderLCDMask || */ Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;'
new1='fastBlit = (!Mobile.renderLCDMask || Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;'
old2='canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & Mobile.lcdMaskColors[Mobile.maskIndex]; //(Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);'
new2='canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & (Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);'
for label,old,new in [('fast gate',old1,new1),('slow gate',old2,new2)]:
    n=s.count(old)
    if n!=1:
        raise SystemExit('B4 MASK FIX FAIL %s count=%d'%(label,n))
    s=s.replace(old,new,1)
if s==orig:
    raise SystemExit('B4 MASK FIX no mutation')
for token in [new1,new2]:
    if token not in s:
        raise SystemExit('B4 MASK FIX missing postcondition')
p.write_text(s,encoding='utf-8',newline='\n')
print('B4_VIDEO_MASK_R1_PATCH=PASS')
print('PRIMARY_VARIABLE=PLATFORMGRAPHICS_LCD_MASK_GATE_ONLY')
print('DIAGNOSTIC_DELTA=NONE')
