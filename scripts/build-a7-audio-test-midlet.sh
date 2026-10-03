#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A7_AUDIO_TEST_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"

DST="$ROOT/out/a7-audio-sdl1"
SRC="$ROOT/tests/a7/A7AudioMediaTest.java"
WORK="$ROOT/build/a7-audio-test"
CLASSES="$WORK/classes"
RES="$WORK/resources"
MANIFEST="$WORK/MANIFEST.MF"
OUT="$DST/A7AudioMediaTest.jar"
[ -f "$DST/freej2me-rg35xx.jar" ] || fail "A7 platform missing"
[ -f "$DST/libaudio.so" ] || fail "A7 audio native missing"
[ -f "$SRC" ] || fail "test source missing"

rm -rf "$WORK"
mkdir -p "$CLASSES" "$RES"

python3 - "$RES/a7-test.wav" "$RES/a7-test.mid" <<'PY'
import math, struct, sys, wave
wav_path, midi_path = sys.argv[1:3]
rate=22050
seconds=3.0
amp=9000
with wave.open(wav_path,'wb') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(rate)
    frames=bytearray()
    for i in range(int(rate*seconds)):
        sample=int(amp*math.sin(2.0*math.pi*440.0*i/rate))
        frames += struct.pack('<h', sample)
    w.writeframes(bytes(frames))
# SMF format 0, division 96, 120 BPM. C4 for 192 ticks ~= 1 second.
track=bytearray()
track += b'\x00\xff\x51\x03\x07\xa1\x20'       # tempo 500000 us/qn
track += b'\x00\xc0\x00'                           # program 0
track += b'\x00\x90\x3c\x64'                     # note on C4
track += b'\x81\x40\x80\x3c\x00'                # delta 192, note off
track += b'\x00\xff\x2f\x00'                     # end track
midi=(b'MThd'+struct.pack('>IHHH',6,0,1,96)+
      b'MTrk'+struct.pack('>I',len(track))+bytes(track))
open(midi_path,'wb').write(midi)
PY

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$DST/freej2me-rg35xx.jar" \
  -d "$CLASSES" "$SRC"

cat > "$MANIFEST" <<'EOF'
Manifest-Version: 1.0
MIDlet-Name: A7 Audio Media Test
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX A7 Integration
MIDlet-1: A7 Audio Media Test,,A7AudioMediaTest
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
EOF

cp "$RES/a7-test.wav" "$CLASSES/a7-test.wav"
cp "$RES/a7-test.mid" "$CLASSES/a7-test.mid"
"$JAVA8/bin/jar" cfm "$OUT" "$MANIFEST" -C "$CLASSES" .

python3 - "$OUT" <<'PY'
import sys, zipfile
p=sys.argv[1]
with zipfile.ZipFile(p) as z:
    names=set(z.namelist())
    need={'A7AudioMediaTest.class','a7-test.wav','a7-test.mid','META-INF/MANIFEST.MF'}
    if not need.issubset(names):
        raise SystemExit('A7_AUDIO_TEST_JAR_GATE_FAIL missing='+repr(sorted(need-names)))
    b=z.read('A7AudioMediaTest.class')
    major=int.from_bytes(b[6:8],'big')
    if major != 50:
        raise SystemExit('A7_AUDIO_TEST_JAVA6_GATE_FAIL major=%d' % major)
    for marker in [b'A7_TEST_WAV_CREATE=PASS', b'A7_TEST_MIDI_END_OF_MEDIA=PASS', b'A7_TEST_NORMAL_EXIT=BEGIN']:
        if marker not in b:
            raise SystemExit('A7_AUDIO_TEST_MARKER_GATE_FAIL '+repr(marker))
print('A7_AUDIO_TEST_JAVA6_GATE=PASS')
print('A7_AUDIO_TEST_RESOURCE_GATE=PASS')
print('A7_AUDIO_TEST_MARKER_GATE=PASS')
PY

TEST_SHA="$(sha256sum "$OUT" | awk '{print $1}')"
WAV_SHA="$(sha256sum "$RES/a7-test.wav" | awk '{print $1}')"
MIDI_SHA="$(sha256sum "$RES/a7-test.mid" | awk '{print $1}')"
python3 - "$DST/A7-AUDIO-IDENTITY.txt" "$TEST_SHA" "$WAV_SHA" "$MIDI_SHA" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
extra='A7_AUDIO_TEST_JAR_SHA256='+sys.argv[2]+'\nA7_AUDIO_TEST_WAV_SHA256='+sys.argv[3]+'\nA7_AUDIO_TEST_MIDI_SHA256='+sys.argv[4]+'\nA7_AUDIO_TEST_JAVA_MAJOR=50\nA7_AUDIO_TEST_MEDIA=GENERATED_NONCOMMERCIAL\nA7_AUDIO_TEST_PLAYTONE=EXCLUDED_CANONICAL_NOOP\n'
if 'A7_AUDIO_TEST_JAR_SHA256=' not in s:
    s=s.replace('BUILD-PASS=YES\n', extra+'BUILD-PASS=YES\n')
p.write_text(s,encoding='utf-8')
PY

(cd "$DST" && find . -maxdepth 1 -type f ! -name A7-ARTIFACT-SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum) > "$DST/A7-ARTIFACT-SHA256SUMS.txt"
(cd "$DST" && sha256sum -c A7-ARTIFACT-SHA256SUMS.txt)
echo A7_AUDIO_TEST_MIDLET_BUILD=PASS
echo A7_AUDIO_TEST_JAR_SHA256=$TEST_SHA
