#!/bin/sh
set +e
OUT=/mnt/mmc/RG35XX-MIYOO-M1.8-DEVICE-RESULT.txt
JLOG=/mnt/mmc/RG35XX-MIYOO-M1.8-JAMVM.log
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm; GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
JE=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GE=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
exec >"$OUT" 2>&1
echo 'RG35XX MIYOO M1.8 MOBILEPLATFORM INPUT DISPATCH'
echo 'FOR EACH CONTROL: PRESS THEN RELEASE. ORDER: UP DOWN LEFT RIGHT A B X Y START SELECT L R'
JB=$(sha256sum "$JAMVM"|awk '{print $1}'); GB=$(sha256sum "$GLIBJ"|awk '{print $1}')
echo JAMVM_SHA256_BEFORE=$JB; echo GLIBJ_SHA256_BEFORE=$GB
[ "$JB" = "$JE" ] || { echo FAIL_CLOSED=JAMVM_HASH; exit 41; }; [ "$GB" = "$GE" ] || { echo FAIL_CLOSED=GLIBJ_HASH; exit 42; }
export LD_LIBRARY_PATH="$APP:${LD_LIBRARY_PATH-}"; rm -f "$JLOG"
"$JAMVM" -Xms8m -Xmx64m -cp "$GLIBJ:$APP/m1.8-freej2me-dispatch.jar" org.recompile.mobile.M18DeviceDispatchProbe >"$JLOG" 2>&1 &
PID=$!; N=0; LIMIT=420
while kill -0 "$PID" 2>/dev/null; do sleep 1; N=$((N+1)); if [ "$N" -ge "$LIMIT" ]; then echo WATCHDOG_TIMEOUT=YES; kill -9 "$PID"; wait "$PID"; RC=124; break; fi; done
[ "$N" -lt "$LIMIT" ] && { wait "$PID"; RC=$?; }
echo JAMVM_EXIT_CODE=$RC; echo '== BOUNDED JAMVM LOG =='; tail -n 160 "$JLOG"
JA=$(sha256sum "$JAMVM"|awk '{print $1}'); GA=$(sha256sum "$GLIBJ"|awk '{print $1}')
echo JAMVM_SHA256_AFTER=$JA; echo GLIBJ_SHA256_AFTER=$GA
[ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && echo PROTECTED_HASHES_UNCHANGED=YES || echo PROTECTED_HASHES_UNCHANGED=NO
if [ "$RC" -eq 0 ] && grep -q 'M1_8_MOBILEPLATFORM_STATE_SEQUENCE=PASS' "$JLOG"; then echo M1_8_EXECUTION_RESULT=PASS; else echo M1_8_EXECUTION_RESULT=FAIL; fi
echo M1_8_CALLBACK_GATE=PENDING
echo DEVICE_PASS=NO_PENDING_ACTUAL_MIDP_CANVAS_CALLBACK_GATE
echo FULL_PLATFORM_STABLE=NO
sync; exit "$RC"
