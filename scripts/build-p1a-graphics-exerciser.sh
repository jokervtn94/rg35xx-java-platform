#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || { echo 'P1A_EXERCISER_BUILD_FAIL=JAVA8/JAVA_HOME not set' >&2; exit 1; }
JAVAC="$JAVA8/bin/javac"
JAR="$JAVA8/bin/jar"
[ -x "$JAVAC" ] || { echo "P1A_EXERCISER_BUILD_FAIL=javac missing $JAVAC" >&2; exit 1; }
[ -x "$JAR" ] || { echo "P1A_EXERCISER_BUILD_FAIL=jar missing $JAR" >&2; exit 1; }

PLATFORM="$ROOT/out/p1a-complete-graphics-candidate/freej2me-rg35xx.jar"
SRC="$ROOT/tests/p1a/exerciser/RG35XXPlatformExerciserP1A.java"
BUILD="$ROOT/build/p1a-graphics-exerciser"
OUT="$ROOT/out/p1a-complete-graphics-candidate"
JAROUT="$OUT/RG35XX-Platform-Exerciser-P1A.jar"
IDENTITY="$OUT/P1A-EXERCISER-IDENTITY.txt"

[ -f "$PLATFORM" ] || { echo 'P1A_EXERCISER_BUILD_FAIL=complete graphics platform jar missing' >&2; exit 1; }
[ -f "$SRC" ] || { echo 'P1A_EXERCISER_BUILD_FAIL=source missing' >&2; exit 1; }
rm -rf "$BUILD"
mkdir -p "$BUILD/classes"

"$JAVAC" \
  -encoding UTF-8 \
  -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PLATFORM" \
  -d "$BUILD/classes" \
  "$SRC"

cat > "$BUILD/MANIFEST.MF" <<'EOF'
Manifest-Version: 1.0
MIDlet-Name: RG35XX Platform Exerciser P1A
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Reconstruction
MIDlet-1: RG35XX Platform Exerciser P1A,,RG35XXPlatformExerciserP1A
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
EOF

rm -f "$JAROUT"
"$JAR" cfm "$JAROUT" "$BUILD/MANIFEST.MF" -C "$BUILD/classes" .

python3 - "$JAROUT" "$IDENTITY" <<'PY'
import hashlib
import sys
import zipfile

jar, identity = sys.argv[1], sys.argv[2]
required = {
    'RG35XXPlatformExerciserP1A.class',
    'RG35XXPlatformExerciserP1A$P1ACanvas.class',
    'META-INF/MANIFEST.MF',
}
majors = set()
with zipfile.ZipFile(jar) as z:
    names = set(z.namelist())
    missing = required - names
    if missing:
        raise SystemExit('P1A_EXERCISER_JAR_GATE_FAIL missing=' + repr(sorted(missing)))
    extra_classes = sorted(n for n in names if n.endswith('.class') and n not in required)
    if extra_classes:
        raise SystemExit('P1A_EXERCISER_JAR_GATE_FAIL unexpected_classes=' + repr(extra_classes))
    marker_blob = b''.join(z.read(n) for n in names if n.endswith('.class'))
    for marker in (
        b'P1A_EXERCISER_BOOT=PASS',
        b'P1A_EXERCISER_RESULT=',
        b'DG_GETPIXELS_BYTE_STUB',
        b'CLEAR_COPY_OVERLAP',
        b'DG_IMAGE_MANIP',
        b'CLIP_TRANSLATE',
        b'ALPHA_MATRIX',
    ):
        if marker not in marker_blob:
            raise SystemExit('P1A_EXERCISER_MARKER_GATE_FAIL marker=' + repr(marker))
    for n in names:
        if n.endswith('.class'):
            b = z.read(n)
            if b[:4] != b'\xca\xfe\xba\xbe':
                raise SystemExit('P1A_EXERCISER_CLASS_GATE_FAIL bad_magic=' + n)
            major = int.from_bytes(b[6:8], 'big')
            majors.add(major)
            if major > 50:
                raise SystemExit('P1A_EXERCISER_JAVA6_GATE_FAIL %s major=%d' % (n, major))

data = open(jar, 'rb').read()
sha = hashlib.sha256(data).hexdigest()
with open(identity, 'w') as f:
    f.write('PROJECT=RG35XX-AWEIGIT-R1\n')
    f.write('MODULE=P1A_GRAPHICS\n')
    f.write('ARTIFACT=RG35XX-Platform-Exerciser-P1A.jar\n')
    f.write('SOURCE=tests/p1a/exerciser/RG35XXPlatformExerciserP1A.java\n')
    f.write('COMMERCIAL_GAME_CONTENT=NO\n')
    f.write('JAVA_CLASS_MAJORS=%s\n' % ','.join(str(x) for x in sorted(majors)))
    f.write('JAVA6_GATE=PASS\n')
    f.write('EXERCISER_SHA256=%s\n' % sha)
    f.write('PHYSICAL_TEST_REQUIRED=YES_ORIGINAL_RG35XX\n')
    f.write('DEVICE-PASS=NO\n')
    f.write('STABLE=NO\n')
print('P1A_EXERCISER_CLASS_MAJORS=' + ','.join(str(x) for x in sorted(majors)))
print('P1A_EXERCISER_JAVA6_GATE=PASS')
print('P1A_EXERCISER_SHA256=' + sha)
PY

echo P1A_EXERCISER_BUILD=PASS
cat "$IDENTITY"
