#!/bin/sh
set -u

APP=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
PKG="$APP/RG35XX-MIYOO-JDK-ABI-PROBE"
JDK="$PKG/runtime/jdk"
JAVA="$JDK/bin/java"
PROBE="$PKG/runtime-probe.jar"
PLATFORM="$PKG/freej2me-rg35xx.jar"
EVID=${RG35XX_RUNTIME_EVIDENCE:-/mnt/mmc/RG35XX-MIYOO-JDK-ABI-EVIDENCE}
LOG="$EVID/MIYOO-JDK-ABI-PROBE.log"

mkdir -p "$EVID/data" 2>/dev/null || exit 20
: >"$LOG" || exit 20

fail() {
	echo "MIYOO_JDK_PROBE=FAIL:$1" | tee -a "$LOG"
	echo 'DEVICE_PASS=NO' >>"$LOG"
	exit 20
}

{
	echo 'PROJECT=RG35XX-AWEIGIT-R1'
	echo 'MODE=MIYOO_OPENJDK_ABI_DIAGNOSTIC_ONLY'
	echo 'SOURCE=MIYOO_AWEIGIT_RELEASE_2.0'
	echo 'RUNTIME_PROTECTED_PATH_MUTATION=NO'
	echo 'DEVICE=ORIGINAL_RG35XX_GARLICOS'
	echo 'EXPECTED_MISMATCH=MIYOO_ARMHF_VS_RG35XX_SOFT_FLOAT_UCLIBC'
} >>"$LOG"

[ -x "$JAVA" ] || fail MIYOO_JDK_MISSING
[ -f "$PROBE" ] || fail PROBE_JAR_MISSING
[ -f "$PLATFORM" ] || fail PLATFORM_JAR_MISSING

if command -v sha256sum >/dev/null 2>&1; then
	echo "MIYOO_JAVA_SHA256=$(sha256sum "$JAVA" | awk '{print $1}')" >>"$LOG"
	echo "PLATFORM_JAR_SHA256=$(sha256sum "$PLATFORM" | awk '{print $1}')" >>"$LOG"
fi

echo 'JAVA_VERSION_BEGIN' >>"$LOG"
LD_LIBRARY_PATH="$JDK/lib:$JDK/lib/server:$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
"$JAVA" -version >>"$LOG" 2>&1
VERSION_RC=$?
echo "JAVA_VERSION_EXIT_CODE=$VERSION_RC" >>"$LOG"
echo 'JAVA_VERSION_END' >>"$LOG"

if [ "$VERSION_RC" -ne 0 ]; then
	echo 'MIYOO_JDK_PROBE=FAIL_RUNTIME_EXECUTION' >>"$LOG"
	echo 'DEVICE_PASS=NO' >>"$LOG"
	exit 2
fi

LD_LIBRARY_PATH="$JDK/lib:$JDK/lib/server:$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
"$JAVA" -cp "$PROBE:$PLATFORM" \
	org.recompile.rg35xx.runtimeprobe.RuntimeProbe "$EVID/data" >>"$LOG" 2>&1
PROBE_RC=$?
echo "RUNTIME_PROBE_EXIT_CODE=$PROBE_RC" >>"$LOG"

if [ "$PROBE_RC" -eq 0 ] && grep -q '^RUNTIME_PROBE_RESULT=PASS$' "$LOG"; then
	echo 'MIYOO_JDK_PROBE=PASS_RUNTIME_ONLY' >>"$LOG"
else
	echo 'MIYOO_JDK_PROBE=FAIL_PLATFORM_RUNTIME' >>"$LOG"
fi
echo 'DEVICE_PASS=NO' >>"$LOG"
exit "$PROBE_RC"
