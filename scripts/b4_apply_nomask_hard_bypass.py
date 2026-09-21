#!/usr/bin/env python3
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: b4_apply_nomask_hard_bypass.py <PlatformGraphics.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

# R2 is intentionally layered on top of the R1 gate.  R1 proved insufficient
# on device because MIDP/Nokia backlight APIs can legitimately set
# Mobile.renderLCDMask=true again.  On RG35XX we preserve that state/API but
# never use lcdMaskColors[] to alter game pixels.
old_fast = 'fastBlit = (!Mobile.renderLCDMask || Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;'
new_fast = 'fastBlit = !Mobile.funLightsEnabled;'

old_pixel = 'canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & (Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);'
new_pixel = 'canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i];'

def replace_once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit('B4 VIDEO MASK R2 FAIL %s count=%d' % (label, n))
    return text.replace(old, new, 1)

s = replace_once(s, old_fast, new_fast, 'R1 fastBlit anchor')
s = replace_once(s, old_pixel, new_pixel, 'R1 slow-path mask anchor')

if s == orig:
    raise SystemExit('B4 VIDEO MASK R2 FAIL no mutation')

for token in (new_fast, new_pixel):
    if token not in s:
        raise SystemExit('B4 VIDEO MASK R2 FAIL missing postcondition: ' + token)

for forbidden in (
    old_fast,
    old_pixel,
    'image.getDataBuffer()[srcRowIndex + i] & Mobile.lcdMaskColors[Mobile.maskIndex]',
):
    if forbidden in s:
        raise SystemExit('B4 VIDEO MASK R2 FAIL mask application still present: ' + forbidden)

p.write_text(s, encoding='utf-8', newline='\n')
print('B4_VIDEO_MASK_R2_PATCH=PASS')
print('PRIMARY_VARIABLE=RG35XX_SOFTWARE_LCD_MASK_BYPASS_ONLY')
print('RENDER_LCD_MASK_STATE=PRESERVED_BUT_NOT_APPLIED_TO_PIXELS')
print('FUNLIGHTS=PRESERVED')
print('HOTPATH_CLEANUP=NOT_INCLUDED')
print('AUDIO_CHANGE=NONE')
