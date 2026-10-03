#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SRC="$ROOT/miyoo-m1/m1_3c_onscreen_keymap_probe.c"
OUTDIR="$ROOT/build/p2c-input-capability-diagnostic"
GEN="$OUTDIR/p2c_input_capability_probe.c"
BIN="$OUTDIR/p2c_input_capability_probe"
CC=${CC:-arm-linux-gcc}

mkdir -p "$OUTDIR"
test -f "$SRC"

# The historical M1.3C source is original-RG35XX device-PASS for the 12-control
# onscreen raw-js0 calibration path. P2C diagnostic deliberately changes only
# the calibration inventory so L2/R2 can be measured instead of inferred.
sed \
  -e 's/static const char \*names\[]={"UP","DOWN","LEFT","RIGHT","A","B","X","Y","START","SELECT","L","R"};/static const char *names[]={"UP","DOWN","LEFT","RIGHT","A","B","X","Y","START","SELECT","LONE","LTWO","RONE","RTWO"};/' \
  -e 's/const int steps=12;/const int steps=14;/' \
  -e 's/M1\.3C/P2C/g' \
  -e 's/M1_3C_RESULT/P2C_INPUT_CAPABILITY_RESULT/g' \
  "$SRC" > "$GEN"

grep -Fq '"LONE","LTWO","RONE","RTWO"' "$GEN"
grep -Fq 'const int steps=14;' "$GEN"
grep -Fq 'P2C_INPUT_CAPABILITY_RESULT' "$GEN"
! grep -Fq 'const int steps=12;' "$GEN"

"$CC" -Os -s -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft "$GEN" -ldl -o "$BIN"

sha256sum "$SRC" "$GEN" "$BIN"
echo "P2C_DIAGNOSTIC_BUILD=PASS"
echo "P2C_DIAGNOSTIC_ONLY=YES"
echo "RUNTIME_SEMANTIC_DELTA=NONE"
