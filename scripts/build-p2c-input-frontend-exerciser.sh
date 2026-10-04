#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2C_EXERCISER_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac jar; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

OUT="$ROOT/out/p2c-input-frontend-candidate-r1"
PLATFORM="$OUT/freej2me-rg35xx.jar"
SRC="$ROOT/tests/p2c/exerciser/RG35XXP2CInputFrontendExerciser.java"
BUILD="$ROOT/build/p2c-input-frontend-exerciser"
JAROUT="$OUT/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar"
IDENTITY="$OUT/P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt"
DIGEST="$ROOT/scripts/p2c-semantic-jar-digest.py"
EXPECTED_PLATFORM_SEMANTIC="${EXPECTED_PLATFORM_SEMANTIC:-0a4f197bdbf39b7102c69bb2e560c6e469c32c20ae58c8fb688fadbcecf1c6c6}"

[ -f "$PLATFORM" ] || fail "P2C candidate platform jar missing"
[ -f "$SRC" ] || fail "exerciser source missing"
[ -f "$DIGEST" ] || fail "semantic digest helper missing"
[ "$(python3 "$DIGEST" "$PLATFORM")" = "$EXPECTED_PLATFORM_SEMANTIC" ] || fail "candidate platform semantic identity"
echo P2C_EXERCISER_PLATFORM_SEMANTIC_GATE=PASS

# The device exerciser must terminate at public MIDP callbacks. No RG35XX or
# org.recompile.mobile implementation class may be imported or referenced.
! grep -nE 'org\.recompile\.(rg35xx|mobile)|java\.awt|RG35XXCore2D' "$SRC" || fail "owner bypass in source"
grep -q 'javax.microedition.lcdui.Canvas' "$SRC" || fail "Canvas public API missing"
grep -q 'pointerPressed' "$SRC" || fail "public pointer callback missing"
grep -q 'keyPressed' "$SRC" || fail "public key callback missing"
grep -q 'LOGICAL_W = 176' "$SRC" || fail "non-240 launch width missing"
grep -q 'LOGICAL_H = 208' "$SRC" || fail "non-240 launch height missing"

rm -rf "$BUILD"
mkdir -p "$BUILD/classes"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$PLATFORM" \
  -d "$BUILD/classes" "$SRC"

cat > "$BUILD/MANIFEST.MF" <<'EOF_MANIFEST'
Manifest-Version: 1.0
MIDlet-Name: RG35XX P2C Input Frontend Exerciser
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Reconstruction
MIDlet-1: RG35XX P2C Input Frontend Exerciser,,RG35XXP2CInputFrontendExerciser
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
EOF_MANIFEST

rm -f "$JAROUT"
"$JAVA8/bin/jar" cfm "$JAROUT" "$BUILD/MANIFEST.MF" -C "$BUILD/classes" .

python3 - "$JAROUT" <<'PY'
import sys,zipfile
jar=sys.argv[1]
with zipfile.ZipFile(jar) as z:
    names=set(z.namelist())
    required={
        'META-INF/MANIFEST.MF',
        'RG35XXP2CInputFrontendExerciser.class',
        'RG35XXP2CInputFrontendExerciser$P2CCanvas.class',
    }
    missing=required-names
    if missing: raise SystemExit('P2C_EXERCISER_JAR_GATE_FAIL missing='+repr(sorted(missing)))
    classes=sorted(n for n in names if n.endswith('.class'))
    if classes!=['RG35XXP2CInputFrontendExerciser$P2CCanvas.class','RG35XXP2CInputFrontendExerciser.class']:
        raise SystemExit('P2C_EXERCISER_JAR_GATE_FAIL classes='+repr(classes))
    blob=b''.join(z.read(n) for n in classes)
    for marker in (
        b'P2C_EXERCISER_BOOT=PASS',
        b'P2C_EXERCISER_RESOLUTION=',
        b'P2C_EXERCISER_STEP=',
        b'P2C_EXERCISER_POINTER_PRESS=6,6 RESULT=PASS',
        b'P2C_EXERCISER_RESULT=PASS PHASE=',
        b'P2C_EXERCISER_EXIT_REQUEST=PASS PHASE=',
    ):
        if marker not in blob: raise SystemExit('P2C_EXERCISER_MARKER_GATE_FAIL '+repr(marker))
    for forbidden in (b'org/recompile/rg35xx',b'org/recompile/mobile',b'java/awt',b'RG35XXCore2D'):
        if forbidden in blob: raise SystemExit('P2C_EXERCISER_OWNER_BYPASS_FORBIDDEN '+repr(forbidden))
    majors=set()
    for n in classes:
        b=z.read(n)
        if b[:4]!=b'\xca\xfe\xba\xbe': raise SystemExit('bad class magic '+n)
        major=int.from_bytes(b[6:8],'big'); majors.add(major)
        if major>50: raise SystemExit('P2C_EXERCISER_JAVA6_FAIL %s major=%d'%(n,major))
print('P2C_EXERCISER_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('P2C_EXERCISER_JAVA6_GATE=PASS')
print('P2C_EXERCISER_PUBLIC_MIDP_ONLY=YES')
print('P2C_EXERCISER_DIRECT_BACKEND_CALL=NO')
PY

EX_SHA="$(sha256sum "$JAROUT" | awk '{print $1}')"
cat > "$IDENTITY" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2C_INPUT_FRONTEND
ARTIFACT=RG35XX-Platform-Exerciser-P2C-InputFrontend.jar
SOURCE=tests/p2c/exerciser/RG35XXP2CInputFrontendExerciser.java
LOGICAL_RESOLUTION=176x208
PHASE_COUNT=3
PHASE1=DEFAULT_14_CONTROLS+PHONE_MODE_CYCLE+PERSIST_N
PHASE2=PERSISTENCE+CUSTOM_KEYMAP+POINTER+ROTATION
PHASE3=INVALID_KEYMAP_FAILSAFE
DEFAULT_PHYSICAL_CONTROL_COUNT=14
PHONE_MODE_SET=p,n,e,s,m
PHONE_MODE_PERSISTENCE=REQUIRED
CUSTOM_KEYMAP_VALID=REQUIRED
INVALID_KEYMAP_FALLBACK=REQUIRED
POINTER_EXPECTED_COORDINATE=6,6
ROTATION_SEQUENCE=0,1,2,0
PUBLIC_MIDP_CANVAS_KEY_API=YES
PUBLIC_MIDP_POINTER_API=YES
DIRECT_RG35XX_BACKEND_CALL=NO
COMMERCIAL_GAME_CONTENT=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
EXERCISER_SHA256=$EX_SHA
P2C_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_ID

echo "P2C_EXERCISER_SHA256=$EX_SHA"
echo P2C_EXERCISER_BUILD=PASS
echo P2C_EXERCISER_JAVA6_GATE=PASS
echo P2C_EXERCISER_PUBLIC_MIDP_ONLY=YES
echo P2C_EXERCISER_DIRECT_BACKEND_CALL=NO
echo RUNTIME_SEMANTIC_DELTA=NONE
cat "$IDENTITY"
