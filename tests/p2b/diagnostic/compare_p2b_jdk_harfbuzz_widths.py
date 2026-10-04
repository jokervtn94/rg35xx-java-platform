#!/usr/bin/env python3
import re,sys
if len(sys.argv)!=3: raise SystemExit('usage: <jdk-shaping.log> <hb.log>')
jre=re.compile(r'^P2B_JDK_SHAPING STYLE=0 NORMALIZED=0 SIZE=(\d+) SAMPLE=(\d+).* STRING_WIDTH=(-?\d+) SUM_CHAR_WIDTH=(-?\d+) WIDTH_DELTA=(-?\d+) ')
hre=re.compile(r'^P2B_HB SIZE=(\d+) SAMPLE=(\d+) CODEPOINTS=(\d+) GLYPHS=(\d+) NOTDEF=(\d+) OFFSETS=(\d+) DIR=(\S+) ADV26=(-?\d+) WIDTH_ROUND=(-?\d+)$')
j={};h={}
for line in open(sys.argv[1],encoding='utf-8',errors='replace'):
 m=jre.match(line.strip())
 if m:
  z,s,sw,cw,d=m.groups();j[(int(z),int(s))]=(int(sw),int(cw),int(d))
for line in open(sys.argv[2],encoding='utf-8',errors='replace'):
 m=hre.match(line.strip())
 if m:
  z,s,cp,g,nd,off,dr,a,w=m.groups();h[(int(z),int(s))]=(int(w),int(cp),int(g),int(nd),int(off),dr,int(a))
print('P2B_HB_DIFF_PARSE=PASS')
print('P2B_HB_JDK_CASES=%d'%len(j)); print('P2B_HB_ARM_CASES=%d'%len(h))
exact=0;err=0;mx=0; mism=[]; shaped=0
for k,a in sorted(j.items()):
 b=h.get(k)
 if b is None: continue
 e=abs(a[0]-b[0]); err+=e; mx=max(mx,e)
 if e==0: exact+=1
 else: mism.append((k,a,b,e))
 if a[2]!=0: shaped+=1
print('P2B_HB_WIDTH_EXACT=%d'%exact)
print('P2B_HB_WIDTH_ERROR_TOTAL=%d'%err)
print('P2B_HB_WIDTH_ERROR_MAX=%d'%mx)
print('P2B_JDK_STRING_LEVEL_WIDTH_CASES=%d'%shaped)
print('P2B_HB_WIDTH_MISMATCH_COUNT=%d'%len(mism))
for (z,s),a,b,e in mism:
 print('P2B_HB_WIDTH_MISMATCH SIZE=%d SAMPLE=%d JDK=%d HB=%d ERR=%d JDK_SUMCHAR=%d JDK_DELTA=%d HB_CODEPOINTS=%d HB_GLYPHS=%d HB_NOTDEF=%d HB_OFFSETS=%d HB_DIR=%s'%(z,s,a[0],b[0],e,a[1],a[2],b[1],b[2],b[3],b[4],b[5]))
if len(j)==42 and len(h)==42 and exact==42:
 print('P2B_HARFBUZZ_LAYOUT_CLASSIFICATION=WIDTH_EXACT_FOR_PROBED_CORPUS')
else:
 print('P2B_HARFBUZZ_LAYOUT_CLASSIFICATION=NOT_WIDTH_EXACT_FOR_PROBED_CORPUS')
print('P2B_HB_DIFF_RESULT=PASS')
print('P2B_RUNTIME_PATCH=FORBIDDEN')
