#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P6_INTEGRATION_EXERCISER_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
PLATFORM="${P6_PLATFORM:-$ROOT/out/full-port-r1/stage/freej2me-rg35xx.jar}"
SRC="$ROOT/tests/p6/RG35XXP6IntegrationExerciser.java"
RESOURCE="$ROOT/tests/p6/p6-resource.txt"
OUT="$ROOT/out/p6-integration-exerciser"
BUILD="$ROOT/build/p6-integration-exerciser"
JAROUT="$OUT/RG35XX-Platform-Exerciser-P6-Integration.jar"
[ -n "$JAVA8" ] || fail JAVA8_NOT_SET
[ -x "$JAVA8/bin/javac" ] || fail JAVAC_MISSING
[ -x "$JAVA8/bin/jar" ] || fail JAR_MISSING
[ -f "$PLATFORM" ] || fail PLATFORM_MISSING
[ -f "$SRC" ] || fail SOURCE_MISSING
[ -f "$RESOURCE" ] || fail RESOURCE_MISSING
! grep -nE 'org\.recompile\.(rg35xx|mobile)|java\.awt|RG35XXCore2D' "$SRC" || fail OWNER_BYPASS
rm -rf "$OUT" "$BUILD"
mkdir -p "$OUT" "$BUILD/classes"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$PLATFORM" \
  -d "$BUILD/classes" "$SRC"
cp "$RESOURCE" "$BUILD/classes/p6-resource.txt"
cat > "$BUILD/MANIFEST.MF" <<'EOF'
Manifest-Version: 1.0
MIDlet-Name: RG35XX P6 Integration Exerciser
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Reconstruction
MIDlet-1: RG35XX P6 Integration Exerciser,,RG35XXP6IntegrationExerciser
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
EOF
"$JAVA8/bin/jar" cfm "$JAROUT" "$BUILD/MANIFEST.MF" -C "$BUILD/classes" .
python3 - "$JAROUT" <<'PY'
import sys, zipfile
p=sys.argv[1]
with zipfile.ZipFile(p) as z:
    names=set(z.namelist())
    req={'META-INF/MANIFEST.MF','RG35XXP6IntegrationExerciser.class','RG35XXP6IntegrationExerciser$1.class','RG35XXP6IntegrationExerciser$P6Canvas.class','p6-resource.txt'}
    missing=req-names
    if missing: raise SystemExit('P6_JAR_GATE_FAIL missing='+repr(sorted(missing)))
    blob=b''.join(z.read(n) for n in names if n.endswith('.class'))
    for m in (b'P6_INTEGRATION_BOOT=PASS',b'P6_RESOURCE_LOADER=PASS',b'P6_CANVAS_SIZE=176x208 RESULT=PASS',b'P6_INTEGRATION_RESULT=PASS'):
        if m not in blob: raise SystemExit('P6_MARKER_GATE_FAIL '+repr(m))
    for forbidden in (b'org/recompile/rg35xx',b'org/recompile/mobile',b'java/awt',b'RG35XXCore2D'):
        if forbidden in blob: raise SystemExit('P6_OWNER_BYPASS '+repr(forbidden))
    majors=set()
    for n in names:
        if not n.endswith('.class'): continue
        b=z.read(n); major=int.from_bytes(b[6:8],'big'); majors.add(major)
        if major>50: raise SystemExit('P6_JAVA6_GATE_FAIL %s major=%d'%(n,major))
print('P6_INTEGRATION_JAVA6_GATE=PASS')
print('P6_INTEGRATION_PUBLIC_MIDP_ONLY=YES')
PY
SHA="$(sha256sum "$JAROUT" | awk '{print $1}')"
cat > "$OUT/P6-INTEGRATION-EXERCISER-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P6_FULL_PLATFORM_INTEGRATION
ARTIFACT=RG35XX-Platform-Exerciser-P6-Integration.jar
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
SCOPE=LIFECYCLE,RESOURCE_LOADER,LOGICAL_RESOLUTION
LOGICAL_RESOLUTION=176x208
PUBLIC_MIDP_ONLY=YES
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
P6_EXERCISER_SHA256=$SHA
PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF
echo "P6_INTEGRATION_EXERCISER_SHA256=$SHA"
echo P6_INTEGRATION_EXERCISER_BUILD=PASS
