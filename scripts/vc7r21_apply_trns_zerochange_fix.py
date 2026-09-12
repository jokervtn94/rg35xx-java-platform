#!/usr/bin/env python3
import pathlib,re,sys

if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r21_apply_trns_zerochange_fix.py <PlatformImage.java>')

p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s

# VC7R20 used "changed == 0" as a proxy for "no tRNS metadata". Device evidence
# disproves that assumption: a valid tRNS chunk can produce changed=0 when ImageIO
# already returned the correct alpha values. VC7R20 then ran opaque repair and
# destroyed those transparent pixels. VC7R21 makes metadata presence explicit.

# 1) Return -1 when no tRNS metadata exists; return >=0 when metadata exists,
# even if zero pixels had to be modified.
s=s.replace(
    'if(meta==null || pixels==null) return 0;',
    'if(meta==null || pixels==null) return -1;',
    1)
if 'if(meta==null || pixels==null) return -1;' not in s:
    raise SystemExit('VC7R21: could not patch no-metadata sentinel')

# 2) Rename the normalization result so its semantics are unambiguous.
s=s.replace(
    'final int trnsChanged=rg35xxVC7R20ApplyPngTransparency(pixels);',
    'final int trnsResult=rg35xxVC7R20ApplyPngTransparency(pixels);',
    1)

# 3) Opaque repair is permitted only when there was NO tRNS metadata at all.
s=s.replace(
    'if(!sourceHasAlpha && trnsChanged==0)',
    'if(!sourceHasAlpha && trnsResult<0)',
    1)

# 4) Keep one bounded diagnostic that distinguishes no-metadata from present-zero.
old='''\t\tif(rg35xxVC7R20TrnsLogCount++<16)\n\t\t\tSystem.err.println("RG35XX-VC7R20-PNG-TRNS: keys="+meta.rgb.length+" changed="+changed);\n\t\treturn changed;'''
new='''\t\tif(rg35xxVC7R20TrnsLogCount++<16)\n\t\t\tSystem.err.println("RG35XX-VC7R21-PNG-TRNS: present=true keys="+meta.rgb.length+" changed="+changed);\n\t\treturn changed;'''
if old not in s:
    raise SystemExit('VC7R21: VC7R20 tRNS log block not found')
s=s.replace(old,new,1)

# Update nearby policy comment.
s=s.replace(
    'if neither a real alpha channel nor recovered tRNS metadata are made',
    'if neither a real alpha channel nor any tRNS metadata are made',
    1)

required=(
    'if(meta==null || pixels==null) return -1;',
    'final int trnsResult=rg35xxVC7R20ApplyPngTransparency(pixels);',
    'if(!sourceHasAlpha && trnsResult<0)',
    'RG35XX-VC7R21-PNG-TRNS: present=true'
)
for tok in required:
    if tok not in s:
        raise SystemExit('VC7R21 missing token: '+tok)
for bad in ('if(!sourceHasAlpha && trnsChanged==0)', 'if(meta==null || pixels==null) return 0;'):
    if bad in s:
        raise SystemExit('VC7R21 obsolete policy survived: '+bad)
if s==orig:
    raise SystemExit('VC7R21: no mutation')

p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R21_TRNS_ZEROCHANGE_FIX=PASS')
print('TRNS_PRESENT_ZEROCHANGE=PRESERVE_ALPHA')
print('OPAQUE_REPAIR=ONLY_WHEN_NO_ALPHA_AND_NO_TRNS_METADATA')
