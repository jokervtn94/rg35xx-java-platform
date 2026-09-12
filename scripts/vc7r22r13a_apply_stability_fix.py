#!/usr/bin/env python3
import pathlib,sys
root=pathlib.Path(sys.argv[1])
p=root/'org/recompile/freej2me/RG35XXGoldenFrameTransport.java'
s=p.read_text(encoding='utf-8')
old='''        synchronized(lock)\n        {\n            System.arraycopy(data, 0, snapshot, 0, pixels);\n        }\n'''
new='''        System.arraycopy(data, 0, snapshot, 0, pixels);\n'''
if s.count(old)!=1:
    raise SystemExit('snapshot lock anchor mismatch')
p.write_text(s.replace(old,new,1),encoding='utf-8',newline='\n')
removed=0
for q in root.rglob('*.java'):
    t=q.read_text(encoding='utf-8')
    lines=t.splitlines(True)
    out=[]
    for line in lines:
        if 'RG35XX-VC7R13-IMAGE-CREATE' in line:
            removed+=1
            continue
        out.append(line)
    if out!=lines:
        q.write_text(''.join(out),encoding='utf-8',newline='\n')
if removed<1:
    raise SystemExit('no image-create markers removed')
print('VC7R22-R1.3A_STABILITY_FIX=PASS')
print('FRAME_SNAPSHOT=LOCK_FREE_BEST_EFFORT')
print('IMAGE_CREATE_LINES_REMOVED=%d'%removed)
