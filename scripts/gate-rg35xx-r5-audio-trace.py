#!/usr/bin/env python3
import hashlib, io, re, sys, zipfile

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-r5-audio-trace.py <zip>')

def sha(data):
    return hashlib.sha256(data).hexdigest()

with zipfile.ZipFile(sys.argv[1]) as z:
    names = set(z.namelist())
    root = 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-AUDIO-TRACE/'
    def need(rel):
        path = root + rel
        if path not in names:
            raise SystemExit('R5_TRACE_GATE_FAIL=MISSING:' + rel)
        return z.read(path)

    ident = need('R5-AUDIO-TRACE-IDENTITY.txt').decode('utf-8')
    m = re.search(r'^TRACE_AUDIO_SHA256=([0-9a-f]{64})$', ident, re.M)
    if not m:
        raise SystemExit('R5_TRACE_GATE_FAIL=TRACE_AUDIO_IDENTITY')
    audio_sha = m.group(1)
    audio = need('SD/Roms/APPS/FreeJ2ME-RG35XX/libaudio.so')
    if sha(audio) != audio_sha:
        raise SystemExit('R5_TRACE_GATE_FAIL=TRACE_AUDIO_HASH')
    for marker in [b'RG35XX_AUDIO_TRACE event=', b'RG35XX_R5_AUDIO_OWNER_PLAY=',
                   b'RG35XX_R5_AUDIO_OWNER_BIND=PASS']:
        if marker not in audio:
            raise SystemExit('R5_TRACE_GATE_FAIL=AUDIO_MARKER:' + marker.decode())
    for rel in ['SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh',
                'SD/Roms/APPS/RG35XX-R1-P7-TIER0.sh']:
        text = need(rel).decode('utf-8')
        if 'export RG35XX_AUDIO_TRACE=1' not in text:
            raise SystemExit('R5_TRACE_GATE_FAIL=TRACE_ENV:' + rel)
        if 'EXPECTED_AUDIO=' + audio_sha not in text:
            raise SystemExit('R5_TRACE_GATE_FAIL=AUDIO_HASH_REBIND:' + rel)
    for token in ['CANONICAL_PLATFORMPLAYER=UNCHANGED',
                  'CANONICAL_MMAPI=UNCHANGED',
                  'RUNTIME_SEMANTIC_DELTA=NONE',
                  'PLATFORM_JAVA_DELTA=NONE',
                  'NATIVE_AUDIO_DELTA=DIAGNOSTIC_TRACE_ONLY',
                  'GAME_SPECIFIC_CODE=NO', 'DEVICE_PASS=NO', 'STABLE=NO']:
        if token not in ident:
            raise SystemExit('R5_TRACE_GATE_FAIL=IDENTITY_TOKEN:' + token)
    for name in names:
        low = name.lower()
        if low.endswith('.jar') and ('god-of-war' in low or 'vua-cuop-bien' in low):
            raise SystemExit('R5_TRACE_GATE_FAIL=COMMERCIAL_JAR')

print('R5_AUDIO_TRACE_INDEPENDENT_GATE=PASS')
print('R5_AUDIO_TRACE_NATIVE_MARKER_GATE=PASS')
print('R5_AUDIO_TRACE_LAUNCHER_ENV_GATE=PASS')
print('R5_AUDIO_TRACE_CANONICAL_JAVA_DELTA=NONE')
print('R5_AUDIO_TRACE_GAME_SPECIFIC_CODE=NO')
print('DEVICE_PASS=NO')
print('STABLE=NO')
print('R5_AUDIO_TRACE_SHA256=' + audio_sha)
print('R5_AUDIO_TRACE_DEVICE_ZIP_SHA256=' + sha(open(sys.argv[1], 'rb').read()))
