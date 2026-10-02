#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G2_DIAG_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"

# Materialize the exact host-passing G1 candidate. No G2 runtime code is staged.
bash "$ROOT/scripts/build-p1a-g1-clear-copy.sh"

G1="$ROOT/out/p1a-g1-clear-copy"
JAR="$G1/freej2me-rg35xx.jar"
G1ID="$G1/P1A-G1-IDENTITY.txt"
[ -f "$JAR" ] || fail "G1 candidate jar missing"
[ -f "$G1ID" ] || fail "G1 identity missing"
grep -q '^P1A_G1_ALPHA_DIFFERENTIAL_GATE=PASS$' "$G1ID" || fail "G1 alpha gate not locked"
grep -q '^HOST-DIFFERENTIAL-PASS=YES$' "$G1ID" || fail "G1 host differential not locked"
grep -q '^DEVICE-PASS=NO$' "$G1ID" || fail "G1 device status unexpectedly promoted"

OUT="$ROOT/out/p1a-g2-midp-shapes-diagnostic"
HOST="$ROOT/build/p1a-g2-midp-shapes-diagnostic"
rm -rf "$OUT" "$HOST"
mkdir -p "$OUT" "$HOST"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$JAR" \
  -d "$HOST" "$ROOT/tests/p1a/RG35XXG2MidpShapesDiagnostic.java"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$JAR:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2MidpShapesDiagnostic \
  | tee "$OUT/P1A-G2-MIDP-SHAPES-DIAGNOSTIC.txt"

grep -q '^P1A_G2_MIDP_SHAPES_DIAGNOSTIC=PASS$' "$OUT/P1A-G2-MIDP-SHAPES-DIAGNOSTIC.txt" || fail "diagnostic marker missing"
grep -q '^P1A_G2_RUNTIME_CHANGE=NO$' "$OUT/P1A-G2-MIDP-SHAPES-DIAGNOSTIC.txt" || fail "runtime-change marker missing"
grep -q '^P1A_G2_FILLROUNDRECT_EQUALS_FILLRECT=true$' "$OUT/P1A-G2-MIDP-SHAPES-DIAGNOSTIC.txt" || fail "fillRoundRect canonical quirk drift"

for c in \
  DRAWARC_PARTIAL DRAWARC_FULL DRAWARC_NEGATIVE \
  FILLARC_PARTIAL FILLARC_FULL FILLARC_NEGATIVE \
  DRAWROUNDRECT_NORMAL DRAWROUNDRECT_OVERSIZE DRAWROUNDRECT_ZERO_ARC \
  FILLROUNDRECT_NORMAL FILLROUNDRECT_OVERSIZE \
  FILLTRIANGLE_NORMAL FILLTRIANGLE_REVERSED FILLTRIANGLE_FLAT; do
  grep -q "^P1A_G2_CASE=${c} EXPECTED=RAW_EXCEPTION ACTUAL=RAW_EXCEPTION AWT=NONE RAW=java.lang.NullPointerException$" \
    "$OUT/P1A-G2-MIDP-SHAPES-DIAGNOSTIC.txt" || fail "pre-G2 classification drift $c"
done

G1_SEM="$(grep '^CANDIDATE_PLATFORM_SEMANTIC_SHA256=' "$G1ID" | cut -d= -f2)"
G1_PG="$(grep '^CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=' "$G1ID" | cut -d= -f2)"
cat > "$OUT/IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G2-MIDP-SHAPES-DIAGNOSTIC
OWNER=RG35XX_GRAPHICS_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G1_SEMANTIC_SHA256=$G1_SEM
PARENT_G1_PLATFORMGRAPHICS_CLASS_SHA256=$G1_PG
G2_METHODS=drawArc,fillArc,drawRoundRect,fillRoundRect,fillTriangle
RUNTIME_CHANGE=NO
RAW_PRE_G2_CLASSIFICATION=RAW_EXCEPTION_NPE_ALL_G2_METHODS
FILLROUNDRECT_CANONICAL_QUIRK=FINAL_FULL_FILLRECT
CANONICAL_RASTER_CAPTURE=JDK8_MASK_CHECKSUM_COUNT_BOUNDS
BUILD-PASS=YES_DIAGNOSTIC_ONLY
DEVICE-PASS=NO
STABLE=NO
EOF

cp "$G1ID" "$OUT/PARENT-G1-IDENTITY.txt"
(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
echo P1A_G2_MIDP_SHAPES_DIAGNOSTIC_RUN=PASS
cat "$OUT/IDENTITY.txt"
