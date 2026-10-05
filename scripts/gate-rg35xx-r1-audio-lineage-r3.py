#!/usr/bin/env python3
import hashlib, os, re, sys, tempfile, zipfile
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-r1-audio-lineage-r3.py ZIP')
zip_path=Path(sys.argv[1])
if not zip_path.is_file():
    raise SystemExit('R1_R3_GATE_FAIL=ZIP_MISSING')

EXPECTED={
 'platform':'a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00',
 'jamvm':'0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3',
 'glibj':'c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4',
 'classes':'ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86',
 'input':'6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c',
 'video':'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
 'font_native':'29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b',
 'audio':'4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
 'font':'1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10',
}
PRE='b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117'

def sha(b): return hashlib.sha256(b).hexdigest()
def fail(x): raise SystemExit('R1_R3_GATE_FAIL='+x)

with zipfile.ZipFile(zip_path) as z:
    names=z.namelist()
    roots={n.split('/')[0] for n in names if '/' in n}
    if roots != {'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R3'}:
        fail('ROOT='+repr(sorted(roots)))
    root='RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R3/'
    app=root+'SD/Roms/APPS/FreeJ2ME-RG35XX/'
    runtime=root+'SD/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime/'
    p7=root+'SD/Roms/APPS/RG35XX-R1-P7/'
    req={
      app+'freej2me-rg35xx.jar':EXPECTED['platform'],
      app+'librg35xx_input.so':EXPECTED['input'],
      app+'librg35xx_video.so':EXPECTED['video'],
      app+'librg35xx_font.so':EXPECTED['font_native'],
      app+'libaudio.so':EXPECTED['audio'],
      app+'font.ttf':EXPECTED['font'],
      runtime+'bin/jamvm':EXPECTED['jamvm'],
      runtime+'share/classpath/glibj.zip':EXPECTED['glibj'],
      runtime+'share/jamvm/classes.zip':EXPECTED['classes'],
      app+'bootstrap-runtime/bin/jamvm':EXPECTED['jamvm'],
      app+'bootstrap-runtime/share/classpath/glibj.zip':EXPECTED['glibj'],
      app+'bootstrap-runtime/share/jamvm/classes.zip':EXPECTED['classes'],
    }
    for n,h in req.items():
        if n not in names: fail('MISSING:'+n)
        got=sha(z.read(n))
        if got != h: fail('HASH:'+n+':'+got)

    # Exact accepted launcher must contain the already-proven loader markers.
    with tempfile.TemporaryDirectory() as td:
        jar=Path(td)/'platform.jar'
        jar.write_bytes(z.read(app+'freej2me-rg35xx.jar'))
        with zipfile.ZipFile(jar) as j:
            data=j.read('org/recompile/rg35xx/RG35XXLauncher.class')
            for marker in (b'libaudio.so', b'RG35XX_A7_AUDIO_BRIDGE=LOADED', b'DEVICE_INIT=LAZY'):
                if marker not in data: fail('AUDIO_LOADER_MARKER:'+repr(marker))

    p6=z.read(root+'SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh').decode('utf-8','replace')
    p7s=z.read(root+'SD/Roms/APPS/RG35XX-R1-P7-TIER0.sh').decode('utf-8','replace')
    if EXPECTED['platform'] not in p6: fail('P6_EXPECTED_PLATFORM')
    if EXPECTED['platform'] not in p7s: fail('P7_EXPECTED_PLATFORM')
    if 'RG35XX-R1-RUNTIME-BOOTSTRAP.sh' not in p6: fail('P6_BOOTSTRAP_MISSING')
    if 'RG35XX-R1-RUNTIME-BOOTSTRAP.sh' not in p7s: fail('P7_BOOTSTRAP_MISSING')

    identity=z.read(root+'AUDIO-LINEAGE-R3-IDENTITY.txt').decode('utf-8','replace')
    required=[
      'SCOPE=FULL_PORT_INTEGRATION_ARTIFACT_SELECTION_ONLY',
      'ACCEPTED_P3_PLATFORM_SHA256='+EXPECTED['platform'],
      'ACCEPTED_P3_ARTIFACT_ID=11306309186',
      'RUNTIME_SEMANTIC_DELTA=NONE',
      'NATIVE_AUDIO_DELTA=NONE',
      'P6_PHYSICAL_ACCEPTANCE=NOT_TESTED',
      'P7_PHYSICAL_REGRESSION=NOT_TESTED',
      'DEVICE_PASS=NO', 'STABLE=NO'
    ]
    for marker in required:
        if marker not in identity: fail('IDENTITY:'+marker)

    # Commercial Tier-0 JARs must remain user-supplied, never repackaged.
    lower=[n.lower() for n in names]
    forbidden=('vua-cuop-bien-240x320.jar','god-of-war-betrayal_j2me_en_v148.jar')
    for f in forbidden:
        if any(n.endswith(f) for n in lower): fail('COMMERCIAL_GAME_CONTENT:'+f)

    # Deferred 3D native capabilities must not be silently re-enabled.
    bad3d=[n for n in lower if n.endswith(('.so','.jar')) and any(k in n for k in ('m3g','micro3d','lwjgl'))]
    if bad3d: fail('DEFERRED_3D='+repr(bad3d))

print('R1_R3_INDEPENDENT_GATE=PASS')
print('R1_R3_ACCEPTED_P3_PLATFORM_GATE=PASS')
print('R1_R3_AUDIO_LOADER_MARKER_GATE=PASS')
print('R1_R3_RUNTIME_HASH_GATE=PASS')
print('R1_R3_NATIVE_HASH_GATE=PASS')
print('R1_R3_COMMERCIAL_GAME_CONTENT=NO')
print('R1_R3_RUNTIME_SEMANTIC_DELTA=NONE')
print('R1_R3_NATIVE_AUDIO_DELTA=NONE')
print('P6_PHYSICAL_ACCEPTANCE=NOT_TESTED')
print('P7_PHYSICAL_REGRESSION=NOT_TESTED')
print('DEVICE_PASS=NO')
print('STABLE=NO')
