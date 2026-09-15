#!/bin/sh
set +e
OUT="/mnt/mmc/RG35XX-MIYOO-M1.6-DEVICE-RESULT.txt"
JLOG="/mnt/mmc/RG35XX-MIYOO-M1.6-JAMVM.log"
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
JAMVM_EXPECT=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_EXPECT=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
exec >"$OUT" 2>&1

echo "RG35XX MIYOO M1.6 JAVA SDL1 FBCON DISPLAY"
date
echo "PRIMARY_VARIABLE=CONNECT_M1_5_JAVA_BOOT_PATH_TO_DEVICE_PROVEN_SDL1_FBCON_DISPLAY_ONLY"
echo "APP=$APP"
JB=$(sha256sum "$JAMVM" 2>/dev/null | awk '{print $1}')
GB=$(sha256sum "$GLIBJ" 2>/dev/null | awk '{print $1}')
echo "JAMVM_SHA256_BEFORE=$JB"
echo "GLIBJ_SHA256_BEFORE=$GB"
[ "$JB" = "$JAMVM_EXPECT" ] || { echo "FAIL_CLOSED=JAMVM_HASH"; exit 41; }
[ "$GB" = "$GLIBJ_EXPECT" ] || { echo "FAIL_CLOSED=GLIBJ_HASH"; exit 42; }

rm -f "$JLOG"
export LD_LIBRARY_PATH="$APP:${LD_LIBRARY_PATH-}"
export SDL_VIDEODRIVER=fbcon
"$JAMVM" -Xmx64m -cp "$GLIBJ:$APP/m1.6-display-probe.jar" M16DisplayProbe >"$JLOG" 2>&1 &
PID=$!
N=0
WATCHDOG_TIMEOUT=20
while kill -0 "$PID" 2>/dev/null; do
  sleep 1; N=$((N+1))
  if [ "$N" -ge "$WATCHDOG_TIMEOUT" ]; then
    echo "WATCHDOG_TIMEOUT=YES"
    kill -9 "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null
    RC=124
    break
  fi
done
[ "$N" -lt "$WATCHDOG_TIMEOUT" ] && { wait "$PID"; RC=$?; }
echo "JAMVM_EXIT_CODE=$RC"
echo "== BOUNDED JAMVM LOG =="
tail -n 100 "$JLOG" 2>&1
JA=$(sha256sum "$JAMVM" 2>/dev/null | awk '{print $1}')
GA=$(sha256sum "$GLIBJ" 2>/dev/null | awk '{print $1}')
echo "JAMVM_SHA256_AFTER=$JA"
echo "GLIBJ_SHA256_AFTER=$GA"
[ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && echo "PROTECTED_HASHES_UNCHANGED=YES" || echo "PROTECTED_HASHES_UNCHANGED=NO"
if [ "$RC" -eq 0 ] && grep -q 'M1_6_JAVA_MARKER=PASS' "$JLOG" && grep -q 'M1_6_NATIVE_INIT_RC=0' "$JLOG" && grep -q 'M1_6_DISPLAY_SEQUENCE_MARKER=PASS' "$JLOG"; then
  echo "M1_6_EXECUTION_RESULT=PASS"
  echo "VISUAL_CONFIRMATION_REQUIRED=YES"
else
  echo "M1_6_EXECUTION_RESULT=FAIL"
  echo "VISUAL_CONFIRMATION_REQUIRED=NO"
fi
echo "DEVICE_PASS=NO_PENDING_VISUAL_CONFIRMATION"
echo "FULL_PLATFORM_STABLE=NO"
sync
exit "$RC"
