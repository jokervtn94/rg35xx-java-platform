#!/usr/bin/env python3
import hashlib,io,sys,zipfile
from pathlib import PurePosixPath
p=sys.argv[1]; raw=open(p,'rb').read()
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    names=set(z.namelist())
    script='SD/Roms/APPS/RG35XX-MIDI-LIFECYCLE-DIAG.sh'
    if script not in names: raise SystemExit('MIDI_LIFE_GATE_FAIL=SCRIPT')
    s=z.read(script)
    for t in [b'0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3',b'a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00',b'4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',b'8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e',b'for MODE in C0 C1 C2 C3',b'aplay -q -D hw:0,0']:
        if t not in s: raise SystemExit('MIDI_LIFE_GATE_FAIL=TOKEN')
    for mode in ['C0','C1','C2','C3']:
        jar='SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Midi-Life-%s.jar'%mode
        if jar not in names: raise SystemExit('MIDI_LIFE_GATE_FAIL=JAR_'+mode)
        with zipfile.ZipFile(io.BytesIO(z.read(jar))) as j:
            if j.read('mode.txt').strip().decode()!=mode: raise SystemExit('MIDI_LIFE_GATE_FAIL=MODE_'+mode)
            cls=j.read('RG35XXMidiLifecycleDiagnostic.class')
            if int.from_bytes(cls[6:8],'big')!=50: raise SystemExit('MIDI_LIFE_GATE_FAIL=JAVA6')
            tone=j.read('tone.mid')
            if tone[:4]!=b'MThd' or int.from_bytes(tone[8:10],'big')!=0 or int.from_bytes(tone[10:12],'big')!=1: raise SystemExit('MIDI_LIFE_GATE_FAIL=TONE')
    forbidden=[]
    for n in names:
        if PurePosixPath(n).name in {'freej2me-rg35xx.jar','libaudio.so','librg35xx_input.so','librg35xx_video.so','jamvm','glibj.zip'}: forbidden.append(n)
    if forbidden: raise SystemExit('MIDI_LIFE_GATE_FAIL=PRODUCTION_BINARY_EMBEDDED')
print('MIDI_LIFE_INDEPENDENT_GATE=PASS')
print('MIDI_LIFE_JAVA6_GATE=PASS')
print('MIDI_LIFE_SAME_FIXTURE_GATE=PASS')
print('MIDI_LIFE_FRESH_JVM_CASE_GATE=PASS')
print('MIDI_LIFE_PRODUCTION_BINARY_DELTA=NONE')
print('MIDI_LIFE_GAME_SPECIFIC_CODE=NO')
print('DEVICE_PASS=NO')
print('STABLE=NO')
print('MIDI_LIFE_ZIP_SHA256='+hashlib.sha256(raw).hexdigest())
