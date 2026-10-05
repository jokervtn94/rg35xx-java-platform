#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
R4_DEVICE_ZIP="${R4_DEVICE_ZIP:-}"
[ -n "$R4_DEVICE_ZIP" ] && [ -f "$R4_DEVICE_ZIP" ] || { echo AUDIO_DIAG_BUILD_FAIL=R4_DEVICE_ZIP_MISSING >&2; exit 2; }
EXPECTED_R4_SHA=0e739da19b7f6078e8c9b1b2223cf3fb55a9f95e187830502320a1987282792d
[ "$(sha256sum "$R4_DEVICE_ZIP" | awk '{print $1}')" = "$EXPECTED_R4_SHA" ] || { echo AUDIO_DIAG_BUILD_FAIL=R4_PARENT_HASH >&2; exit 3; }

WORK="$ROOT/build/audio-boundary-diag"
OUT="$ROOT/out/audio-boundary-diag"
rm -rf "$WORK" "$OUT"
mkdir -p "$WORK/r4" "$WORK/classes" "$OUT/RG35XX-AUDIO-BOUNDARY-DIAG/SD/Roms/APPS/FreeJ2ME-RG35XX/test"
unzip -q "$R4_DEVICE_ZIP" -d "$WORK/r4"
R4ROOT="$(find "$WORK/r4" -mindepth 1 -maxdepth 1 -type d -name 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4' -print -quit)"
[ -n "$R4ROOT" ] || { echo AUDIO_DIAG_BUILD_FAIL=R4_ROOT >&2; exit 4; }
PLATFORM="$R4ROOT/SD/Roms/APPS/FreeJ2ME-RG35XX/freej2me-rg35xx.jar"
[ "$(sha256sum "$PLATFORM" | awk '{print $1}')" = "a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00" ] || { echo AUDIO_DIAG_BUILD_FAIL=R4_PLATFORM_HASH >&2; exit 5; }

python3 - "$WORK/classes/diag-complex-format1.mid" "$WORK/classes/diag-bgm-loop.mid" "$WORK/classes/diag-fx-silent-tail.mid" <<'PY'
import struct, sys
complex_path, bgm_path, fx_path = sys.argv[1:4]

def vlq(n):
    n=int(n); b=[n & 0x7f]; n >>= 7
    while n:
        b.append((n & 0x7f) | 0x80); n >>= 7
    return bytes(reversed(b))

def trk(events):
    data=b''.join(vlq(dt)+ev for dt,ev in events)+b'\x00\xff\x2f\x00'
    return b'MTrk'+struct.pack('>I',len(data))+data

def midi(fmt, division, tracks):
    return b'MThd'+struct.pack('>IHHH',6,fmt,len(tracks),division)+b''.join(tracks)

div=960
tracks=[]
tracks.append(trk([(0,b'\xff\x51\x03\x07\xa1\x20'), (0,b'\xff\x58\x04\x04\x02\x18\x08')]))
programs=[0,4,12,24,32,40,48,60,72,80]
channels=[0,1,2,3,4,5,6,7,8,10]
base=[48,52,55,60,64,67,72,76,79,84]
for ti,(ch,prog,note0) in enumerate(zip(channels,programs,base)):
    ev=[(0,bytes([0xC0|ch, prog]))]
    for step in range(16):
        note=note0 + (step % 4)
        ev.append((0,bytes([0x90|ch,note,70 + (ti%3)*10])))
        ev.append((480,bytes([0x80|ch,note,0])))
        ev.append((480,b'\xff\x01\x00'))
    tracks.append(trk(ev))
open(complex_path,'wb').write(midi(1,div,tracks))

ev=[(0,b'\xc0\x20')]
for note in [48,52,55,52,48,55,52,48]:
    ev.append((0,bytes([0x90,note,100])))
    ev.append((480,bytes([0x80,note,0])))
open(bgm_path,'wb').write(midi(0,div,[trk(ev)]))

ev=[(0,b'\xc0\x50'),
    (0,b'\x90\x60\x7f'), (240,b'\x80\x60\x00'),
    (0,b'\x90\x67\x7f'), (240,b'\x80\x67\x00'),
    (57600,b'\xff\x01\x00')]
open(fx_path,'wb').write(midi(0,div,[trk(ev)]))

