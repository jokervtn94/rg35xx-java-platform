#!/usr/bin/env python3
import hashlib, io, sys, zipfile
from pathlib import PurePosixPath

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-audio-boundary-diag.py <zip>')
path=sys.argv[1]
raw=open(path,'rb').read()
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    names=set(z.namelist())
    script='SD/Roms/APPS/RG35XX-AUDIO-BOUNDARY-DIAG.sh'
    jar='SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Audio-Boundary-Diagnostic.jar'
    readme='README.txt'
    for n in (script,jar,readme):
        if n not in names: raise SystemExit('AUDIO_DIAG_GATE_FAIL=MISSING:'+n)
    s=z.read(script)
    for token in [
        b'0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3',
        b'c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4',
        b'a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00',
        b'4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
        b'8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e',
        b'A_COMPLEX_FORMAT1_AUDIBLE=NOT_TESTED', b'B3_BGM_RETURN_AUDIBLE=NOT_TESTED']:
        if token not in s: raise SystemExit('AUDIO_DIAG_GATE_FAIL=SCRIPT_TOKEN:'+token.decode())
    if b'/mnt/mmc/CFW/java' in s: raise SystemExit('AUDIO_DIAG_GATE_FAIL=CFW_JAVA_DEPENDENCY')
    jb=z.read(jar)
    with zipfile.ZipFile(io.BytesIO(jb)) as j:
        jnames=set(j.namelist())
        need={'RG35XXAudioBoundaryDiagnostic.class','RG35XXAudioBoundaryDiagnostic$DiagnosticCanvas.class','diag-complex-format1.mid','diag-bgm-loop.mid','diag-fx-silent-tail.mid'}
        if not need <= jnames: raise SystemExit('AUDIO_DIAG_GATE_FAIL=JAR_ENTRIES')
        cls=j.read('RG35XXAudioBoundaryDiagnostic.class')
        if int.from_bytes(cls[6:8],'big') != 50: raise SystemExit('AUDIO_DIAG_GATE_FAIL=JAVA_MAJOR')
        for marker in [b'AUDIO_DIAG_A_COMPLEX_START=PASS',b'AUDIO_DIAG_B1_BGM_START=PASS',b'AUDIO_DIAG_B2_FX_START=PASS',b'AUDIO_DIAG_B3_BGM_RESTART=PASS']:
            if marker not in cls: raise SystemExit('AUDIO_DIAG_GATE_FAIL=MARKER')
        for mid in ['diag-complex-format1.mid','diag-bgm-loop.mid','diag-fx-silent-tail.mid']:
            d=j.read(mid)
            if d[:4] != b'MThd': raise SystemExit('AUDIO_DIAG_GATE_FAIL=MIDI_HEADER')
        c=j.read('diag-complex-format1.mid')
        if int.from_bytes(c[8:10],'big') != 1 or int.from_bytes(c[10:12],'big') < 10:
            raise SystemExit('AUDIO_DIAG_GATE_FAIL=COMPLEX_MIDI_SHAPE')
        allbytes=b''.join(j.read(n) for n in j.namelist() if not n.endswith('/'))
        if b'God-of-War' in allbytes or b'God Of War' in allbytes:
            raise SystemExit('AUDIO_DIAG_GATE_FAIL=GAME_SPECIFIC_CONTENT')
    jar_sha=hashlib.sha256(jb).hexdigest().encode()
    if jar_sha not in s: raise SystemExit('AUDIO_DIAG_GATE_FAIL=JAR_HASH_NOT_BOUND')
    forbidden=[]
    for n in names:
        p=PurePosixPath(n)
        if p.name in {'freej2me-rg35xx.jar','libaudio.so','librg35xx_input.so','librg35xx_video.so','jamvm','glibj.zip'}:
            forbidden.append(n)
    if forbidden: raise SystemExit('AUDIO_DIAG_GATE_FAIL=PRODUCTION_BINARY_EMBEDDED:'+','.join(forbidden))

print('AUDIO_DIAG_INDEPENDENT_GATE=PASS')
print('AUDIO_DIAG_JAVA6_GATE=PASS')
print('AUDIO_DIAG_COMPLEX_FORMAT1_FIXTURE_GATE=PASS')
print('AUDIO_DIAG_MULTI_PLAYER_FIXTURE_GATE=PASS')
print('AUDIO_DIAG_R4_IDENTITY_BINDING_GATE=PASS')
print('AUDIO_DIAG_PRODUCTION_BINARY_DELTA=NONE')
print('AUDIO_DIAG_GAME_SPECIFIC_CODE=NO')
print('DEVICE_PASS=NO')
print('STABLE=NO')
print('AUDIO_DIAG_ZIP_SHA256='+hashlib.sha256(raw).hexdigest())
