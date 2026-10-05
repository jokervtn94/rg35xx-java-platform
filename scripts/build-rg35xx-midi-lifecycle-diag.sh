#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
R4_DEVICE_ZIP="${R4_DEVICE_ZIP:-}"
[ -n "$R4_DEVICE_ZIP" ] && [ -f "$R4_DEVICE_ZIP" ] || { echo MIDI_LIFE_BUILD_FAIL=R4_DEVICE_ZIP_MISSING >&2; exit 2; }
EXPECTED_R4_SHA=0e739da19b7f6078e8c9b1b2223cf3fb55a9f95e187830502320a1987282792d
[ "$(sha256sum "$R4_DEVICE_ZIP" | awk '{print $1}')" = "$EXPECTED_R4_SHA" ] || { echo MIDI_LIFE_BUILD_FAIL=R4_PARENT_HASH >&2; exit 3; }

WORK="$ROOT/build/midi-lifecycle-diag"
OUT="$ROOT/out/midi-lifecycle-diag"
rm -rf "$WORK" "$OUT"
mkdir -p "$WORK/r4" "$WORK/classes" "$OUT/RG35XX-MIDI-LIFECYCLE-DIAG/SD/Roms/APPS/FreeJ2ME-RG35XX/test"
unzip -q "$R4_DEVICE_ZIP" -d "$WORK/r4"
R4ROOT="$(find "$WORK/r4" -mindepth 1 -maxdepth 1 -type d -name 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4' -print -quit)"
[ -n "$R4ROOT" ] || { echo MIDI_LIFE_BUILD_FAIL=R4_ROOT >&2; exit 4; }
PLATFORM="$R4ROOT/SD/Roms/APPS/FreeJ2ME-RG35XX/freej2me-rg35xx.jar"
[ "$(sha256sum "$PLATFORM" | awk '{print $1}')" = "a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00" ] || { echo MIDI_LIFE_BUILD_FAIL=R4_PLATFORM_HASH >&2; exit 5; }

python3 - "$WORK/tone.mid" <<'PY'
import struct, sys
p=sys.argv[1]
def vlq(n):
    b=[n&0x7f]; n >>= 7
    while n:
        b.append((n&0x7f)|0x80); n >>= 7
    return bytes(reversed(b))
ev=[]
ev.append((0,b'\xff\x51\x03\x07\xa1\x20')) # 120 BPM
ev.append((0,b'\xc0\x00'))
for note in [60,64,67,72,67,64,60,55,60,64,67,72,67,64,60,55]:
    ev.append((0,bytes([0x90,note,110])))
    ev.append((192,bytes([0x80,note,0])))
track=b''.join(vlq(dt)+msg for dt,msg in ev)+b'\x00\xff\x2f\x00'
data=b'MThd'+struct.pack('>IHHH',6,0,1,96)+b'MTrk'+struct.pack('>I',len(track))+track
open(p,'wb').write(data)
print('MIDI_LIFE_TONE_SIZE=%d' % len(data))
print('MIDI_LIFE_TONE_FORMAT=%d TRACKS=%d DIV=%d' % (int.from_bytes(data[8:10],'big'),int.from_bytes(data[10:12],'big'),int.from_bytes(data[12:14],'big')))
PY

SRC="$ROOT/tests/diagnostics/RG35XXMidiLifecycleDiagnostic.java"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -f "$SRC" ] || { echo MIDI_LIFE_BUILD_FAIL=SOURCE_MISSING >&2; exit 6; }
[ -n "$JAVA8" ] && [ -x "$JAVA8/bin/javac" ] && [ -x "$JAVA8/bin/jar" ] || { echo MIDI_LIFE_BUILD_FAIL=JAVA8_MISSING >&2; exit 7; }
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -classpath "$PLATFORM" -d "$WORK/classes" "$SRC"
cat > "$WORK/MANIFEST.MF" <<'MANIFEST'
Manifest-Version: 1.0
MIDlet-Name: RG35XX MIDI Lifecycle Diagnostic
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Diagnostics
MIDlet-1: RG35XX MIDI Lifecycle Diagnostic,,RG35XXMidiLifecycleDiagnostic
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
MANIFEST

