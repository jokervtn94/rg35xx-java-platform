#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_COPYAREA_DIAG_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"

# Build until the known G1 overlap differential failure. The candidate JAR is
# already materialized before that gate, so this diagnostic can characterize
# its output without weakening the normal G1 workflow.
set +e
bash "$ROOT/scripts/build-p1a-g1-clear-copy.sh"
RC=$?
set -e
[ "$RC" -ne 0 ] || fail "G1 unexpectedly passed before overlap characterization"

JAR="$ROOT/out/p1a-g1-clear-copy/freej2me-rg35xx.jar"
[ -f "$JAR" ] || fail "candidate jar missing after expected G1 differential failure"

HOST="$ROOT/build/p1a-copyarea-overlap-diag"
OUT="$ROOT/out/p1a-copyarea-overlap-diagnostic"
rm -rf "$HOST" "$OUT"
mkdir -p "$HOST" "$OUT"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$JAR" \
  -d "$HOST" "$ROOT/tests/p1a/RG35XXCopyAreaOverlapDiagnostic.java"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$JAR:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXCopyAreaOverlapDiagnostic \
  | tee "$OUT/P1A-COPYAREA-OVERLAP-DIAGNOSTIC.txt"

grep -q '^P1A_COPYAREA_OVERLAP_DIAGNOSTIC=COMPLETE$' "$OUT/P1A-COPYAREA-OVERLAP-DIAGNOSTIC.txt" \
  || fail "completion marker missing"
grep -q '^P1A_COPYAREA_OVERLAP_RUNTIME_CHANGE=NO$' "$OUT/P1A-COPYAREA-OVERLAP-DIAGNOSTIC.txt" \
  || fail "runtime-change marker missing"

cat > "$OUT/IDENTITY.txt" <<'EOF'
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G1-COPYAREA-OVERLAP-DIAGNOSTIC
MODE=DIAGNOSTIC_ONLY
OWNER=RG35XX_GRAPHICS_BOUNDARY
RUNTIME_CHANGE=NO_NEW_CHANGE
EXPECTED_PARENT_G1_STATUS=ONE_FORWARD_OVERLAP_MISMATCH
DEVICE_PASS=NO
STABLE=NO
EOF

(cd "$OUT" && sha256sum * > SHA256SUMS.txt)
echo P1A_COPYAREA_OVERLAP_DIAGNOSTIC_RUN=PASS
