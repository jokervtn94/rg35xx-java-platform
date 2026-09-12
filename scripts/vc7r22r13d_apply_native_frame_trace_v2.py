#!/usr/bin/env python3
import pathlib,re,sys
p=pathlib.Path(sys.argv[1]); s=p.read_text(); o=s

def rep(old,new,label):
 n=s.count(old)
 if n!=1: raise SystemExit('%s count=%d'%(label,n))
 return s.replace(old,new,1)

s=rep('    int obs_first_present;\n};','    int obs_first_present;\n    unsigned long r13d_headers, r13d_payloads, r13d_publishes, r13d_present_calls;\n};','state')
s=rep('        if(!read_header_resync(header, &w, &h, &rotation)) break;\n\n        pixels = (size_t)w * (size_t)h;','        if(!read_header_resync(header, &w, &h, &rotation)) break;\n\n        g.r13d_headers++;\n        if(g.r13d_headers<=8ul || (g.r13d_headers%120ul)==0ul) rg35xx_b4_video_log("R13D NATIVE READ_HEADER_DONE n=%lu src=%ux%u rot=%u",g.r13d_headers,w,h,rotation);\n\n        pixels = (size_t)w * (size_t)h;','header')
rm=re.search(r'static void \*receiver_main\(.*?\n\}',s,re.S)
if not rm: raise SystemExit('receiver_main missing')
r=rm.group(0); h=r.find('read_header_resync'); c=r.find('read_exact(',h)
if c<0: raise SystemExit('payload read missing')
ls=r.rfind('\n',0,c)+1; ind=re.match(r'[ \t]*',r[ls:]).group(0)
semi=r.find(';',c)
brace=r.find('{',c,semi if semi>=0 else len(r))
if brace>=0:
 d=1; i=brace+1
 while i<len(r) and d:
  d += (r[i]=='{')-(r[i]=='}'); i+=1
 end=i
else:
 end=semi+1
pre=ind+'if(g.r13d_headers<=8ul || (g.r13d_headers%120ul)==0ul) rg35xx_b4_video_log("R13D NATIVE READ_PAYLOAD_BEGIN n=%lu",g.r13d_headers);\n'
post='\n'+ind+'g.r13d_payloads++;\n'+ind+'if(g.r13d_payloads<=8ul || (g.r13d_payloads%120ul)==0ul) rg35xx_b4_video_log("R13D NATIVE READ_PAYLOAD_DONE n=%lu",g.r13d_payloads);'
r=r[:ls]+pre+r[ls:end]+post+r[end:]; s=s[:rm.start()]+r+s[rm.end():]
s=rep('    if(!g.obs_first_publish)\n    {','    g.r13d_publishes++;\n    if(g.r13d_publishes<=8ul || (g.r13d_publishes%120ul)==0ul) rg35xx_b4_video_log("R13D NATIVE PUBLISH_DONE n=%lu generation=%lu",g.r13d_publishes,g.generation);\n\n    if(!g.obs_first_publish)\n    {','publish')
s=rep('    if(!g.obs_first_present)\n    {','    g.r13d_present_calls++;\n    if(g.r13d_present_calls<=8ul || (g.r13d_present_calls%120ul)==0ul) rg35xx_b4_video_log("R13D NATIVE PRESENT_BEGIN n=%lu generation=%lu presented=%lu",g.r13d_present_calls,generation,g.presented_generation);\n\n    if(!g.obs_first_present)\n    {','present-begin')
s=rep('    g.presented_generation = generation;','    g.presented_generation = generation;\n    if(g.r13d_present_calls<=8ul || (g.r13d_present_calls%120ul)==0ul) rg35xx_b4_video_log("R13D NATIVE PRESENT_DONE n=%lu generation=%lu",g.r13d_present_calls,generation);','present-done')
for t in ['READ_HEADER_DONE','READ_PAYLOAD_BEGIN','READ_PAYLOAD_DONE','PUBLISH_DONE','PRESENT_BEGIN','PRESENT_DONE']:
 if ('R13D NATIVE '+t) not in s: raise SystemExit('missing '+t)
if s==o: raise SystemExit('no mutation')
p.write_text(s)
print('VC7R22-R1.3D_NATIVE_FRAME_TRACE_V2=PASS')
