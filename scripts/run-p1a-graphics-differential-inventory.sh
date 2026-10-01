#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail(){ echo "P1A_DIFFERENTIAL_RUN_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"

# Reconstruct the accepted graphics parent only. This is a diagnostic inventory;
# it does not stage any P1A implementation and does not modify canonical source.
bash "$ROOT/scripts/build-a6-corpus3-cliptranslate-fix.sh"

PARENT="$ROOT/out/a6-corpus3-cliptranslate-fix"
JAR="$PARENT/freej2me-rg35xx.jar"
[ -f "$JAR" ] || fail "graphics parent jar missing"

# PlatformGraphics is unchanged by A7/A8 media/package consolidation. Lock the
# exact decompressed class identity produced by the accepted reconstruction.
PG_SHA="$(python3 - "$JAR" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"
PI_SHA="$(python3 - "$JAR" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    print(hashlib.sha256(z.read('org/recompile/mobile/PlatformImage.class')).hexdigest())
PY
)"

echo "P1A_PARENT_JAR=$JAR"
echo "P1A_PARENT_PLATFORMGRAPHICS_CLASS_SHA256=$PG_SHA"
echo "P1A_PARENT_PLATFORMIMAGE_CLASS_SHA256=$PI_SHA"
echo "P1A_RUNTIME_PATCH_STAGED=NO"

HOST="$ROOT/build/p1a-differential-inventory"
OUT="$ROOT/out/p1a-differential-inventory"
rm -rf "$HOST" "$OUT"
mkdir -p "$HOST" "$OUT"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$JAR" \
  -d "$HOST" "$ROOT/tests/p1a/RG35XXGraphicsDifferentialInventory.java"

"$JAVA8/bin/java" -Djava.awt.headless=true \
  -cp "$JAR:$HOST" org.recompile.rg35xx.p1a.RG35XXGraphicsDifferentialInventory \
  | tee "$OUT/P1A-DIFFERENTIAL-INVENTORY.txt"

grep -q '^P1A_DIFFERENTIAL_INVENTORY=PASS$' "$OUT/P1A-DIFFERENTIAL-INVENTORY.txt" \
  || fail "inventory marker missing"
grep -q '^P1A_RUNTIME_CHANGE=NO$' "$OUT/P1A-DIFFERENTIAL-INVENTORY.txt" \
  || fail "runtime-change marker missing"

cat > "$OUT/P1A-DIFFERENTIAL-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-CORE-2D-SOURCE-COVERAGE
MODE=DIAGNOSTIC_INVENTORY_ONLY
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
EXACT_A8_GOLDEN_PLATFORM_SHA256=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
PARENT_PLATFORMGRAPHICS_CLASS_SHA256=$PG_SHA
PARENT_PLATFORMIMAGE_CLASS_SHA256=$PI_SHA
GAME_SPECIFIC_CODE=NO
RUNTIME_CHANGE=NO
BUILD_PASS=DIAGNOSTIC_ONLY
DEVICE_PASS=NO
STABLE=NO
EOF

(cd "$OUT" && sha256sum * > SHA256SUMS.txt)
echo 'P1A_DIFFERENTIAL_RUN=PASS'