TESTDIR="$OUT/RG35XX-MIDI-LIFECYCLE-DIAG/SD/Roms/APPS/FreeJ2ME-RG35XX/test"
for mode in C0 C1 C2 C3; do
  STAGE="$WORK/stage-$mode"
  rm -rf "$STAGE"; mkdir -p "$STAGE"
  cp -a "$WORK/classes/." "$STAGE/"
  cp "$WORK/tone.mid" "$STAGE/tone.mid"
  printf '%s\n' "$mode" > "$STAGE/mode.txt"
  "$JAVA8/bin/jar" cfm "$TESTDIR/RG35XX-Midi-Life-$mode.jar" "$WORK/MANIFEST.MF" -C "$STAGE" .
done

python3 - "$TESTDIR" <<'PY'
import sys,zipfile,hashlib,os
root=sys.argv[1]
for mode in ['C0','C1','C2','C3']:
    p=os.path.join(root,'RG35XX-Midi-Life-%s.jar'%mode)
    with zipfile.ZipFile(p) as z:
        names=set(z.namelist())
        need={'RG35XXMidiLifecycleDiagnostic.class','RG35XXMidiLifecycleDiagnostic$DiagnosticCanvas.class','tone.mid','mode.txt','META-INF/MANIFEST.MF'}
        assert need <= names
        cls=z.read('RG35XXMidiLifecycleDiagnostic.class')
        assert int.from_bytes(cls[6:8],'big') == 50
        assert z.read('mode.txt').strip().decode() == mode
        t=z.read('tone.mid')
        assert t[:4] == b'MThd' and int.from_bytes(t[8:10],'big') == 0 and int.from_bytes(t[10:12],'big') == 1
    print('MIDI_LIFE_JAR_%s_SHA256=%s'%(mode,hashlib.sha256(open(p,'rb').read()).hexdigest()))
print('MIDI_LIFE_JAVA6_GATE=PASS')
print('MIDI_LIFE_FIXTURE_GATE=PASS')
PY

SCRIPT="$OUT/RG35XX-MIDI-LIFECYCLE-DIAG/SD/Roms/APPS/RG35XX-MIDI-LIFECYCLE-DIAG.sh"
cat > "$SCRIPT" <<'SH'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
BASELOG=/mnt/mmc/RG35XX-MIDI-LIFECYCLE-DIAG.log
OBS=/mnt/mmc/RG35XX-MIDI-LIFECYCLE-DIAG-OBSERVATION.txt
sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
fail(){ echo "MIDI_LIFE_LAUNCH=FAIL:$1" >"$BASELOG"; sync; exit 20; }
gate(){ [ -f "$1" ] || fail "MISSING:$1"; [ "$(sha "$1")" = "$2" ] || fail "HASH:$1"; }

gate "$RUNTIME/bin/jamvm" 0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
gate "$RUNTIME/share/classpath/glibj.zip" c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
gate "$PKG/freej2me-rg35xx.jar" a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
gate "$PKG/librg35xx_input.so" 6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
gate "$PKG/librg35xx_video.so" c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
gate "$PKG/librg35xx_font.so" 29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
gate "$PKG/libaudio.so" 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
gate "$PKG/a7-a1p5-rw-silence-prime.s32le" 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
gate "$PKG/font.ttf" 1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10

echo MIDI_LIFE_LAUNCH=BEGIN >"$BASELOG"
echo MIDI_LIFE_IDENTITY_GATE=PASS >>"$BASELOG"
cat >"$OBS" <<'OBS'
C0_FIRST_PLAY_AUDIBLE=NOT_TESTED
C1A_BEFORE_STOP_AUDIBLE=NOT_TESTED
C1B_SAME_PLAYER_RESUME_AUDIBLE=NOT_TESTED
C2A_BEFORE_FREE_AUDIBLE=NOT_TESTED
C2B_RELOAD_AFTER_FREE_AUDIBLE=NOT_TESTED
C3A_FIRST_PRELOADED_PLAYER_AUDIBLE=NOT_TESTED
C3B_SECOND_PRELOADED_PLAYER_AUDIBLE=NOT_TESTED
INTERPRETATION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
OBS

