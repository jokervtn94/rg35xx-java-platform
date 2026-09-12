#!/usr/bin/env python3
import pathlib,re,sys
if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r22r13d_apply_native_frame_trace.py <rg35xx_golden_video.c>')
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding='utf-8'); orig=s

def once(old,new,label):
    global s
    n=s.count(old)
    if n!=1: raise SystemExit('R13D %s anchor count=%d'%(label,n))
    s=s.replace(old,new,1)

def match_paren(text, start):
    depth=0; ins=False; inc=False; esc=False
    for i in range(start,len(text)):
        c=text[i]
        if ins:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c=='"': ins=False
            continue
        if inc:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c=="'": inc=False
            continue
        if c=='"': ins=True; continue
        if c=="'": inc=True; continue
        if c=='(': depth+=1
        elif c==')':
            depth-=1
            if depth==0: return i
    return -1

def match_brace(text,start):
    depth=0; ins=False; inc=False; esc=False
    for i in range(start,len(text)):
        c=text[i]
        if ins:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c=='"': ins=False
            continue
        if inc:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c=="'": inc=False
            continue
        if c=='"': ins=True; continue
        if c=="'": inc=True; continue
        if c=='{': depth+=1
        elif c=='}':
            depth-=1
            if depth==0: return i
    return -1

# Extend existing B4 observability state. No video/audio semantics changed.
once('    int obs_first_present;\n};', '''    int obs_first_present;\n\n    unsigned long r13d_headers;\n    unsigned long r13d_payloads;\n    unsigned long r13d_publishes;\n    unsigned long r13d_present_calls;\n};''', 'state')

# Header stage: immediately after the receiver has a complete/resynced header.
once('        if(!read_header_resync(header, &w, &h, &rotation)) break;\n\n        pixels = (size_t)w * (size_t)h;', '''        if(!read_header_resync(header, &w, &h, &rotation)) break;\n\n        g.r13d_headers++;\n        if(g.r13d_headers <= 8ul || (g.r13d_headers % 120ul)==0ul)\n            rg35xx_b4_video_log("R13D NATIVE READ_HEADER_DONE n=%lu src=%ux%u rot=%u",\n                                g.r13d_headers, w, h, rotation);\n\n        pixels = (size_t)w * (size_t)h;''', 'header')

# Payload stage: locate the first read_exact call after read_header_resync inside
# receiver_main. Do not depend on one-line formatting; generated source has changed
# formatting across checkpoints. BEGIN is inserted immediately before the owning
# statement and DONE immediately after it, so failed reads that break/return never
# emit DONE.
rm=re.search(r'static void \*receiver_main\(.*?\n\}',s,re.S)
if not rm: raise SystemExit('R13D receiver_main not found')
r=rm.group(0)
hpos=r.find('read_header_resync')
if hpos<0: raise SystemExit('R13D receiver header call not found')
call=r.find('read_exact(',hpos)
if call<0: raise SystemExit('R13D receiver payload read_exact call not found')
line_start=r.rfind('\n',0,call)+1
indent=re.match(r'[ \t]*',r[line_start:]).group(0)
openp=r.find('(',call)
closep=match_paren(r,openp)
if closep<0: raise SystemExit('R13D payload read_exact paren not closed')
# Move through outer condition parens/whitespace.
q=closep+1
while q<len(r) and r[q] in ' \t\r\n)': q+=1
if q<len(r) and r[q]=='{':
    end=match_brace(r,q)
    if end<0: raise SystemExit('R13D payload read block not closed')
    stmt_end=end+1
else:
    semi=r.find(';',q)
    if semi<0: raise SystemExit('R13D payload read statement terminator not found')
    stmt_end=semi+1
begin=(indent+'if(g.r13d_headers <= 8ul || (g.r13d_headers % 120ul)==0ul)\n'+
       indent+'    rg35xx_b4_video_log("R13D NATIVE READ_PAYLOAD_BEGIN n=%lu", g.r13d_headers);\n')
done=('\n'+indent+'g.r13d_payloads++;\n'+
      indent+'if(g.r13d_payloads <= 8ul || (g.r13d_payloads % 120ul)==0ul)\n'+
      indent+'    rg35xx_b4_video_log("R13D NATIVE READ_PAYLOAD_DONE n=%lu", g.r13d_payloads);')
r=r[:line_start]+begin+r[line_start:stmt_end]+done+r[stmt_end:]
s=s[:rm.start()]+r+s[rm.end():]

# Publish stage: existing B4 hook sits after generation is committed and mutex released.
once('    if(!g.obs_first_publish)\n    {', '''    g.r13d_publishes++;\n    if(g.r13d_publishes <= 8ul || (g.r13d_publishes % 120ul)==0ul)\n        rg35xx_b4_video_log("R13D NATIVE PUBLISH_DONE n=%lu generation=%lu",\n                            g.r13d_publishes, g.generation);\n\n    if(!g.obs_first_publish)\n    {''', 'publish')

# Present stage: rg35xx_golden_video_present is called from retro_run. If this
# counter advances, retro_run is observing published generations.
once('    if(!g.obs_first_present)\n    {', '''    g.r13d_present_calls++;\n    if(g.r13d_present_calls <= 8ul || (g.r13d_present_calls % 120ul)==0ul)\n        rg35xx_b4_video_log("R13D NATIVE PRESENT_BEGIN n=%lu generation=%lu presented=%lu",\n                            g.r13d_present_calls, generation, g.presented_generation);\n\n    if(!g.obs_first_present)\n    {''', 'present begin')
once('    g.presented_generation = generation;\n    pthread_mutex_unlock(&g.mutex);\n    return 1;', '''    g.presented_generation = generation;\n    if(g.r13d_present_calls <= 8ul || (g.r13d_present_calls % 120ul)==0ul)\n        rg35xx_b4_video_log("R13D NATIVE PRESENT_DONE n=%lu generation=%lu",\n                            g.r13d_present_calls, generation);\n    pthread_mutex_unlock(&g.mutex);\n    return 1;''', 'present done')

for tok in ('R13D NATIVE READ_HEADER_DONE','R13D NATIVE READ_PAYLOAD_BEGIN','R13D NATIVE READ_PAYLOAD_DONE','R13D NATIVE PUBLISH_DONE','R13D NATIVE PRESENT_BEGIN','R13D NATIVE PRESENT_DONE'):
    if tok not in s: raise SystemExit('R13D missing '+tok)
if s==orig: raise SystemExit('R13D no mutation')
p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R22-R1.3D_NATIVE_FRAME_TRACE=PASS')
print('TRACE_POLICY=FIRST_8_THEN_EVERY_120')
print('VIDEO_AUDIO_SEMANTICS=UNCHANGED')
