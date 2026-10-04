#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$ROOT/out/p4-capability-probe"
PKGROOT="$OUT/RG35XX-P4-CAPABILITY-PROBE"
APP="$PKGROOT/SD/Roms/APPS/RG35XX-P4-CAPABILITY-PROBE.sh"

rm -rf "$OUT"
mkdir -p "$(dirname "$APP")"

cat > "$APP" <<'EOF_PROBE'
#!/bin/sh
set +e

EVID=/mnt/mmc/RG35XX-P4-CAPABILITY-EVIDENCE
LOG="$EVID/P4-EGL-GLES-PROBE.log"
mkdir -p "$EVID"
: > "$LOG"

emit(){ echo "$*" >> "$LOG"; }
emit "P4_PROBE_BEGIN=$(date 2>/dev/null || echo UNKNOWN)"
emit "P4_SCOPE=READ_ONLY_EGL_GLES_PROVIDER_INVENTORY"
emit "P4_DO_NOT_REENABLE_3D=YES"
emit "P4_CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63"
emit "P4_UNAME=$(uname -a 2>/dev/null)"

for f in /etc/os-release /etc/buildroot-release /etc/version /etc/issue; do
  if [ -f "$f" ]; then
    emit "P4_RELEASE_FILE=$f"
    sed 's/[[:cntrl:]]//g' "$f" >> "$LOG" 2>/dev/null
  fi
done

LIB_ROOTS="/lib /usr/lib /usr/local/lib /opt/lib /mnt/mmc/CFW /mnt/mmc/Roms/APPS"
for root in $LIB_ROOTS; do
  if [ -d "$root" ]; then
    find "$root" -maxdepth 5 -type f \( \
      -iname 'libEGL.so*' -o -iname 'libGLES.so*' -o -iname 'libGLESv1_CM.so*' \
      -o -iname 'libGLESv2.so*' -o -iname 'libMali.so*' -o -iname 'libGL.so*' \
    \) -print 2>/dev/null | sort -u | while IFS= read -r lib; do
      [ -n "$lib" ] || continue
      emit "P4_PROVIDER_FILE=$lib"
      if command -v file >/dev/null 2>&1; then
        emit "P4_PROVIDER_FILE_INFO=$(file "$lib" 2>/dev/null)"
      fi
      if command -v strings >/dev/null 2>&1; then
        strings "$lib" 2>/dev/null | grep -E '(^|[^A-Za-z])(egl|EGL|gles|GLES|Mali|OpenGL|OpenGLES)([^A-Za-z]|$)' | head -40 | while IFS= read -r symbol; do
          emit "P4_PROVIDER_STRING=$symbol"
        done
      fi
    done
  fi
done

if command -v ldconfig >/dev/null 2>&1; then
  emit "P4_LDCONFIG_BEGIN"
  ldconfig -p 2>/dev/null | grep -E 'lib(EGL|GLES|GLESv1_CM|GLESv2|Mali|GL)\.so' >> "$LOG"
  emit "P4_LDCONFIG_END"
else
  emit "P4_LDCONFIG=UNAVAILABLE"
fi

if grep -q '^P4_PROVIDER_FILE=' "$LOG" || grep -q 'libEGL\.so' "$LOG" || grep -q 'libGLES' "$LOG"; then
  emit "P4_PROVIDER_INVENTORY=FOUND"
  emit "P4_DECISION=REQUIRES_SYMBOL_AND_CONTEXT_REVIEW"
else
  emit "P4_PROVIDER_INVENTORY=NOT_FOUND"
  emit "P4_DECISION=NO_EGL_GLES_PROVIDER_VISIBLE_IN_SEARCH_ROOTS"
fi

emit "P4_PROBE_END=$(date 2>/dev/null || echo UNKNOWN)"
sync
echo "P4_DEVICE_PROBE_LOG=$LOG"
echo "P4_DEVICE_RESULT=REVIEW_REQUIRED"
exit 0
EOF_PROBE
chmod +x "$APP"

cat > "$PKGROOT/P4-CAPABILITY-PROBE-README.txt" <<'EOF_README'
RG35XX P4 EGL/GLES capability probe

Copy the SD/ tree to the root of the GarlicOS SD card and run:
  /mnt/mmc/Roms/APPS/RG35XX-P4-CAPABILITY-PROBE.sh

The probe is read-only. It inventories visible EGL/GLES/OpenGL provider files,
release information and optional strings/ldconfig output. It does not load or
enable M3G, MascotCapsule/Micro3D, LWJGL or OpenGL classes.

Evidence output:
  /mnt/mmc/RG35XX-P4-CAPABILITY-EVIDENCE/P4-EGL-GLES-PROBE.log

P4_DEVICE_RESULT=REVIEW_REQUIRED is intentional until the provider inventory
is mapped to the canonical Aweigit native call surface.
EOF_README

cat > "$PKGROOT/P4-CAPABILITY-PROBE-IDENTITY.txt" <<'EOF_ID'
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P4_3D_CAPABILITY_DECISION
PACKAGE=RG35XX-P4-CAPABILITY-PROBE
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
PROBE_SCOPE=READ_ONLY_EGL_GLES_PROVIDER_INVENTORY
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
P4_DEVICE_RESULT=REVIEW_REQUIRED
EOF_ID

(cd "$PKGROOT" && find . -type f -print | sort | xargs sha256sum > PAYLOAD-SHA256SUMS.txt)
(cd "$OUT" && zip -qr "RG35XX-P4-CAPABILITY-PROBE.zip" "RG35XX-P4-CAPABILITY-PROBE")
echo "P4_CAPABILITY_PROBE_BUILD=PASS"
echo "P4_CAPABILITY_PROBE_PACKAGE=$OUT/RG35XX-P4-CAPABILITY-PROBE.zip"
sha256sum "$OUT/RG35XX-P4-CAPABILITY-PROBE.zip"
