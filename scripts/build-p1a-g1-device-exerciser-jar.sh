#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G1_EXERCISER_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"

PLATFORM="$ROOT/out/p1a-g1-clear-copy/freej2me-rg35xx.jar"
SRC="$ROOT/tests/p1a/RG35XXP1AG1DeviceExerciserMIDlet.java"
OUT="$ROOT/out/p1a-g1-device-exerciser-jar"
BUILD="$ROOT/build/p1a-g1-device-exerciser"
[ -f "$PLATFORM" ] || fail "G1 candidate platform missing"
[ -f "$SRC" ] || fail "device exerciser source missing"

rm -rf "$OUT" "$BUILD"
mkdir -p "$OUT" "$BUILD/classes"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PLATFORM" \
  -d "$BUILD/classes" "$SRC"

cat > "$BUILD/MANIFEST.MF" <<'MF'
Manifest-Version: 1.0
MIDlet-1: RG35XX P1A G1 Exerciser,,org.recompile.rg35xx.p1a.device.RG35XXP1AG1DeviceExerciserMIDlet
MIDlet-Name: RG35XX P1A G1 Exerciser
MIDlet-Vendor: RG35XX-AWEIGIT-R1
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

JAR="$OUT/RG35XX-P1A-G1-EXERCISER.jar"
"$JAVA8/bin/jar" cfm "$JAR" "$BUILD/MANIFEST.MF" -C "$BUILD/classes" .

python3 - "$JAR" <<'PY'
import sys,zipfile
jar=sys.argv[1]
with zipfile.ZipFile(jar) as z:
    classes=[n for n in z.namelist() if n.endswith('.class')]
    if not classes:
        raise SystemExit('P1A_G1_EXERCISER_JAVA6_FAIL no classes')
    bad=[]
    for n in classes:
        b=z.read(n)
        major=int.from_bytes(b[6:8],'big')
        if major>50: bad.append((n,major))
    if bad:
        raise SystemExit('P1A_G1_EXERCISER_JAVA6_FAIL '+repr(bad))
    raw=z.read('META-INF/MANIFEST.MF').decode('utf-8','replace').replace('\r\n','\n')
    # JAR manifests fold physical lines at 72 bytes. Unfold continuation lines
    # before checking semantic MIDlet attributes so the gate validates the
    # manifest contract instead of depending on its physical line wrapping.
    logical=[]
    for line in raw.split('\n'):
        if line.startswith(' ') and logical:
            logical[-1] += line[1:]
        else:
            logical.append(line)
    mf='\n'.join(logical)
    markers=[
        'MIDlet-Name: RG35XX P1A G1 Exerciser',
        'MIDlet-1: RG35XX P1A G1 Exerciser,,org.recompile.rg35xx.p1a.device.RG35XXP1AG1DeviceExerciserMIDlet',
    ]
    for marker in markers:
        if marker not in mf:
            raise SystemExit('P1A_G1_EXERCISER_MANIFEST_FAIL '+marker)
print('P1A_G1_EXERCISER_JAVA6_GATE=PASS')
print('P1A_G1_EXERCISER_MANIFEST_GATE=PASS')
PY

SHA="$(sha256sum "$JAR" | awk '{print $1}')"
PLATFORM_SHA="$(sha256sum "$PLATFORM" | awk '{print $1}')"
cat > "$OUT/IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G1-CLEAR-COPY
ARTIFACT=PLATFORM_MODULE_EXERCISER_JAR
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
BUILD_CLASSPATH_PLATFORM_SHA256=$PLATFORM_SHA
EXERCISER_JAR_SHA256=$SHA
SCOPE=clearRect+copyArea
COMMERCIAL_GAME_DEPENDENCY=NO
JAVA_MAJOR_MAX=50
BUILD-PASS=YES
DEVICE-PASS=NO
STABLE=NO
EOF
(
  cd "$OUT"
  sha256sum RG35XX-P1A-G1-EXERCISER.jar IDENTITY.txt > SHA256SUMS.txt
  sha256sum -c SHA256SUMS.txt
)
echo P1A_G1_DEVICE_EXERCISER_JAR_BUILD=PASS
cat "$OUT/IDENTITY.txt"