for p in (complex_path,bgm_path,fx_path):
    d=open(p,'rb').read()
    assert d[:4] == b'MThd'
    print('AUDIO_DIAG_MIDI_GENERATED=%s SIZE=%d FORMAT=%d TRACKS=%d DIV=%d' %
          (p.split('/')[-1], len(d), int.from_bytes(d[8:10],'big'), int.from_bytes(d[10:12],'big'), int.from_bytes(d[12:14],'big')))
PY

SRC="$ROOT/tests/diagnostics/RG35XXAudioBoundaryDiagnostic.java"
[ -f "$SRC" ] || { echo AUDIO_DIAG_BUILD_FAIL=SOURCE_MISSING >&2; exit 6; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] && [ -x "$JAVA8/bin/javac" ] && [ -x "$JAVA8/bin/jar" ] || { echo AUDIO_DIAG_BUILD_FAIL=JAVA8_MISSING >&2; exit 7; }
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -classpath "$PLATFORM" -d "$WORK/classes" "$SRC"

cat > "$WORK/MANIFEST.MF" <<'MANIFEST'
Manifest-Version: 1.0
MIDlet-Name: RG35XX Audio Boundary Diagnostic
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Diagnostics
MIDlet-1: RG35XX Audio Boundary Diagnostic,,RG35XXAudioBoundaryDiagnostic
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
MANIFEST
JAR="$OUT/RG35XX-AUDIO-BOUNDARY-DIAG/SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Audio-Boundary-Diagnostic.jar"
"$JAVA8/bin/jar" cfm "$JAR" "$WORK/MANIFEST.MF" -C "$WORK/classes" .

python3 - "$JAR" <<'PY'
import sys, zipfile, hashlib
p=sys.argv[1]
with zipfile.ZipFile(p) as z:
    need={'RG35XXAudioBoundaryDiagnostic.class','RG35XXAudioBoundaryDiagnostic$DiagnosticCanvas.class','diag-complex-format1.mid','diag-bgm-loop.mid','diag-fx-silent-tail.mid','META-INF/MANIFEST.MF'}
    names=set(z.namelist())
    assert need <= names, sorted(need-names)
    b=z.read('RG35XXAudioBoundaryDiagnostic.class')
    assert int.from_bytes(b[6:8],'big') == 50
    for marker in [b'AUDIO_DIAG_A_COMPLEX_START=PASS', b'AUDIO_DIAG_B1_BGM_START=PASS', b'AUDIO_DIAG_B2_FX_START=PASS', b'AUDIO_DIAG_B3_BGM_RESTART=PASS', b'AUDIO_DIAG_PROGRAMMATIC_RESULT=PASS']:
        assert marker in b, marker
    allbytes=b''.join(z.read(n) for n in z.namelist() if not n.endswith('/'))
    assert b'God-of-War' not in allbytes and b'God Of War' not in allbytes
print('AUDIO_DIAG_JAVA6_GATE=PASS')
print('AUDIO_DIAG_RESOURCE_GATE=PASS')
print('AUDIO_DIAG_GAME_SPECIFIC_CONTENT=NO')
print('AUDIO_DIAG_JAR_SHA256='+hashlib.sha256(open(p,'rb').read()).hexdigest())
PY

SCRIPT="$OUT/RG35XX-AUDIO-BOUNDARY-DIAG/SD/Roms/APPS/RG35XX-AUDIO-BOUNDARY-DIAG.sh"
cat > "$SCRIPT" <<'SH'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
BOOTSTRAP="$APPS/RG35XX-R1-RUNTIME-BOOTSTRAP.sh"
JAR="$PKG/test/RG35XX-Audio-Boundary-Diagnostic.jar"
LOG=/mnt/mmc/RG35XX-AUDIO-BOUNDARY-DIAG.log
PRIMELOG=/mnt/mmc/RG35XX-AUDIO-BOUNDARY-DIAG-PRIME.log
OBS=/mnt/mmc/RG35XX-AUDIO-BOUNDARY-DIAG-OBSERVATION.txt

sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
fail(){ echo "AUDIO_DIAG_LAUNCH=FAIL:$1" >"$LOG"; sync; exit 20; }
gate(){ [ -f "$1" ] || fail "MISSING:$1"; [ "$(sha "$1")" = "$2" ] || fail "HASH:$1"; }

