#!/usr/bin/env python3
import hashlib, io, re, sys, zipfile
from pathlib import PurePosixPath
if len(sys.argv)!=2: raise SystemExit('usage: gate-rg35xx-r5-audio-owner.py <zip>')
raw=open(sys.argv[1],'rb').read()
OLD_AUDIO='4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644'
EXPECTED={
 'freej2me-rg35xx.jar':'a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00',
 'librg35xx_input.so':'6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c',
 'librg35xx_video.so':'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
 'librg35xx_font.so':'29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b',
 'font.ttf':'1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10',
 'a7-a1p5-rw-silence-prime.s32le':'8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e',
}
def sha(b): return hashlib.sha256(b).hexdigest()
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    names=z.namelist(); root='RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-OWNER/'
    def need(rel):
        p=root+rel
        if p not in names: raise SystemExit('R5_GATE_FAIL=MISSING:'+rel)
        return z.read(p)
    ident=need('AUDIO-OWNER-R5-IDENTITY.txt').decode('utf-8')
    m=re.search(r'^R5_AUDIO_SHA256=([0-9a-f]{64})$',ident,re.M)
    if not m: raise SystemExit('R5_GATE_FAIL=R5_AUDIO_IDENTITY')
    audio_sha=m.group(1)
    if audio_sha==OLD_AUDIO: raise SystemExit('R5_GATE_FAIL=AUDIO_NOT_CHANGED')
    pkg='SD/Roms/APPS/FreeJ2ME-RG35XX/'
    for fn,h in EXPECTED.items():
        if sha(need(pkg+fn))!=h: raise SystemExit('R5_GATE_FAIL=PROTECTED_HASH:'+fn)
    audio=need(pkg+'libaudio.so')
    if sha(audio)!=audio_sha: raise SystemExit('R5_GATE_FAIL=AUDIO_HASH')
    for marker in [b'RG35XX_R5_AUDIO_OWNER_BIND=PASS',b'RG35XX_R5_AUDIO_OWNER_PAUSE=IGNORED_NONOWNER',b'RG35XX_R5_AUDIO_OWNER_RESUME=IGNORED_NONOWNER']:
        if marker not in audio: raise SystemExit('R5_GATE_FAIL=AUDIO_MARKER:'+marker.decode())
    jar=need(pkg+'test/RG35XX-Midi-Ownership-R5.jar')
    with zipfile.ZipFile(io.BytesIO(jar)) as j:
        required={'RG35XXMidiOwnershipDiagnostic.class','RG35XXMidiOwnershipDiagnostic$DiagnosticCanvas.class','owner-a-low.mid','owner-b-high.mid'}
        if not required<=set(j.namelist()): raise SystemExit('R5_GATE_FAIL=OWNER_JAR_ENTRIES')
        cls=j.read('RG35XXMidiOwnershipDiagnostic.class')
        if int.from_bytes(cls[6:8],'big')!=50: raise SystemExit('R5_GATE_FAIL=JAVA_MAJOR')
        for mark in [b'MIDI_OWNER_A1_START=PASS',b'MIDI_OWNER_B_START=PASS',b'MIDI_OWNER_A2_RETURN_START=PASS']:
            if mark not in cls: raise SystemExit('R5_GATE_FAIL=OWNER_TEST_MARKER')
        allb=b''.join(j.read(n) for n in j.namelist() if not n.endswith('/'))
        if b'God-of-War' in allb or b'God Of War' in allb or b'Vua-Cuop-Bien' in allb:
            raise SystemExit('R5_GATE_FAIL=GAME_SPECIFIC_TEST_CONTENT')
    for rel in ['SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh','SD/Roms/APPS/RG35XX-R1-P7-TIER0.sh']:
        s=need(rel).decode('utf-8')
        if ('EXPECTED_AUDIO='+audio_sha) not in s: raise SystemExit('R5_GATE_FAIL=AUDIO_GATE_REBIND:'+rel)
        if ('EXPECTED_AUDIO='+OLD_AUDIO) in s: raise SystemExit('R5_GATE_FAIL=STALE_AUDIO_GATE:'+rel)
    launcher=need('SD/Roms/APPS/FreeJ2ME-RG35XX.sh')
    if b'RG35XX-R1-AUDIO-ROUTE-PRIME.sh' not in launcher: raise SystemExit('R5_GATE_FAIL=PRIME_PATH')
    diag=need('SD/Roms/APPS/RG35XX-R5-MIDI-OWNER-DIAG.sh')
    if b'RG35XX-Midi-Ownership-R5.jar' not in diag: raise SystemExit('R5_GATE_FAIL=DIAG_LAUNCHER')
    if '/mnt/mmc/CFW/java' in (launcher+diag).decode('utf-8','ignore'): raise SystemExit('R5_GATE_FAIL=CFW_JAVA_MUTATION')
    for n in names:
        low=n.lower()
        if low.endswith('.jar') and ('god-of-war' in low or 'vua-cuop-bien' in low): raise SystemExit('R5_GATE_FAIL=COMMERCIAL_JAR')
    for token in ['CANONICAL_PLATFORMPLAYER=UNCHANGED','CANONICAL_MMAPI=UNCHANGED','RUNTIME_SEMANTIC_DELTA=NONE','PLATFORM_JAVA_DELTA=NONE','NATIVE_AUDIO_DELTA=PLAYER_MANAGER_OWNERSHIP_ONLY','GAME_SPECIFIC_CODE=NO','DEVICE_PASS=NO','STABLE=NO']:
        if token not in ident: raise SystemExit('R5_GATE_FAIL=IDENTITY_TOKEN:'+token)
print('R5_AUDIO_OWNER_INDEPENDENT_GATE=PASS')
print('R5_AUDIO_OWNER_PROTECTED_NONAUDIO_HASH_GATE=PASS')
print('R5_AUDIO_OWNER_NATIVE_MARKER_GATE=PASS')
print('R5_AUDIO_OWNER_JAVA6_DIAGNOSTIC_GATE=PASS')
print('R5_AUDIO_OWNER_P6_P7_HASH_REBIND_GATE=PASS')
print('R5_AUDIO_OWNER_A1P5_PRIME_GATE=PASS')
print('R5_AUDIO_OWNER_CANONICAL_JAVA_DELTA=NONE')
print('R5_AUDIO_OWNER_RUNTIME_DELTA=NONE')
print('R5_AUDIO_OWNER_GAME_SPECIFIC_CODE=NO')
print('DEVICE_PASS=NO')
print('STABLE=NO')
print('R5_AUDIO_SHA256='+audio_sha)
print('R5_DEVICE_ZIP_SHA256='+hashlib.sha256(raw).hexdigest())
