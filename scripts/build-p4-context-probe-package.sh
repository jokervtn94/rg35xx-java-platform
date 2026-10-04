#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$ROOT/out/p4-context-probe"
PKGROOT="$OUT/RG35XX-P4-CONTEXT-PROBE"
PAYLOAD="$PKGROOT/SD/Roms/APPS/RG35XX-P4-CONTEXT-PROBE"
APP="$PKGROOT/SD/Roms/APPS/RG35XX-P4-CONTEXT-PROBE.sh"
SRC="$ROOT/tests/p4/rg35xx_egl_gles_context_probe.c"

fail(){ echo "P4_CONTEXT_PROBE_BUILD_FAIL=$*" >&2; exit 1; }

command -v arm-linux-gnueabihf-gcc >/dev/null 2>&1 || fail arm-linux-gnueabihf-gcc_missing
command -v arm-linux-gnueabi-gcc >/dev/null 2>&1 || fail arm-linux-gnueabi-gcc_missing
test -f "$SRC" || fail source_missing

rm -rf "$OUT"
mkdir -p "$PAYLOAD"

arm-linux-gnueabihf-gcc -O2 -pipe -fno-stack-protector -fPIE -pie "$SRC" -ldl \
  -o "$PAYLOAD/p4-egl-gles-context-probe-hardfloat"
arm-linux-gnueabi-gcc -O2 -pipe -fno-stack-protector -fPIE -pie "$SRC" -ldl \
  -o "$PAYLOAD/p4-egl-gles-context-probe-softfloat"
chmod +x "$PAYLOAD"/p4-egl-gles-context-probe-*

cat > "$APP" <<'EOF_APP'
#!/bin/sh
set +e

APPDIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
BINROOT="$APPDIR/RG35XX-P4-CONTEXT-PROBE"
EVID=/mnt/mmc/RG35XX-P4-CONTEXT-EVIDENCE
LOG="$EVID/P4-EGL-GLES-CONTEXT.log"
mkdir -p "$EVID"
: > "$LOG"
echo "P4_CONTEXT_WRAPPER=BEGIN" >> "$LOG"
echo "P4_DO_NOT_REENABLE_3D=YES" >> "$LOG"

run_probe(){
  candidate="$1"
  [ -x "$candidate" ] || return 127
  echo "P4_CONTEXT_CANDIDATE=$candidate" >> "$LOG"
  LD_LIBRARY_PATH="/usr/lib:/lib:$BINROOT${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$candidate" >> "$LOG" 2>&1
  return $?
}

run_probe "$BINROOT/p4-egl-gles-context-probe-hardfloat"
RC=$?
if [ "$RC" -ne 0 ] || ! grep -q '^P4_CONTEXT_RESULT=PASS$' "$LOG"; then
  echo "P4_CONTEXT_HARDFLOAT_RC=$RC" >> "$LOG"
  run_probe "$BINROOT/p4-egl-gles-context-probe-softfloat"
  RC=$?
fi

if grep -q '^P4_CONTEXT_RESULT=PASS$' "$LOG"; then
  echo "P4_CONTEXT_DEVICE_RESULT=PASS" >> "$LOG"
else
  echo "P4_CONTEXT_DEVICE_RESULT=REVIEW_REQUIRED" >> "$LOG"
fi
echo "P4_CONTEXT_WRAPPER=END RC=$RC" >> "$LOG"
sync
echo "P4_CONTEXT_LOG=$LOG"
grep -E '^(P4_CONTEXT_(EGL_INITIALIZE|EGL_BIND_ES|EGL_CHOOSE_CONFIG|EGL_PBUFFER|EGL_CONTEXT|EGL_MAKE_CURRENT|GL_VENDOR|GL_RENDERER|GL_VERSION|RESULT|DEVICE_RESULT))' "$LOG"
exit 0
EOF_APP
chmod +x "$APP"

cat > "$PKGROOT/P4-CONTEXT-PROBE-README.txt" <<'EOF_README'
RG35XX P4.1 EGL/GLES context probe

This package is a read-only ARM probe. It dynamically opens the device EGL and
GLESv2 libraries, requests the default display, initializes EGL, chooses an
OpenGL ES 2 config, creates a 1x1 pbuffer/context, makes it current and reads
the EGL and GL vendor/renderer/version strings.

It does not load Java M3G, MascotCapsule/Micro3D or LWJGL classes and does not
modify the production runtime.

Run:
  /mnt/mmc/Roms/APPS/RG35XX-P4-CONTEXT-PROBE.sh

Evidence:
  /mnt/mmc/RG35XX-P4-CONTEXT-EVIDENCE/P4-EGL-GLES-CONTEXT.log
EOF_README

cat > "$PKGROOT/P4-CONTEXT-PROBE-IDENTITY.txt" <<'EOF_ID'
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P4_3D_CAPABILITY_DECISION
PACKAGE=RG35XX-P4-CONTEXT-PROBE
PROBE_SCOPE=DLOPEN_EGL_INIT_ES2_PBUFFER_CONTEXT
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
P4_CONTEXT_DEVICE_RESULT=REVIEW_REQUIRED
EOF_ID

(cd "$PKGROOT" && find . -type f -print | sort | xargs sha256sum > PAYLOAD-SHA256SUMS.txt)
(cd "$OUT" && zip -qr RG35XX-P4-CONTEXT-PROBE.zip RG35XX-P4-CONTEXT-PROBE)
echo "P4_CONTEXT_PROBE_BUILD=PASS"
echo "P4_CONTEXT_PROBE_PACKAGE=$OUT/RG35XX-P4-CONTEXT-PROBE.zip"
sha256sum "$OUT/RG35XX-P4-CONTEXT-PROBE.zip"