export SDL_AUDIODRIVER=alsa
for MODE in C0 C1 C2 C3; do
  JAR="$PKG/test/RG35XX-Midi-Life-$MODE.jar"
  [ -f "$JAR" ] || fail "MISSING_JAR_$MODE"
  PRIMELOG="/mnt/mmc/RG35XX-MIDI-LIFECYCLE-$MODE-PRIME.log"
  { echo A1P5_AUDIO_ROUTE_PRIME=BEGIN; } >"$PRIMELOG"
  aplay -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 < "$PKG/a7-a1p5-rw-silence-prime.s32le"
  PRC=$?
  echo A1P5_AUDIO_ROUTE_PRIME_EXIT_CODE=$PRC >>"$PRIMELOG"
  [ "$PRC" -eq 0 ] || fail "PRIME_$MODE"
  echo A1P5_AUDIO_ROUTE_PRIME=PASS >>"$PRIMELOG"
  LOG="/mnt/mmc/RG35XX-MIDI-LIFECYCLE-$MODE.log"
  echo "MIDI_LIFE_MODE=$MODE" >>"$BASELOG"
  LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$RUNTIME/bin/jamvm" -Xmx64m -Drg35xx.raw2d=true \
    -Drg35xx.native.dir="$PKG" \
    -Drg35xx.font.path="$PKG/font.ttf" \
    -Drg35xx.font.native.path="$PKG/librg35xx_font.so" \
    -cp "$RUNTIME/share/classpath/glibj.zip:$PKG/freej2me-rg35xx.jar" \
    org.recompile.rg35xx.RG35XXLauncher "$JAR" 240 320 \
    "$PKG/data/RG35XX-Midi-Life-$MODE" "$PKG/rms/RG35XX-Midi-Life-$MODE" >"$LOG" 2>&1
  RC=$?
  echo "MIDI_LIFE_MODE_${MODE}_JVM_EXIT=$RC" >>"$BASELOG"
  [ "$RC" -eq 0 ] || fail "JVM_$MODE:$RC"
  sleep 2
done

echo MIDI_LIFE_PROGRAMMATIC_SEQUENCE=PASS >>"$BASELOG"
echo MIDI_LIFE_PHYSICAL_REVIEW_REQUIRED=YES >>"$BASELOG"
sync
exit 0
SH
chmod +x "$SCRIPT"

cat > "$OUT/RG35XX-MIDI-LIFECYCLE-DIAG/README.txt" <<'EOF'
RG35XX MIDI lifecycle diagnostic — diagnostic only, no production binary replacement.
Copy SD/ contents to SD root and run RG35XX-MIDI-LIFECYCLE-DIAG.
Each C0-C3 case runs in a fresh JVM using the SAME simple format-0 MIDI tone.
Report audible phases shown on screen:
C0 first playback
C1A same Player before stop; C1B same Player after stop/start
C2A before deallocate/free; C2B new Player after free/reload
C3A first of two preloaded Players; C3B second preloaded Player after first is freed
EOF

(cd "$OUT/RG35XX-MIDI-LIFECYCLE-DIAG" && zip -qr -X "$OUT/RG35XX-MIDI-LIFECYCLE-DIAG.zip" .)
echo MIDI_LIFE_BUILD=PASS
echo MIDI_LIFE_PRODUCTION_BINARY_DELTA=NONE
echo MIDI_LIFE_GAME_SPECIFIC_CODE=NO
echo MIDI_LIFE_ZIP_SHA256=$(sha256sum "$OUT/RG35XX-MIDI-LIFECYCLE-DIAG.zip" | awk '{print $1}')
