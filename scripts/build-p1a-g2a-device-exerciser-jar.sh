#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G2A_EXERCISER_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"

PLATFORM="$ROOT/out/p1a-g2a-fillroundrect/freej2me-rg35xx.jar"
SRC="$ROOT/tests/p1a/RG35XXP1AG2ADeviceExerciserMIDlet.java"
OUT="$ROOT/out/p1a-g2a-device-exerciser-jar"
BUILD="$ROOT/build/p1a-g2a-device-exerciser"
[ -f "$PLATFORM" ] || fail "G2A candidate platform missing"
[ -f "$SRC" ] || fail "device exerciser source missing"

rm -rf "$OUT" "$BUILD"
mkdir -p "$OUT" "$BUILD/classes"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PLATFORM" \
  -d "$BUILD/classes" "$SRC"

cat > "$BUILD/MANIFEST.MF" <<'MF'
Manifest-Version: 1.0
MIDlet-1: RG35XX P1A G2A Exerciser,,org.recompile.rg35xx.p1a.device.RG35XXP1AG2ADeviceExerciserMIDlet
MIDlet-Name: RG35XX P1A G2A Exerciser
MIDlet-Vendor: RG35XX-AWEIGIT-R1
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

JAR="$OUT/RG35XX-P1A-G2A-EXERCISER.jar"
"$JAVA8/bin/jar" cfm "$JAR" "$BUILD/MANIFEST.MF" -C "$BUILD/classes" .

python3 - "$JAR" <<'PY'
import sys,zipfile
jar=sys.argv[1]
with zipfile.ZipFile(jar) as z:
    classes=[n for n in z.namelist() if n.endswith('.class')]
    if not classes:
        raise SystemExit('P1A_G2A_EXERCISER_JAVA6_FAIL no classes')
    bad=[]
    for n in classes:
        b=z.read(n); major=int.from_bytes(b[6:8],'big')
        if major>50: bad.append((n,major))
    if bad:
        raise SystemExit('P1A_G2A_EXERCISER_JAVA6_FAIL '+repr(bad))
    raw=z.read('META-INF/MANIFEST.MF').decode('utf-8','replace').replace('\r\n','\n')
    lines=[]
    for line in raw.split('\n'):
        if line.startswith(' ') and lines: lines[-1]+=line[1:]
        else: lines.append(line)
    mf='\n'.join(lines)
    for marker in ['MIDlet-Name: RG35XX P1A G2A Exerciser','org.recompile.rg35xx.p1a.device.RG35XXP1AG2ADeviceExerciserMIDlet']:
        if marker not in mf:
            raise SystemExit('P1A_G2A_EXERCISER_MANIFEST_FAIL '+marker)
print('P1A_G2A_EXERCISER_JAVA6_GATE=PASS')
print('P1A_G2A_EXERCISER_MANIFEST_GATE=PASS')
PY

SHA="$(sha256sum "$JAR" | awk '{print $1}')"
PLATFORM_SHA="$(sha256sum "$PLATFORM" | awk '{print $1}')"
cat > "$OUT/IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G2A-FILLROUNDRECT
ARTIFACT=PLATFORM_MODULE_EXERCISER_JAR
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
BUILD_CLASSPATH_PLATFORM_SHA256=$PLATFORM_SHA
EXERCISER_JAR_SHA256=$SHA
SCOPE=fillRoundRect+G1_SENTINELS
COMMERCIAL_GAME_DEPENDENCY=NO
JAVA_MAJOR_MAX=50
EXPECTED_PHYSICAL_PASS_PATTERN=GREEN_BACKGROUND_4_WHITE_BARS
BUILD-PASS=YES
DEVICE-PASS=NO
STABLE=NO
EOF
(
  cd "$OUT"
  sha256sum RG35XX-P1A-G2A-EXERCISER.jar IDENTITY.txt > SHA256SUMS.txt
)
echo P1A_G2A_DEVICE_EXERCISER_JAR_BUILD=PASS
cat "$OUT/IDENTITY.txt"
