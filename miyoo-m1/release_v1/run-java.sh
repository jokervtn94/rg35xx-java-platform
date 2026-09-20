#!/bin/sh
# RG35XX-JAVA-INSTALLABLE-BASELINE-V1
BASE=/mnt/mmc/Roms/APPS/RG35XX-JAVA-BASELINE
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
GAME="$1"
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

[ -n "$GAME" ] && [ -f "$GAME" ] || exit 20
[ -f "$BASE/freej2me-platform.jar" ] || exit 21
[ -f "$BASE/font-resource.jar" ] || exit 22
[ -f "$BASE/libm1_8_input.so" ] || exit 23
[ -f "$BASE/libm1_9e_presenter.so" ] || exit 24

JB=$(sha256sum "$JAMVM" 2>/dev/null | awk '{print $1}')
GB=$(sha256sum "$GLIBJ" 2>/dev/null | awk '{print $1}')
[ "$JB" = "$EXPECTED_JAMVM" ] || exit 25
[ "$GB" = "$EXPECTED_GLIBJ" ] || exit 26

SAFE=$(basename "$GAME" .jar | tr ' /:\\' '____' | tr -cd 'A-Za-z0-9._-')
STAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo run)
LOG="/mnt/mmc/RG35XX-JAVA-BASELINE-${SAFE}-${STAMP}.log"
LAST=/mnt/mmc/RG35XX-JAVA-BASELINE-LAST.log

{
  echo "RG35XX JAVA INSTALLABLE BASELINE V1"
  echo "GAME=$GAME"
  echo "JAMVM_SHA256_BEFORE=$JB"
  echo "GLIBJ_SHA256_BEFORE=$GB"
  echo "PLATFORM_SHA256=$(sha256sum "$BASE/freej2me-platform.jar" | awk '{print $1}')"
  echo "INPUT_SHA256=$(sha256sum "$BASE/libm1_8_input.so" | awk '{print $1}')"
  echo "PRESENTER_SHA256=$(sha256sum "$BASE/libm1_9e_presenter.so" | awk '{print $1}')"
  echo "FONT_CLASSIFICATION=EXPERIMENTAL_NOT_GOLDEN"
  echo "FULL_PLATFORM_STABLE=NO"
} >"$LOG"

LD_LIBRARY_PATH="$BASE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
"$JAMVM" -Xmx64m \
-cp "$GLIBJ:$BASE/freej2me-platform.jar:$BASE/font-resource.jar" \
org.recompile.mobile.M1InstallableBaselineLauncher "$GAME" >>"$LOG" 2>&1
RC=$?

JA=$(sha256sum "$JAMVM" 2>/dev/null | awk '{print $1}')
GA=$(sha256sum "$GLIBJ" 2>/dev/null | awk '{print $1}')
{
  echo "JAMVM_EXIT_CODE=$RC"
  echo "JAMVM_SHA256_AFTER=$JA"
  echo "GLIBJ_SHA256_AFTER=$GA"
  if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ]; then
    echo "PROTECTED_HASHES=PASS"
  else
    echo "PROTECTED_HASHES=FAIL"
  fi
  echo "DEVICE_PASS=NO_GAME_REVIEW_PENDING"
  echo "FULL_PLATFORM_STABLE=NO"
} >>"$LOG"
cp "$LOG" "$LAST" 2>/dev/null || true
sync
exit "$RC"
