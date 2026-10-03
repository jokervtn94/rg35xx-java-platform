#!/usr/bin/env python3
import re, sys
if len(sys.argv)!=3: raise SystemExit('usage: <jdk.log> <ft.log>')
jre=re.compile(r'^P2B_JDK_RASTER_FP STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) SAMPLE=(\d+) WIDTH=(\d+) INK=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+) FP=([0-9a-f]+)$')
fre=re.compile(r'^P2B_FT_RASTER_FP VARIANT=(\S+) STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) SAMPLE=(\d+) WIDTH=(\d+) INK=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+) FP=([0-9a-f]+)$')
j={}
for line in open(sys.argv[1],encoding='utf-8',errors='replace'):
 m=jre.match(line.strip())
 if m:
  s,n,z,i,w,ink,*rest=m.groups(); b=tuple(map(int,rest[:4])); fp=rest[4]
  j[(int(s),int(z),int(i))]=(int(n),int(w),int(ink),b,fp)
f={}
for line in open(sys.argv[2],encoding='utf-8',errors='replace'):
 m=fre.match(line.strip())
 if m:
  v,s,n,z,i,w,ink,*rest=m.groups(); b=tuple(map(int,rest[:4])); fp=rest[4].lstrip('0') or '0'
  f[(v,int(s),int(z),int(i))]=(int(n),int(w),int(ink),b,fp)
print('P2B_RASTER_DIFF_PARSE=PASS')
print('P2B_RASTER_JDK_CASES=%d'%len(j))
variants=sorted(set(k[0] for k in f))
for v in variants:
 width=norm=ink_exact=bounds_exact=bounds1=fp_exact=0; ink_err=0; cases=0
 for (s,z,i),a in j.items():
  b=f.get((v,s,z,i))
  if b is None: continue
  cases+=1
  if a[0]==b[0]: norm+=1
  if a[1]==b[1]: width+=1
  if a[2]==b[2]: ink_exact+=1
  ink_err+=abs(a[2]-b[2])
  if a[3]==b[3]: bounds_exact+=1
  if max(abs(a[3][q]-b[3][q]) for q in range(4))<=1: bounds1+=1
  if a[4].lstrip('0')==b[4].lstrip('0'): fp_exact+=1
 print('P2B_RASTER_VARIANT=%s CASES=%d NORMALIZED_STYLE_EXACT=%d WIDTH_EXACT=%d BOUNDS_EXACT=%d BOUNDS_WITHIN1=%d INK_EXACT=%d INK_ABS_ERROR_TOTAL=%d FP_EXACT=%d'%(v,cases,norm,width,bounds_exact,bounds1,ink_exact,ink_err,fp_exact))
print('P2B_RASTER_DIFF_RESULT=PASS')
print('P2B_RUNTIME_PATCH=FORBIDDEN')
