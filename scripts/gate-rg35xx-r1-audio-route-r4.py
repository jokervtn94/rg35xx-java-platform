#!/usr/bin/env python3
import hashlib, sys, tempfile, zipfile
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-r1-audio-route-r4.py ZIP')
p=Path(sys.argv[1])
if not p.is_file(): raise SystemExit('R1_R4_GATE_FAIL=ZIP_MISSING')

def h(b): return hashlib.sha256(b).hexdigest()
def fail(x): raise SystemExit('R1_R4_GATE_FAIL='+x)

E={
'platform':'a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00',
'jamvm':'0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3',
'glibj':'c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4',
'classes':'ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86',
'input':'6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c',
'video':'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
'font_native':'29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b',
'audio':'4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
'font':'1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10',
'prime':'8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e',
}
with zipfile.ZipFile(p) as z:
    names=z.namelist()
    root='RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4/'
    if {n.split('/')[0] for n in names if '/' in n} != {root[:-1]}: fail('ROOT')
    app=root+'SD/Roms/APPS/FreeJ2ME-RG35XX/'
    rt=root+'SD/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime/'
    req={
      app+'freej2me-rg35xx.jar':E['platform'], app+'librg35xx_input.so':E['input'],
      app+'librg35xx_video.so':E['video'], app+'librg35xx_font.so':E['font_native'],
      app+'libaudio.so':E['audio'], app+'font.ttf':E['font'],
      app+'a7-a1p5-rw-silence-prime.s32le':E['prime'],
      rt+'bin/jamvm':E['jamvm'], rt+'share/classpath/glibj.zip':E['glibj'],
      rt+'share/jamvm/classes.zip':E['classes'],
      app+'bootstrap-runtime/bin/jamvm':E['jamvm'],
      app+'bootstrap-runtime/share/classpath/glibj.zip':E['glibj'],
      app+'bootstrap-runtime/share/jamvm/classes.zip':E['classes'],
    }
    for n,expected in req.items():
        if n not in names: fail('MISSING:'+n)
        got=h(z.read(n))
        if got!=expected: fail('HASH:'+n+':'+got)
    if len(z.read(app+'a7-a1p5-rw-silence-prime.s32le')) != 123480: fail('PRIME_SIZE')

    prime=z.read(root+'SD/Roms/APPS/RG35XX-R1-AUDIO-ROUTE-PRIME.sh').decode('utf-8','replace')
    for marker in ('export SDL_AUDIODRIVER=alsa','-D hw:0,0','-t raw','-f S32_LE','-c 2','-r 44100','A1P5_AUDIO_ROUTE_PRIME=PASS'):
        if marker not in prime: fail('PRIME_SCRIPT:'+marker)
    generic=z.read(root+'SD/Roms/APPS/FreeJ2ME-RG35XX.sh').decode('utf-8','replace')
    p6=z.read(root+'SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh').decode('utf-8','replace')
    if 'RG35XX-R1-AUDIO-ROUTE-PRIME.sh' not in generic: fail('GENERIC_PRIME')
    if 'export SDL_AUDIODRIVER=alsa' not in generic: fail('GENERIC_ALSA')
    if 'A1P5_AUDIO_ROUTE_PRIME_R4=ENABLED' not in p6: fail('P6_PRIME')
    if p6.count('prime_audio') < 2: fail('P6_PRIME_CALLS')

    ident=z.read(root+'AUDIO-ROUTE-R4-IDENTITY.txt').decode('utf-8','replace')
    for marker in (
      'SCOPE=RG35XX_AUDIO_ROUTE_LAUNCHER_BOUNDARY_ONLY',
      'GOLDEN_OWNER=A1P5_AUDIO_ROUTE_PRIME',
      'PRIME_PCM_SHA256='+E['prime'],
      'CANONICAL_MMAPI=UNCHANGED','CANONICAL_PLATFORMPLAYER=UNCHANGED',
      'CANONICAL_SDLMIXERMANAGER=UNCHANGED','RUNTIME_SEMANTIC_DELTA=NONE',
      'NATIVE_AUDIO_DELTA=NONE','GAME_SPECIFIC_CODE=NO','DEVICE_PASS=NO','STABLE=NO'):
        if marker not in ident: fail('IDENTITY:'+marker)

    # Never package the commercial Tier-0 inputs or deferred 3D capabilities.
    lower=[n.lower() for n in names]
    for f in ('vua-cuop-bien-240x320.jar','god-of-war-betrayal_j2me_en_v148.jar'):
        if any(n.endswith(f) for n in lower): fail('COMMERCIAL_GAME:'+f)
    if any(n.endswith(('.jar','.so')) and any(k in n for k in ('m3g','micro3d','lwjgl')) for n in lower):
        fail('DEFERRED_3D')

print('R1_R4_INDEPENDENT_GATE=PASS')
print('R1_R4_GOLDEN_A1P5_ROUTE_PRIME_GATE=PASS')
print('R1_R4_PRIME_SHA256='+E['prime'])
print('R1_R4_PLATFORM_HASH_GATE=PASS')
print('R1_R4_RUNTIME_HASH_GATE=PASS')
print('R1_R4_NATIVE_HASH_GATE=PASS')
print('R1_R4_CANONICAL_MMAPI_DELTA=NONE')
print('R1_R4_NATIVE_AUDIO_DELTA=NONE')
print('R1_R4_GAME_SPECIFIC_CODE=NO')
print('P6_PHYSICAL_ACCEPTANCE=NOT_TESTED')
print('P7_PHYSICAL_REGRESSION=NOT_TESTED')
print('DEVICE_PASS=NO')
print('STABLE=NO')
