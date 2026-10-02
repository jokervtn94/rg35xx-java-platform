#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G2D_DIAGNOSTIC_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/p1a-g2d-arc-family-diagnostic"

# Rebuild exact host-accepted G2C parent. No runtime mutation in G2D diagnostic.
bash "$ROOT/scripts/build-p1a-g2c-drawroundrect-jdk8-raster-v2.sh"
PARENT="$ROOT/out/p1a-g2c-drawroundrect-jdk8-raster"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT/P1A-G2C-IDENTITY.txt"
[ -f "$PARENT_JAR" ] || fail "G2C parent jar missing"
grep -q '^G2C_STRICT_DIFFERENTIAL=PASS$' "$PARENT_ID" || fail "G2C strict differential"
grep -q '^G2C_CANONICAL_EQUIVALENT=YES$' "$PARENT_ID" || fail "G2C canonical"
grep -q '^CANDIDATE_PLATFORM_SEMANTIC_SHA256=a177541d3d0f9a8ad5e322afae03994800f73d8b13b5b141f8343490aa3ae2dc$' "$PARENT_ID" || fail "G2C semantic drift"
grep -q '^CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=0b0d5afad448c0e1323a9f1eb66c6a05b6cd13357697f929aa6985551c5e95cb$' "$PARENT_ID" || fail "G2C PlatformGraphics drift"
echo P1A_G2D_G2C_PARENT_IDENTITY_GATE=PASS

rm -rf "$OUT" "$BUILD/p1a-g2d-diag-host"
mkdir -p "$OUT" "$BUILD/p1a-g2d-diag-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$PARENT_JAR" \
  -d "$BUILD/p1a-g2d-diag-host" "$ROOT/tests/p1a/RG35XXG2DArcFamilyDiagnostic.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$PARENT_JAR:$BUILD/p1a-g2d-diag-host" \
  org.recompile.rg35xx.p1a.RG35XXG2DArcFamilyDiagnostic \
  | tee "$OUT/P1A-G2D-ARC-FAMILY-DIAGNOSTIC.txt"
LOG="$OUT/P1A-G2D-ARC-FAMILY-DIAGNOSTIC.txt"
grep -q '^P1A_G2D_DIAGNOSTIC_FAILURE_COUNT=0$' "$LOG" || fail "diagnostic failures"
grep -q '^P1A_G2D_ARC_FAMILY_DIAGNOSTIC=PASS$' "$LOG" || fail "diagnostic marker"
grep -q '^P1A_G2D_RUNTIME_DELTA=NONE_DIAGNOSTIC_ONLY$' "$LOG" || fail "runtime delta marker"
grep -q '^P1A_G2D_RAW_GAP=DRAW_RAW_GAP EXPECTED=RAW_NPE ACTUAL=RAW_NPE ' "$LOG" || fail "drawArc gap not proven"
grep -q '^P1A_G2D_RAW_GAP=FILL_RAW_GAP EXPECTED=RAW_NPE ACTUAL=RAW_NPE ' "$LOG" || fail "fillArc gap not proven"
SIGS="$(grep -c '^P1A_G2D_SIGNATURE=' "$LOG")"
[ "$SIGS" = 37 ] || fail "signature count $SIGS"

cp "$PARENT_ID" "$OUT/PARENT-G2C-IDENTITY.txt"
cat > "$OUT/P1A-G2D-DIAGNOSTIC-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G2D-ARC-FAMILY-DIAGNOSTIC
OWNER=RG35XX_GRAPHICS_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
PARENT_G2C_SEMANTIC_SHA256=a177541d3d0f9a8ad5e322afae03994800f73d8b13b5b141f8343490aa3ae2dc
PARENT_G2C_PLATFORMGRAPHICS_CLASS_SHA256=0b0d5afad448c0e1323a9f1eb66c6a05b6cd13357697f929aa6985551c5e95cb
TARGET_METHODS=Graphics.drawArc,Graphics.fillArc
CANONICAL_PATH=JAVA2D_ARC2D_PROCESSPATH_CHARACTERIZATION_PENDING_IMPLEMENTATION
SIGNATURE_COUNT=$SIGS
DRAWARC_RAW_GAP=PROVEN_NPE
FILLARC_RAW_GAP=PROVEN_NPE
RUNTIME_DELTA=NONE
CORE2D_CHANGE=NO
GAME_SPECIFIC_CODE=NO
NO_A9_PARENT=YES
JAMVM_GLIBJ=NOT_TOUCHED
BUILD-PASS=YES
HOST-CHARACTERIZATION-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=NO_MODULE_INTEGRATION_PENDING
STABLE=NO
EOF
(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
echo P1A_G2D_DIAGNOSTIC_BUILD=PASS
cat "$OUT/P1A-G2D-DIAGNOSTIC-IDENTITY.txt"
