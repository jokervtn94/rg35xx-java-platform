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

def strip_marker_prints(text, marker):
    removed=0
    pos=0
    token='System.err.println('
    while True:
        start=text.find(token,pos)
        if start<0:
            break
        par=text.find('(',start+len('System.err.println'))
        depth=0
        i=par
        in_str=False
        in_char=False
        esc=False
        close=-1
        while i<len(text):
            c=text[i]
            if in_str:
                if esc: esc=False
                elif c=='\\': esc=True
                elif c=='"': in_str=False
            elif in_char:
                if esc: esc=False
                elif c=='\\': esc=True
                elif c=="'": in_char=False
            else:
                if c=='"': in_str=True
                elif c=="'": in_char=True
                elif c=='(': depth+=1
                elif c==')':
                    depth-=1
                    if depth==0:
                        close=i
                        break
            i+=1
        if close<0:
            raise SystemExit('unterminated println')
        semi=close+1
        while semi<len(text) and text[semi] in ' \t\r':
            semi+=1
        if semi>=len(text) or text[semi]!=';':
            pos=start+len(token)
            continue
        end=semi+1
        stmt=text[start:end]
        if marker not in stmt:
            pos=end
            continue
        line_start=text.rfind('\n',0,start)+1
        if text[line_start:start].strip()=='':
            start=line_start
        while end<len(text) and text[end] in ' \t\r':
            end+=1
        if end<len(text) and text[end]=='\n':
            end+=1
        text=text[:start]+text[end:]
        removed+=1
        pos=start
    return text,removed

removed=0
for q in root.rglob('*.java'):
    t=q.read_text(encoding='utf-8')
    nt,n=strip_marker_prints(t,'RG35XX-VC7R13-IMAGE-CREATE')
    if n:
        q.write_text(nt,encoding='utf-8',newline='\n')
        removed+=n
if removed<1:
    raise SystemExit('no image-create probes removed')
print('VC7R22-R1.3A_STABILITY_FIX=PASS')
print('FRAME_SNAPSHOT=LOCK_FREE_BEST_EFFORT')
print('IMAGE_CREATE_PRINTS_REMOVED=%d'%removed)
