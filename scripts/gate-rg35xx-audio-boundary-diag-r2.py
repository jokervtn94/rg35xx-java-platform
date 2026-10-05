#!/usr/bin/env python3
import hashlib, io, sys, zipfile
from pathlib import PurePosixPath

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-audio-boundary-diag-r2.py <zip>')
path=sys.argv[1]
raw=open(path,'rb').read()
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    names=set(z.namelist())
    script='SD/Roms/APPS/RG35XX-AUDIO-BOUNDARY-DIAG.sh'
    jar='SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Audio-Boundary-Diagnostic.jar'
    readme='README.txt'
    for n in (script,jar,readme):
        if n not in names: raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=MISSING:'+n)
    jb=z.read(jar)
    if hashlib.sha256(jb).hexdigest() != '8600a6aaeb5782486a55570e54f11e67cf9edcc2d5233329fdf2b5177d9e0f09':
        raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=JAR_CHANGED')
    s=z.read(script)
    required=[
        b'0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3',
        b'c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4',
        b'a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00',
        b'6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c',
        b'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
        b'4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
        b'8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e',
        b'AUDIO_DIAG_PACKAGING_REVISION=R2_DIRECT_R4',
        b'aplay -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100',
        b'org.recompile.rg35xx.RG35XXLauncher',
        b'A_COMPLEX_FORMAT1_AUDIBLE=NOT_TESTED',
        b'B3_BGM_RETURN_AUDIBLE=NOT_TESTED',
    ]
    for token in required:
        if token not in s: raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=SCRIPT_TOKEN:'+token.decode('utf-8','replace'))
    forbidden_tokens=[b'RG35XX-R1-RUNTIME-BOOTSTRAP.sh', b'FreeJ2ME-RG35XX.sh', b'/mnt/mmc/CFW/java']
    for token in forbidden_tokens:
        if token in s: raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=FORBIDDEN_DEP:'+token.decode())
    with zipfile.ZipFile(io.BytesIO(jb)) as j:
        need={'RG35XXAudioBoundaryDiagnostic.class','RG35XXAudioBoundaryDiagnostic$DiagnosticCanvas.class','diag-complex-format1.mid','diag-bgm-loop.mid','diag-fx-silent-tail.mid'}
        if not need <= set(j.namelist()): raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=JAR_ENTRIES')
        cls=j.read('RG35XXAudioBoundaryDiagnostic.class')
        if int.from_bytes(cls[6:8],'big') != 50: raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=JAVA_MAJOR')
        c=j.read('diag-complex-format1.mid')
        if int.from_bytes(c[8:10],'big') != 1 or int.from_bytes(c[10:12],'big') < 10:
            raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=COMPLEX_MIDI_SHAPE')
        allbytes=b''.join(j.read(n) for n in j.namelist() if not n.endswith('/'))
        if b'God-of-War' in allbytes or b'God Of War' in allbytes:
            raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=GAME_SPECIFIC_CONTENT')
    forbidden=[]
    for n in names:
        p=PurePosixPath(n)
        if p.name in {'freej2me-rg35xx.jar','libaudio.so','librg35xx_input.so','librg35xx_video.so','librg35xx_font.so','jamvm','glibj.zip'}:
            forbidden.append(n)
    if forbidden: raise SystemExit('AUDIO_DIAG_R2_GATE_FAIL=PRODUCTION_BINARY_EMBEDDED:'+','.join(forbidden))

print('AUDIO_DIAG_R2_INDEPENDENT_GATE=PASS')
print('AUDIO_DIAG_R2_PARENT_JAR_IDENTITY_GATE=PASS')
print('AUDIO_DIAG_R2_DIRECT_R4_LAUNCH_GATE=PASS')
print('AUDIO_DIAG_R2_DIRECT_A1P5_PRIME_GATE=PASS')
print('AUDIO_DIAG_R2_NO_BOOTSTRAP_DEPENDENCY=PASS')
print('AUDIO_DIAG_R2_NO_GENERIC_LAUNCHER_DEPENDENCY=PASS')
print('AUDIO_DIAG_R2_PRODUCTION_BINARY_DELTA=NONE')
print('AUDIO_DIAG_R2_DIAGNOSTIC_SEMANTIC_DELTA=NONE')
print('AUDIO_DIAG_R2_GAME_SPECIFIC_CODE=NO')
print('DEVICE_PASS=NO')
print('STABLE=NO')
print('AUDIO_DIAG_R2_ZIP_SHA256='+hashlib.sha256(raw).hexdigest())