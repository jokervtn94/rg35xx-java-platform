#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P3_EXERCISER_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail JAVA8_NOT_SET
for tool in javac jar; do [ -x "$JAVA8/bin/$tool" ] || fail "$tool missing"; done

PLATFORM="${P3_PLATFORM:-$ROOT/out/p2c-input-frontend-candidate-r1/freej2me-rg35xx.jar}"
SRC="$ROOT/tests/p3/RG35XXP3RuntimeServiceExerciser.java"
OUT="$ROOT/out/p3-runtime-service-exerciser"
BUILD="$ROOT/build/p3-runtime-service-exerciser"
CLASSES="$BUILD/classes"
[ -f "$PLATFORM" ] || fail P2C_PLATFORM_MISSING
[ -f "$SRC" ] || fail SOURCE_MISSING

rm -rf "$OUT" "$BUILD"
mkdir -p "$OUT" "$CLASSES" "$BUILD/resources"

grep -q 'P3_RMS_CRUD_ENUMERATE=PASS' "$SRC" || fail rms_marker_missing
grep -q 'P3_FILE_CREATE_WRITE_READ_DELETE=PASS' "$SRC" || fail file_marker_missing
grep -q 'P3_MMAPI_WAV_PAUSE_RESUME=PASS' "$SRC" || fail wav_marker_missing
grep -q 'P3_MMAPI_MIDI_END_OF_MEDIA=PASS' "$SRC" || fail midi_marker_missing
! grep -nE 'org\.recompile\.(rg35xx|mobile)|java\.awt|RG35XXCore2D' "$SRC" || fail direct_backend_reference

python3 - "$BUILD/resources/p3-test.wav" "$BUILD/resources/p3-test.mid" <<'PY'
import math, struct, sys, wave
wav_path, midi_path = sys.argv[1:3]
rate = 22050
with wave.open(wav_path, 'wb') as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(rate)
    frames = bytearray()
    for i in range(rate * 2):
        frames += struct.pack('<h', int(9000 * math.sin(2.0 * math.pi * 440.0 * i / rate)))
    wav.writeframes(bytes(frames))
track = bytearray(b'\x00\xff\x51\x03\x07\xa1\x20')
track += b'\x00\xc0\x00\x00\x90\x3c\x64\x81\x40\x80\x3c\x00\x00\xff\x2f\x00'
midi = b'MThd' + struct.pack('>IHHH', 6, 0, 1, 96)
midi += b'MTrk' + struct.pack('>I', len(track)) + bytes(track)
open(midi_path, 'wb').write(midi)
PY

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PLATFORM" \
  -d "$CLASSES" "$SRC"

cp "$BUILD/resources/p3-test.wav" "$BUILD/resources/p3-test.mid" "$CLASSES/"
cat > "$BUILD/MANIFEST.MF" <<'EOF_MANIFEST'
Manifest-Version: 1.0
MIDlet-Name: RG35XX P3 Runtime Service Exerciser
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Reconstruction
MIDlet-1: RG35XX P3 Runtime Service Exerciser,,org.recompile.rg35xx.p3.RG35XXP3RuntimeServiceExerciser
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
EOF_MANIFEST

JAR="$OUT/RG35XX-Platform-Exerciser-P3-RuntimeService.jar"
"$JAVA8/bin/jar" cfm "$JAR" "$BUILD/MANIFEST.MF" -C "$CLASSES" .

python3 - "$JAR" <<'PY'
import sys, zipfile
jar = sys.argv[1]
with zipfile.ZipFile(jar) as archive:
    names = set(archive.namelist())
    required = {
        'META-INF/MANIFEST.MF',
        'org/recompile/rg35xx/p3/RG35XXP3RuntimeServiceExerciser.class',
        'org/recompile/rg35xx/p3/RG35XXP3RuntimeServiceExerciser$P3Canvas.class',
        'p3-test.wav', 'p3-test.mid'
    }
    missing = required - names
    if missing: raise SystemExit('P3_EXERCISER_JAR_GATE_FAIL missing='+repr(sorted(missing)))
    classes = [n for n in names if n.endswith('.class')]
    for name in classes:
        data = archive.read(name)
        major = int.from_bytes(data[6:8], 'big')
        if major > 50: raise SystemExit('P3_EXERCISER_JAVA6_GATE_FAIL '+name)
        for forbidden in (b'org/recompile/rg35xx/RG35XX', b'org/recompile/mobile', b'java/awt'):
            if forbidden in data: raise SystemExit('P3_EXERCISER_OWNER_BYPASS='+repr(forbidden))
print('P3_EXERCISER_JAVA6_GATE=PASS')
print('P3_EXERCISER_PUBLIC_MIDP_ONLY=YES')
print('P3_EXERCISER_RESOURCE_GATE=PASS')
PY

SHA="$(sha256sum "$JAR" | awk '{print $1}')"
cat > "$OUT/P3-RUNTIME-SERVICE-EXERCISER-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P3_RUNTIME_SERVICE_MODULES
SOURCE=tests/p3/RG35XXP3RuntimeServiceExerciser.java
PLATFORM_PARENT=P2C_INPUT_FRONTEND_PHYSICAL_ACCEPTED
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
LOGICAL_RESOLUTION=176x208
SCOPE=LIFECYCLE,RMS,FILECONNECTION,WAV,MIDI
PUBLIC_MIDP_ONLY=YES
GAME_SPECIFIC_CODE=NO
P3_EXERCISER_SHA256=$SHA
P3_HOST_BUILD=PASS
P3_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_ID
(cd "$OUT" && sha256sum "$JAR" P3-RUNTIME-SERVICE-EXERCISER-IDENTITY.txt > SHA256SUMS.txt && sha256sum -c SHA256SUMS.txt)
echo P3_EXERCISER_BUILD=PASS
echo P3_EXERCISER_JAR_SHA256=$SHA
echo P3_PHYSICAL_TEST=NOT_TESTED
