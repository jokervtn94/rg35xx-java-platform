#!/bin/sh
# M1.5 isolated Java boot test for original RG35XX. Does not overwrite platform files.
set +e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="/mnt/mmc/RG35XX-MIYOO-M1.5-DEVICE-RESULT.txt"
LOG="/mnt/mmc/RG35XX-MIYOO-M1.5-JAMVM.log"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECT_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECT_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
exec >"$OUT" 2>&1

echo "RG35XX MIYOO M1.5 MINIMAL JAVA DEVICE BOOT"
date
echo "PRIMARY_VARIABLE=LAUNCH_M1_4A_8_JAVA5_2D_NO_AUDIO_SLICE_ON_DEVICE_PROVEN_JAMVM_L_GLIBJ"
echo "ISOLATED_TEST=YES"
echo "TEST_ROOT=$ROOT"

hashf() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
fail() { echo "M1_5_DEVICE_RESULT=FAIL_CLOSED"; echo "FAIL_REASON=$1"; sync; exit 1; }
[ -x "$JAMVM" ] || fail JAMVM_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_MISSING
[ -f "$ROOT/m1.5-java5-slice.jar" ] || fail SLICE_JAR_MISSING
[ -f "$ROOT/m1.5-boot-probe.jar" ] || fail PROBE_JAR_MISSING
command -v sha256sum >/dev/null 2>&1 || fail SHA256SUM_MISSING

JB=$(hashf "$JAMVM"); GB=$(hashf "$GLIBJ")
echo "JAMVM_SHA256_BEFORE=$JB"
echo "GLIBJ_SHA256_BEFORE=$GB"
[ "$JB" = "$EXPECT_JAMVM" ] || fail JAMVM_HASH_MISMATCH
[ "$GB" = "$EXPECT_GLIBJ" ] || fail GLIBJ_HASH_MISMATCH

echo "== JVM VERSION =="
"$JAMVM" -version 2>&1 | head -n 12
echo "== MEMORY BEFORE =="
head -n 12 /proc/meminfo 2>/dev/null
rm -f "$LOG"
CP="$ROOT/m1.5-boot-probe.jar:$ROOT/m1.5-java5-slice.jar:$GLIBJ"
echo "M1_5_LAUNCH_BEGIN=YES"
"$JAMVM" -Xms8m -Xmx64m -cp "$CP" M15BootProbe >"$LOG" 2>&1 &
PID=$!
T=0
while kill -0 "$PID" 2>/dev/null; do
  T=$((T+1))
  if [ "$T" -ge 20 ]; then
    echo "WATCHDOG_TIMEOUT=YES"
    kill "$PID" 2>/dev/null
    sleep 1
    kill -9 "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null
    cat "$LOG"
    fail JAVA_BOOT_TIMEOUT
  fi
  sleep 1
done
wait "$PID"; RC=$?
echo "JAMVM_EXIT_CODE=$RC"
echo "== BOUNDED JAMVM LOG =="
sed -n '1,240p' "$LOG"
JA=$(hashf "$JAMVM"); GA=$(hashf "$GLIBJ")
echo "JAMVM_SHA256_AFTER=$JA"
echo "GLIBJ_SHA256_AFTER=$GA"
[ "$JA" = "$JB" ] || fail JAMVM_HASH_CHANGED
[ "$GA" = "$GB" ] || fail GLIBJ_HASH_CHANGED
[ "$RC" -eq 0 ] || fail JAMVM_NONZERO_EXIT
grep -q '^M1_5_BOOT_MARKER=PASS$' "$LOG" || fail BOOT_MARKER_MISSING
grep -q '^M1_5_LINKAGE_MARKER=PASS$' "$LOG" || fail LINKAGE_MARKER_MISSING
if grep -E 'VerifyError|UnsupportedClassVersionError|NoClassDefFoundError' "$LOG" >/dev/null; then fail BOOT_LINKAGE_ERROR; fi
echo "PROTECTED_HASHES_UNCHANGED=YES"
echo "M1_5_DEVICE_RESULT=PASS"
echo "DEVICE_PASS_SCOPE=M1.5_JAVA_BOOT_SLICE_ONLY"
echo "FULL_PLATFORM_STABLE=NO"
sync
exit 0
