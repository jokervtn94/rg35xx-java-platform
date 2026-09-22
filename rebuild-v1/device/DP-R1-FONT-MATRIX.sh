#!/bin/sh
. "$(dirname "$0")/DP-R1-COMMON.sh"
OUT=/mnt/mmc/RG35XX-DP-R1-FONT-MATRIX.txt
FONTJAR=/mnt/mmc/BIOS/freej2me-lr.jar
EXPECTED_FONT=20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9
: >"$OUT"; check_protected || { echo PRECONDITION=FAIL >>"$OUT"; exit 20; }
TMP=/tmp/dp-r1-font.bin; rm -f "$TMP"
unzip -p "$FONTJAR" org/recompile/mobile/rg35xx-font.bin >"$TMP" 2>/dev/null || true
FH=$(sha256sum "$TMP" 2>/dev/null|awk '{print $1}')
echo FONT_RESOURCE_SHA256=$FH >>"$OUT"; echo FONT_RESOURCE_CLASSIFICATION=EXPERIMENTAL_NOT_GOLDEN >>"$OUT"
[ "$FH" = "$EXPECTED_FONT" ] || { echo FONT_RESOURCE_GATE=FAIL_CLOSED >>"$OUT"; exit 22; }
LD_LIBRARY_PATH="$APP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$JAMVM" -Xmx64m -cp "$GLIBJ:$PLATFORM:$FONTJAR" org.recompile.mobile.M19CanvasLifecycleLauncher "$APP/dp-r1-font-matrix.jar" >>"$OUT" 2>&1
RC=$?; echo JAMVM_EXIT_CODE=$RC >>"$OUT"
check_protected && echo PROTECTED_HASHES=PASS >>"$OUT" || echo PROTECTED_HASHES=FAIL >>"$OUT"
grep -q 'M1_14_R6_MATRIX_COUNT=36' "$OUT" && grep -q 'M1_14_R6_NORMAL_EXIT=PASS' "$OUT" && [ "$RC" -eq 0 ] && echo RUNTIME_GATE=PASS >>"$OUT" || echo RUNTIME_GATE=FAIL >>"$OUT"
echo DEVICE_PASS=NO_VISUAL_REVIEW_PENDING >>"$OUT"; echo STABLE=NO >>"$OUT"; sync
