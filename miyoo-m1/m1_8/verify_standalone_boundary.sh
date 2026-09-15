#!/bin/sh
set -eu

M17="miyoo-m1/m1_7_input_jni.c"
DISPATCH="miyoo-m1/m1_8/M1InputDispatch.java"
JNI="miyoo-m1/m1_8/m1_8_input_jni.c"

[ -f "$M17" ] && [ -f "$DISPATCH" ] && [ -f "$JNI" ]

EXPECTED_M17="34e0e19297a3c7e32520e0684ce7031f361fc8bcbf585093149dc8db7f39d603"
ACTUAL_M17=$(sha256sum "$M17" | awk '{print $1}')
[ "$ACTUAL_M17" = "$EXPECTED_M17" ] || { echo "FAIL: M1.7 changed: $ACTUAL_M17"; exit 1; }

[ "$(grep -c 'M1Input.rawGetState()' "$DISPATCH")" -eq 1 ]
[ "$(grep -c 'MobilePlatform.keyPressed(key)' "$DISPATCH")" -eq 1 ]
[ "$(grep -c 'MobilePlatform.keyReleased(key)' "$DISPATCH")" -eq 1 ]
[ "$(grep -c 'MobilePlatform.keyRepeated(key)' "$DISPATCH")" -eq 1 ]
grep -q 'REPEAT_DELAY_MS = 400' "$DISPATCH"
grep -q 'REPEAT_PERIOD_MS = 100' "$DISPATCH"

[ "$(grep -c 'open(\"/dev/input/js0\"' "$JNI")" -eq 1 ]
! grep -q 'printf\|fprintf\|syslog' "$JNI"

# Standalone boundary: this checkpoint must not add or modify Libretro integration.
! grep -q 'Libretro' miyoo-m1/m1_8/M1Input.java
! grep -q 'Libretro' "$DISPATCH"
! grep -q 'Libretro' "$JNI"

echo "M1.8_STANDALONE_BOUNDARY=PASS"
echo "M1.7_SHA256=$ACTUAL_M17"
echo "DEVICE_PASS=NO"
echo "DEVICE_TEST_PENDING=YES"
