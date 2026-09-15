#!/bin/sh
set +e
OUT=/mnt/mmc/RG35XX-MIYOO-M1.8-DEVICE-RESULT.txt
JLOG=/mnt/mmc/RG35XX-MIYOO-M1.8-JAMVM.log
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
JE=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GE=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
exec >"$OUT" 2>&1

echo 'RG35XX MIYOO M1.8 MIDP DEVICE ACCEPTANCE'
echo 'SCOPE=M1.8_DETERMINISTIC_ADAPTER_TO_MOBILEPLATFORM_BUILD_ACCEPTANCE'
echo 'NOTE=This runner validates JamVM compatibility and deterministic M1InputDispatch to canonical MobilePlatform only; physical js0 and real Canvas callbacks require the next device harness.'

JB=$(sha256sum "$JAMVM" 2>/dev/null|awk '{print $1}')
GB=$(sha256sum "$GLIBJ" 2>/dev/null|awk '{print $1}')
echo JAMVM_SHA256_BEFORE=$JB
echo GLIBJ_SHA256_BEFORE=$GB
[ "$JB" = "$JE" ] || { echo FAIL_CLOSED=JAMVM_HASH; exit 41; }
[ "$GB" = "$GE" ] || { echo FAIL_CLOSED=GLIBJ_HASH; exit 42; }

JAR="$APP/m1.8-midp-acceptance.jar"
LIB="$APP/libm1_8_input.so"
[ -f "$JAR" ] || { echo FAIL_CLOSED=MISSING_ACCEPTANCE_JAR; exit 43; }
[ -f "$LIB" ] || { echo FAIL_CLOSED=MISSING_M1_8_NATIVE; exit 44; }
echo ACCEPTANCE_JAR_SHA256=$(sha256sum "$JAR"|awk '{print $1}')
echo M1_8_NATIVE_SHA256=$(sha256sum "$LIB"|awk '{print $1}')

rm -f "$JLOG"
export LD_LIBRARY_PATH="$APP:${LD_LIBRARY_PATH-}"
"$JAMVM" -Xmx64m -cp "$GLIBJ:$JAR" org.recompile.mobile.M18DispatchAcceptance >"$JLOG" 2>&1 &
PID=$!; N=0; LIMIT=180
while kill -0 "$PID" 2>/dev/null; do
  sleep 1; N=$((N+1))
  if [ "$N" -ge "$LIMIT" ]; then
    echo WATCHDOG_TIMEOUT=YES
    kill -9 "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null
    RC=124
    break
  fi
done
[ "$N" -lt "$LIMIT" ] && { wait "$PID"; RC=$?; }

echo JAMVM_EXIT_CODE=$RC
echo '== BOUNDED JAMVM LOG =='
tail -n 160 "$JLOG"
JA=$(sha256sum "$JAMVM" 2>/dev/null|awk '{print $1}')
GA=$(sha256sum "$GLIBJ" 2>/dev/null|awk '{print $1}')
echo JAMVM_SHA256_AFTER=$JA
echo GLIBJ_SHA256_AFTER=$GA
[ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && echo PROTECTED_HASHES_UNCHANGED=YES || echo PROTECTED_HASHES_UNCHANGED=NO

if [ "$RC" -eq 0 ] && grep -q 'M1_8_MIDP_ACCEPTANCE_MARKER=PASS' "$JLOG"; then
  echo M1_8_EXECUTION_RESULT=PASS
else
  echo M1_8_EXECUTION_RESULT=FAIL
fi
echo DEVICE_PASS=NO_DETERMINISTIC_ACCEPTANCE_ONLY
echo PHYSICAL_JS0_CANVAS_TEST_PENDING=YES
echo FULL_PLATFORM_STABLE=NO
sync
exit "$RC"
