#!/usr/bin/env python3
import collections, re, sys
if len(sys.argv)!=3: raise SystemExit('usage: <jdk.log> <ft.log>')
jre=re.compile(r'^P2B_JDK_RASTER_FP STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) SAMPLE=(\d+) WIDTH=(\d+) INK=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+) FP=([0-9a-f]+)$')
fre=re.compile(r'^P2B_FT_RASTER_FP VARIANT=(\S+) STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) SAMPLE=(\d+) WIDTH=(\d+) INK=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+) FP=([0-9a-f]+)$')
j={}
for line in open(sys.argv[1],encoding='utf-8',errors='replace'):
 m=jre.match(line.strip())
 if m:
  s,n,z,i,w,ink,*rest=m.groups(); b=tuple(map(int,rest[:4])); fp=rest[4].lstrip('0') or '0'
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
mono_mismatches=[]
for v in variants:
 width=norm=ink_exact=bounds_exact=bounds1=fp_exact=0; ink_err=0; cases=0
 for (s,z,i),a in sorted(j.items()):
  b=f.get((v,s,z,i))
  if b is None: continue
  cases+=1
  if a[0]==b[0]: norm+=1
  if a[1]==b[1]: width+=1
  if a[2]==b[2]: ink_exact+=1
  ink_err+=abs(a[2]-b[2])
  if a[3]==b[3]: bounds_exact+=1
  if max(abs(a[3][q]-b[3][q]) for q in range(4))<=1: bounds1+=1
  same_fp=(a[4]==b[4])
  if same_fp: fp_exact+=1
  elif v=='MONO':
   kind='SHAPE_DIFFERENCE_SAME_INK' if a[2]==b[2] else 'INK_AND_SHAPE_DIFFERENCE'
   mono_mismatches.append((s,a[0],z,i,kind,a[1],b[1],a[2],b[2],b[2]-a[2],a[3],b[3],a[4],b[4]))
 print('P2B_RASTER_VARIANT=%s CASES=%d NORMALIZED_STYLE_EXACT=%d WIDTH_EXACT=%d BOUNDS_EXACT=%d BOUNDS_WITHIN1=%d INK_EXACT=%d INK_ABS_ERROR_TOTAL=%d FP_EXACT=%d'%(v,cases,norm,width,bounds_exact,bounds1,ink_exact,ink_err,fp_exact))

print('P2B_MONO_MISMATCH_CLASSIFIER=BEGIN')
print('P2B_MONO_MISMATCH_CASES=%d'%len(mono_mismatches))
by_kind=collections.Counter(x[4] for x in mono_mismatches)
by_style=collections.Counter(x[0] for x in mono_mismatches)
by_normalized=collections.Counter(x[1] for x in mono_mismatches)
by_size=collections.Counter(x[2] for x in mono_mismatches)
by_sample=collections.Counter(x[3] for x in mono_mismatches)
for key in sorted(by_kind): print('P2B_MONO_MISMATCH_BY_KIND KIND=%s COUNT=%d'%(key,by_kind[key]))
for key in sorted(by_style): print('P2B_MONO_MISMATCH_BY_STYLE STYLE=%d COUNT=%d'%(key,by_style[key]))
for key in sorted(by_normalized): print('P2B_MONO_MISMATCH_BY_NORMALIZED_STYLE NORMALIZED=%d COUNT=%d'%(key,by_normalized[key]))
for key in sorted(by_size): print('P2B_MONO_MISMATCH_BY_SIZE SIZE=%d COUNT=%d'%(key,by_size[key]))
for key in sorted(by_sample): print('P2B_MONO_MISMATCH_BY_SAMPLE SAMPLE=%d COUNT=%d'%(key,by_sample[key]))
for x in mono_mismatches:
 s,n,z,i,kind,jw,fw,ji,fi,delta,jb,fb,jfp,ffp=x
 print('P2B_MONO_MISMATCH STYLE=%d NORMALIZED=%d SIZE=%d SAMPLE=%d KIND=%s JDK_WIDTH=%d FT_WIDTH=%d JDK_INK=%d FT_INK=%d INK_DELTA=%+d BOUNDS_EXACT=%s JDK_BOUNDS=%d,%d,%d,%d FT_BOUNDS=%d,%d,%d,%d JDK_FP=%s FT_FP=%s'%(s,n,z,i,kind,jw,fw,ji,fi,delta,'YES' if jb==fb else 'NO',jb[0],jb[1],jb[2],jb[3],fb[0],fb[1],fb[2],fb[3],jfp,ffp))
print('P2B_MONO_MISMATCH_CLASSIFIER=PASS')
print('P2B_RASTER_DIFF_RESULT=PASS')
print('P2B_RUNTIME_PATCH=FORBIDDEN')
