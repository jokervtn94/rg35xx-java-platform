#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$ROOT/out/p4-platform-probe"
PKGROOT="$OUT/RG35XX-P4-PLATFORM-PROBE"
PAYLOAD="$PKGROOT/SD/Roms/APPS/RG35XX-P4-PLATFORM-PROBE"
APP="$PKGROOT/SD/Roms/APPS/RG35XX-P4-PLATFORM-PROBE.sh"
SRC="$ROOT/tests/p4/rg35xx_egl_platform_probe.c"

fail(){ echo "P4_PLATFORM_PROBE_BUILD_FAIL=$*" >&2; exit 1; }
test -f "$SRC" || fail source_missing
ARM_CC="${P4_ARM_CC:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc}"
[ -x "$ARM_CC" ] || fail "pinned_miyoo_toolchain_missing:$ARM_CC"

rm -rf "$OUT"
mkdir -p "$PAYLOAD"
"$ARM_CC" -O2 -pipe -fno-stack-protector "$SRC" -ldl \
  -o "$PAYLOAD/p4-egl-platform-probe"
chmod +x "$PAYLOAD/p4-egl-platform-probe"

cat > "$APP" <<'EOF_APP'
#!/bin/sh
set +e
APPDIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
BIN="$APPDIR/RG35XX-P4-PLATFORM-PROBE/p4-egl-platform-probe"
EVID=/mnt/mmc/RG35XX-P4-PLATFORM-EVIDENCE
LOG="$EVID/P4-EGL-PLATFORM.log"
mkdir -p "$EVID"
: > "$LOG"
echo "P4_PLATFORM_WRAPPER=BEGIN" >> "$LOG"
echo "P4_DO_NOT_REENABLE_3D=YES" >> "$LOG"
if [ -x "$BIN" ]; then
  LD_LIBRARY_PATH="/usr/lib:/lib:$(dirname "$BIN")${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$BIN" >> "$LOG" 2>&1
  RC=$?
else
  echo "P4_PLATFORM_BINARY=MISSING" >> "$LOG"
  RC=127
fi
if grep -q '^P4_PLATFORM_RESULT=PASS$' "$LOG"; then
  echo "P4_PLATFORM_DEVICE_RESULT=PASS" >> "$LOG"
else
  echo "P4_PLATFORM_DEVICE_RESULT=REVIEW_REQUIRED" >> "$LOG"
fi
echo "P4_PLATFORM_WRAPPER=END RC=$RC" >> "$LOG"
sync
echo "P4_PLATFORM_LOG=$LOG"
grep -E '^(P4_PLATFORM_(NODE|ENV|FILE|CLIENT_EXTENSIONS|DEFAULT|GET_PLATFORM|DEVICE|INITIALIZE|DISPLAY|RESULT|DEVICE_RESULT))' "$LOG"
exit 0
EOF_APP
chmod +x "$APP"

cat > "$PKGROOT/P4-PLATFORM-PROBE-README.txt" <<'EOF_README'
RG35XX P4.2 EGL platform/device diagnostic

This is a read-only diagnostic. It inventories framebuffer/GPU device nodes and
SDL/EGL environment variables, queries EGL client extensions, tests the default
display, and if advertised tests EGL platform/device display entry points.
It does not load Java 3D classes and does not modify the production runtime.

Run:
  /mnt/mmc/Roms/APPS/RG35XX-P4-PLATFORM-PROBE.sh

Evidence:
  /mnt/mmc/RG35XX-P4-PLATFORM-EVIDENCE/P4-EGL-PLATFORM.log
EOF_README

cat > "$PKGROOT/P4-PLATFORM-PROBE-IDENTITY.txt" <<'EOF_ID'
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P4_3D_CAPABILITY_DECISION
PACKAGE=RG35XX-P4-PLATFORM-PROBE
PROBE_SCOPE=DEVICE_NODES_ENV_EGL_CLIENT_PLATFORM_DEVICE_DISPLAY
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
EOF_ID

(cd "$PKGROOT" && find . -type f -print | sort | xargs sha256sum > PAYLOAD-SHA256SUMS.txt)
(cd "$OUT" && zip -qr RG35XX-P4-PLATFORM-PROBE.zip RG35XX-P4-PLATFORM-PROBE)
echo "P4_PLATFORM_PROBE_BUILD=PASS"
echo "P4_PLATFORM_PROBE_PACKAGE=$OUT/RG35XX-P4-PLATFORM-PROBE.zip"
sha256sum "$OUT/RG35XX-P4-PLATFORM-PROBE.zip"
