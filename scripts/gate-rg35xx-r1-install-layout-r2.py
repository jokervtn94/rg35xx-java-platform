#!/usr/bin/env python3
import hashlib, io, os, sys, zipfile

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-r1-install-layout-r2.py <zip>')
zip_path=sys.argv[1]
EXPECTED={
 'jamvm':'0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3',
 'glibj':'c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4',
 'classes':'ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86',
 'platform':'b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117',
 'input':'6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c',
 'video':'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
 'fontnative':'29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b',
 'audio':'4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
 'font':'1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10',
}
def sha(b): return hashlib.sha256(b).hexdigest()
with zipfile.ZipFile(zip_path) as z:
    names=set(z.namelist())
    roots=sorted({n.split('/')[0] for n in names if n})
    if roots != ['RG35XX-MIYOO-FULL-PORT-R1-P7-READY-LAYOUT-R2']:
        raise SystemExit('LAYOUT_R2_GATE_FAIL root='+repr(roots))
    r=roots[0]
    base=f'{r}/SD/Roms/APPS'
    app=f'{base}/FreeJ2ME-RG35XX'
    sibling=f'{base}/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime'
    boot=f'{app}/bootstrap-runtime'
    req={
      f'{base}/RG35XX-R1-RUNTIME-BOOTSTRAP.sh',
      f'{base}/FreeJ2ME-RG35XX.sh',
      f'{base}/RG35XX-FULL-PORT-R1-TEST.sh',
      f'{base}/RG35XX-R1-P7-TIER0.sh',
      f'{boot}/bin/jamvm',
      f'{boot}/share/classpath/glibj.zip',
      f'{boot}/share/jamvm/classes.zip',
      f'{sibling}/bin/jamvm',
      f'{sibling}/share/classpath/glibj.zip',
      f'{sibling}/share/jamvm/classes.zip',
      f'{app}/freej2me-rg35xx.jar',
      f'{app}/librg35xx_input.so',
      f'{app}/librg35xx_video.so',
      f'{app}/librg35xx_font.so',
      f'{app}/libaudio.so',
      f'{app}/font.ttf',
      f'{r}/INSTALL-LAYOUT-R2-IDENTITY.txt',
    }
    missing=req-names
    if missing: raise SystemExit('LAYOUT_R2_GATE_FAIL missing='+repr(sorted(missing)))
    checks={
      f'{boot}/bin/jamvm':EXPECTED['jamvm'],
      f'{boot}/share/classpath/glibj.zip':EXPECTED['glibj'],
      f'{boot}/share/jamvm/classes.zip':EXPECTED['classes'],
      f'{sibling}/bin/jamvm':EXPECTED['jamvm'],
      f'{sibling}/share/classpath/glibj.zip':EXPECTED['glibj'],
      f'{sibling}/share/jamvm/classes.zip':EXPECTED['classes'],
      f'{app}/freej2me-rg35xx.jar':EXPECTED['platform'],
      f'{app}/librg35xx_input.so':EXPECTED['input'],
      f'{app}/librg35xx_video.so':EXPECTED['video'],
      f'{app}/librg35xx_font.so':EXPECTED['fontnative'],
      f'{app}/libaudio.so':EXPECTED['audio'],
      f'{app}/font.ttf':EXPECTED['font'],
    }
    for n,e in checks.items():
        g=sha(z.read(n))
        if g!=e: raise SystemExit('LAYOUT_R2_GATE_FAIL hash %s %s'%(n,g))
    for n in [f'{base}/FreeJ2ME-RG35XX.sh',f'{base}/RG35XX-FULL-PORT-R1-TEST.sh',f'{base}/RG35XX-R1-P7-TIER0.sh']:
        s=z.read(n).decode('utf-8')
        if 'RG35XX-R1-RUNTIME-BOOTSTRAP.sh' not in s:
            raise SystemExit('LAYOUT_R2_GATE_FAIL bootstrap-not-injected '+n)
    bs=z.read(f'{base}/RG35XX-R1-RUNTIME-BOOTSTRAP.sh').decode('utf-8')
    for marker in ['bootstrap-runtime','RG35XX-RUNTIME-CANDIDATE-PROBE/runtime','R1_RUNTIME_BOOTSTRAP=PASS:MATERIALIZED_EXACT','POST_COPY_HASH']:
        if marker not in bs: raise SystemExit('LAYOUT_R2_GATE_FAIL bootstrap-marker '+marker)
    identity=z.read(f'{r}/INSTALL-LAYOUT-R2-IDENTITY.txt').decode('utf-8')
    for marker in ['SCOPE=INSTALL_LAYOUT_BOUNDARY_ONLY','RUNTIME_SEMANTIC_DELTA=NONE','PLATFORM_SEMANTIC_DELTA=NONE','DEVICE_PASS=NO','STABLE=NO']:
        if marker not in identity: raise SystemExit('LAYOUT_R2_GATE_FAIL identity '+marker)
    lower='\n'.join(names).lower()
    for forbidden in ['vua-cuop-bien-240x320.jar','god-of-war-betrayal_j2me_en_v148.jar','/cfw/java/']:
        if forbidden in lower: raise SystemExit('LAYOUT_R2_GATE_FAIL forbidden-content '+forbidden)
print('R1_LAYOUT_R2_INDEPENDENT_GATE=PASS')
print('R1_LAYOUT_R2_BOOTSTRAP_SOURCE_HASH_GATE=PASS')
print('R1_LAYOUT_R2_EXISTING_RUNTIME_HASH_GATE=PASS')
print('R1_LAYOUT_R2_PLATFORM_HASH_GATE=PASS')
print('R1_LAYOUT_R2_COMMERCIAL_GAME_CONTENT=NO')
print('RUNTIME_SEMANTIC_DELTA=NONE')
print('PLATFORM_SEMANTIC_DELTA=NONE')
print('P6_PHYSICAL_ACCEPTANCE=NOT_TESTED')
print('P7_PHYSICAL_REGRESSION=NOT_TESTED')
print('DEVICE_PASS=NO')
print('STABLE=NO')