[ -x "$BOOTSTRAP" ] || fail BOOTSTRAP_MISSING
RG35XX_R1_BOOTSTRAP_LOG=/mnt/mmc/RG35XX-AUDIO-BOUNDARY-DIAG-BOOTSTRAP.log "$BOOTSTRAP" || fail BOOTSTRAP_FAILED

gate "$RUNTIME/bin/jamvm" 0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
gate "$RUNTIME/share/classpath/glibj.zip" c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
gate "$PKG/freej2me-rg35xx.jar" a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
gate "$PKG/librg35xx_input.so" 6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
gate "$PKG/librg35xx_video.so" c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
gate "$PKG/librg35xx_font.so" 29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
gate "$PKG/libaudio.so" 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
gate "$PKG/a7-a1p5-rw-silence-prime.s32le" 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
gate "$PKG/font.ttf" 1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
gate "$JAR" __DIAG_JAR_SHA__

cat >"$OBS" <<'OBSERVATION'
A_COMPLEX_FORMAT1_AUDIBLE=NOT_TESTED
B1_INITIAL_BGM_AUDIBLE=NOT_TESTED
B2_HIGH_FX_AUDIBLE=NOT_TESTED
B3_BGM_RETURN_AUDIBLE=NOT_TESTED
INTERPRETATION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
OBSERVATION

FREEJ2ME_LOG="$LOG" RG35XX_AUDIO_ROUTE_LOG="$PRIMELOG" \
  "$APPS/FreeJ2ME-RG35XX.sh" "$JAR" 240 320
RC=$?
echo "AUDIO_DIAG_WRAPPER_EXIT=$RC" >>"$LOG"
echo "AUDIO_DIAG_PHYSICAL_REVIEW_REQUIRED=YES" >>"$LOG"
sync
exit "$RC"
SH
JAR_SHA="$(sha256sum "$JAR" | awk '{print $1}')"
sed -i "s/__DIAG_JAR_SHA__/$JAR_SHA/" "$SCRIPT"
chmod +x "$SCRIPT"

cat > "$OUT/RG35XX-AUDIO-BOUNDARY-DIAG/README.txt" <<EOF_README
RG35XX generic audio boundary diagnostic — diagnostic only.
Parent required: exact installed R4 platform/runtime; package does not replace production files.

Copy contents of SD/ to SD root, then run RG35XX-AUDIO-BOUNDARY-DIAG.
Listen to four phases shown on screen:
A  = complex format-1 MIDI, should be clearly audible for ~6 sec.
B1 = low repeating BGM, should be audible for ~4 sec.
B2 = short high FX, then silence.
B3 = low BGM must return for ~5 sec.

Interpretation:
- A silent: complex SDL1 MIDI boundary implicated.
- A+B1+B2 audible, B3 silent: multi-Player/global Mix_Music lifecycle collision proven.
- A+B3 audible: current hypothesis not reproduced; do not patch production.

AUDIO_DIAG_JAR_SHA256=$JAR_SHA
RUNTIME_SEMANTIC_DELTA=NONE
PLATFORM_SEMANTIC_DELTA=NONE
NATIVE_AUDIO_DELTA=NONE
GAME_SPECIFIC_CODE=NO
DEVICE_PASS=NO
STABLE=NO
EOF_README

(cd "$OUT/RG35XX-AUDIO-BOUNDARY-DIAG" && zip -qr -X "$OUT/RG35XX-AUDIO-BOUNDARY-DIAG.zip" .)
echo AUDIO_DIAG_BUILD=PASS
echo AUDIO_DIAG_JAR_SHA256=$JAR_SHA
echo AUDIO_DIAG_ZIP_SHA256=$(sha256sum "$OUT/RG35XX-AUDIO-BOUNDARY-DIAG.zip" | awk '{print $1}')
echo AUDIO_DIAG_RUNTIME_SEMANTIC_DELTA=NONE
echo AUDIO_DIAG_PLATFORM_SEMANTIC_DELTA=NONE
echo AUDIO_DIAG_NATIVE_AUDIO_DELTA=NONE
echo AUDIO_DIAG_GAME_SPECIFIC_CODE=NO
