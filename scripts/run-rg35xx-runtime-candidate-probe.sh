#!/bin/sh
set -u

APP=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
PKG="$APP/RG35XX-RUNTIME-CANDIDATE-PROBE"
RUNTIME="$PKG/runtime"
JAMVM="$RUNTIME/bin/jamvm"
GLIBJ="$RUNTIME/share/classpath/glibj.zip"
PROBE="$PKG/runtime-probe.jar"
PLATFORM="$PKG/freej2me-rg35xx.jar"
EVID=${RG35XX_RUNTIME_EVIDENCE:-/mnt/mmc/RG35XX-RUNTIME-CANDIDATE-EVIDENCE}
LOG="$EVID/RUNTIME-PROBE.log"

mkdir -p "$EVID/data" 2>/dev/null || exit 20
: >"$LOG" || exit 20

fail() {
	echo "RUNTIME_PROBE_PRECONDITION=FAIL:$1" | tee -a "$LOG"
	echo "RUNTIME_PROBE_RESULT=FAIL" | tee -a "$LOG"
	exit 20
}

echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$LOG"
echo 'MODE=ALTERNATIVE_RUNTIME_DIAGNOSTIC_ONLY' >>"$LOG"
echo 'BASE=MIYOO_AWEIGIT_PLATFORM' >>"$LOG"
echo 'RUNTIME_PROTECTED_PATH_MUTATION=NO' >>"$LOG"
echo 'DEVICE=ORIGINAL_RG35XX_GARLICOS' >>"$LOG"

[ -x "$JAMVM" ] || fail JAMVM_CANDIDATE_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_CANDIDATE_MISSING
[ -f "$PROBE" ] || fail PROBE_JAR_MISSING
[ -f "$PLATFORM" ] || fail PLATFORM_JAR_MISSING
command -v sha256sum >/dev/null 2>&1 || fail SHA256SUM_MISSING

echo "CANDIDATE_JAMVM_SHA256=$(sha256sum "$JAMVM" | awk '{print $1}')" >>"$LOG"
echo "CANDIDATE_GLIBJ_SHA256=$(sha256sum "$GLIBJ" | awk '{print $1}')" >>"$LOG"
echo "PLATFORM_JAR_SHA256=$(sha256sum "$PLATFORM" | awk '{print $1}')" >>"$LOG"

echo 'JAMVM_VERSION_BEGIN' >>"$LOG"
"$JAMVM" -version >>"$LOG" 2>&1 || fail JAMVM_EXECUTION
echo 'JAMVM_VERSION_END' >>"$LOG"

LD_LIBRARY_PATH="$RUNTIME/lib:$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
"$JAMVM" -Xmx64m \
	-Djava.io.tmpdir="$EVID/data" \
	-cp "$GLIBJ:$PROBE:$PLATFORM" \
	org.recompile.rg35xx.runtimeprobe.RuntimeProbe "$EVID/data" >>"$LOG" 2>&1
RC=$?
echo "RUNTIME_PROBE_EXIT_CODE=$RC" >>"$LOG"

if [ "$RC" -eq 0 ] && grep -q '^RUNTIME_PROBE_RESULT=PASS$' "$LOG"; then
	echo 'RUNTIME_PROBE_RESULT=PASS' >>"$LOG"
	echo 'RUNTIME_PROBE_DEVICE_PASS=NO' >>"$LOG"
	exit 0
fi

echo 'RUNTIME_PROBE_RESULT=FAIL' >>"$LOG"
echo 'RUNTIME_PROBE_DEVICE_PASS=NO' >>"$LOG"
exit 2
