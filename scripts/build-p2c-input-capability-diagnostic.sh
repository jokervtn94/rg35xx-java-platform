#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTDIR="$ROOT/build/p2c-input-capability-diagnostic"
BASE="$OUTDIR/m1_3c_onscreen_keymap_probe.c"
GEN="$OUTDIR/p2c_input_capability_probe.c"
BIN="$OUTDIR/p2c_input_capability_probe"
CC=${CC:-arm-linux-gcc}

HIST_COMMIT=faa49f9b941db5394265d9b13413e4576ef4694f
HIST_PATH=miyoo-m1/m1_3c_onscreen_keymap_probe.c
HIST_BLOB=4e6d42f499f85db242fd0f8db09d97077c48aa33

mkdir -p "$OUTDIR"

# Materialize the exact historical M1.3C source that is original-RG35XX
# device-PASS for the 12-control onscreen raw-js0 calibration path.
# Fail closed if repository history does not resolve to the locked blob.
test "$(git -C "$ROOT" rev-parse "$HIST_COMMIT:$HIST_PATH")" = "$HIST_BLOB"
git -C "$ROOT" show "$HIST_COMMIT:$HIST_PATH" > "$BASE"
test -s "$BASE"

# P2C diagnostic deliberately changes only the calibration inventory so
# L2/R2 can be measured instead of inferred. It is not production runtime.
sed \
  -e 's/static const char \*names\[]={"UP","DOWN","LEFT","RIGHT","A","B","X","Y","START","SELECT","L","R"};/static const char *names[]={"UP","DOWN","LEFT","RIGHT","A","B","X","Y","START","SELECT","LONE","LTWO","RONE","RTWO"};/' \
  -e 's/const int steps=12;/const int steps=14;/' \
  -e 's/M1\.3C/P2C/g' \
  -e 's/M1_3C_RESULT/P2C_INPUT_CAPABILITY_RESULT/g' \
  "$BASE" > "$GEN"

grep -Fq '"LONE","LTWO","RONE","RTWO"' "$GEN"
grep -Fq 'const int steps=14;' "$GEN"
grep -Fq 'P2C_INPUT_CAPABILITY_RESULT' "$GEN"
! grep -Fq 'const int steps=12;' "$GEN"

"$CC" -Os -s -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft "$GEN" -ldl -o "$BIN"

sha256sum "$BASE" "$GEN" "$BIN"
echo "P2C_DIAGNOSTIC_SOURCE_COMMIT=$HIST_COMMIT"
echo "P2C_DIAGNOSTIC_SOURCE_BLOB=$HIST_BLOB"
echo "P2C_DIAGNOSTIC_BUILD=PASS"
echo "P2C_DIAGNOSTIC_ONLY=YES"
echo "RUNTIME_SEMANTIC_DELTA=NONE"
