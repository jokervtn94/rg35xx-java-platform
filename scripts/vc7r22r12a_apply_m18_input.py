#!/usr/bin/env python3
from pathlib import Path
import shutil,sys
root=Path(sys.argv[1])
repo=Path(sys.argv[2])
mobile=root/'src/org/recompile/mobile'
for n in ('M1Input.java','M1InputDispatch.java'):
    shutil.copy2(repo/'miyoo-m1/m1_8'/n,mobile/n)
p=root/'src/org/recompile/freej2me/Libretro.java'
s=p.read_text()
old='import org.recompile.mobile.MobilePlatform;'
if s.count(old)!=1: raise SystemExit('M1.8 fail-closed: MobilePlatform import anchor')
s=s.replace(old,old+'\nimport org.recompile.mobile.M1InputDispatch;',1)
old='\tLibretroIO lio;'
if s.count(old)!=1: raise SystemExit('M1.8 fail-closed: LibretroIO field anchor')
s=s.replace(old,old+'\n\tprivate final M1InputDispatch m1InputDispatch = new M1InputDispatch();',1)
rel='\t\t\t\t\t\t\tcase 2:\t// joypad key up\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = false;\n\t\t\t\t\t\t\t\tMobilePlatform.keyReleased(Mobile.getMobileKey(code));\n\t\t\t\t\t\t\tbreak;'
pre='\t\t\t\t\t\t\tcase 3: // joypad key down\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = true;\n\t\t\t\t\t\t\t\tMobilePlatform.keyPressed(Mobile.getMobileKey(code));\n\t\t\t\t\t\t\tbreak;'
if s.count(rel)!=1 or s.count(pre)!=1: raise SystemExit('M1.8 fail-closed: legacy dispatch blocks changed')
s=s.replace(rel,'\t\t\t\t\t\t\tcase 2:\t// M1.8 consumes legacy key-up; raw js0 is sole gameplay owner\n\t\t\t\t\t\t\tbreak;',1)
s=s.replace(pre,'\t\t\t\t\t\t\tcase 3: // M1.8 consumes legacy key-down; raw js0 is sole gameplay owner\n\t\t\t\t\t\t\tbreak;',1)
anchor='\t\t\t\t\tif (count==5)\n\t\t\t\t\t{\n\t\t\t\t\t\tcount = 0;'
if s.count(anchor)!=1: raise SystemExit('M1.8 fail-closed: packet cadence anchor')
s=s.replace(anchor,anchor+'\n\t\t\t\t\t\tm1InputDispatch.poll(System.currentTimeMillis());',1)
p.write_text(s)
print('VC7R22_R12A_M18_PATCH=PASS')
