#!/usr/bin/env python3
import struct
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_p2b_charwidth_tables.py <jdk.bin> <ft.bin>")

a = Path(sys.argv[1]).read_bytes()
b = Path(sys.argv[2]).read_bytes()
case_count = 65536 * 3
expected = case_count * 3
if len(a) != expected or len(b) != expected:
    raise SystemExit("P2B_CHARWIDTH_PARSE_FAIL jdk=%d ft=%d expected=%d" % (len(a),len(b),expected))

width_exact=0
display_exact=0
both_exact=0
width_abs_total=0
width_abs_max=0
mismatches=[]
display_mismatches=[]
sizes=(12,14,16)
for i in range(case_count):
    off=i*3
    jw=struct.unpack('>h',a[off:off+2])[0]
    fw=struct.unpack('>h',b[off:off+2])[0]
    jd=a[off+2]
    fd=b[off+2]
    z=i//65536
    cp=i%65536
    if jw==fw: width_exact+=1
    else:
        d=abs(jw-fw)
        width_abs_total+=d
        width_abs_max=max(width_abs_max,d)
        if len(mismatches)<40: mismatches.append((sizes[z],cp,jw,fw,d,jd,fd))
    if jd==fd: display_exact+=1
    else:
        if len(display_mismatches)<40: display_mismatches.append((sizes[z],cp,jd,fd,jw,fw))
    if jw==fw and jd==fd: both_exact+=1

print('P2B_CHARWIDTH_DIFF_PARSE=PASS')
print('P2B_CHARWIDTH_CASES=%d' % case_count)
print('P2B_CHARWIDTH_WIDTH_EXACT=%d' % width_exact)
print('P2B_CHARWIDTH_DISPLAY_EXACT=%d' % display_exact)
print('P2B_CHARWIDTH_BOTH_EXACT=%d' % both_exact)
print('P2B_CHARWIDTH_WIDTH_ABS_ERROR_TOTAL=%d' % width_abs_total)
print('P2B_CHARWIDTH_WIDTH_ABS_ERROR_MAX=%d' % width_abs_max)
print('P2B_CHARWIDTH_WIDTH_MISMATCH_COUNT=%d' % (case_count-width_exact))
print('P2B_CHARWIDTH_DISPLAY_MISMATCH_COUNT=%d' % (case_count-display_exact))
for size,cp,jw,fw,d,jd,fd in mismatches:
    print('P2B_CHARWIDTH_MISMATCH SIZE=%d CP=U+%04X JDK=%d FT=%d ABS=%d JDK_DISPLAY=%d FT_DISPLAY=%d' % (size,cp,jw,fw,d,jd,fd))
for size,cp,jd,fd,jw,fw in display_mismatches:
    print('P2B_DISPLAY_MISMATCH SIZE=%d CP=U+%04X JDK=%d FT=%d JDK_WIDTH=%d FT_WIDTH=%d' % (size,cp,jd,fd,jw,fw))
if width_exact == case_count and display_exact == case_count:
    cls='EXACT_ALL_BMP_CODE_UNITS'
elif width_abs_max <= 1 and display_exact == case_count:
    cls='NEAR_EXACT_MAX1_REQUIRES_CALIBRATION'
else:
    cls='DIVERGENT_REQUIRES_CLASSIFICATION'
print('P2B_CHARWIDTH_CLASSIFICATION=%s' % cls)
print('P2B_RUNTIME_PATCH=FORBIDDEN')
print('P2B_CHARWIDTH_DIFF_RESULT=PASS')
