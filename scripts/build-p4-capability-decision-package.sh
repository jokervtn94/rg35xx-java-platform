#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="$ROOT/out/p4-capability-decision"
PKGROOT="$OUT/RG35XX-P4-CAPABILITY-DECISION"
SDROOT="$PKGROOT/SD"
APP="$SDROOT/Roms/APPS/RG35XX-P4-CAPABILITY-DECISION.sh"
COMPONENTS="$PKGROOT/COMPONENTS"

fail(){ echo "P4_CAPABILITY_DECISION_BUILD_FAIL=$*" >&2; exit 1; }

# P4 is diagnostic only. Reuse the three already-reviewed probes rather than
# creating a fourth hardware implementation path.
for script in \
  scripts/build-p4-capability-probe-package.sh \
  scripts/build-p4-context-probe-package.sh \
  scripts/build-p4-platform-probe-package.sh; do
  test -f "$script" || fail "missing_component_builder:$script"
  chmod +x "$script"
done

bash scripts/build-p4-capability-probe-package.sh | tee /tmp/p4-capability-build.log
bash scripts/build-p4-context-probe-package.sh | tee /tmp/p4-context-build.log
bash scripts/build-p4-platform-probe-package.sh | tee /tmp/p4-platform-build.log

grep -q '^P4_CAPABILITY_PROBE_BUILD=PASS$' /tmp/p4-capability-build.log || fail capability_probe_build
grep -q '^P4_CONTEXT_PROBE_BUILD=PASS$' /tmp/p4-context-build.log || fail context_probe_build
grep -q '^P4_PLATFORM_PROBE_BUILD=PASS$' /tmp/p4-platform-build.log || fail platform_probe_build

rm -rf "$OUT"
mkdir -p "$SDROOT" "$COMPONENTS"

copy_sd_tree(){
  src="$1"
  test -d "$src" || fail "missing_component_sd:$src"
  cp -a "$src"/. "$SDROOT"/
}

copy_sd_tree "$ROOT/out/p4-capability-probe/RG35XX-P4-CAPABILITY-PROBE/SD"
copy_sd_tree "$ROOT/out/p4-context-probe/RG35XX-P4-CONTEXT-PROBE/SD"
copy_sd_tree "$ROOT/out/p4-platform-probe/RG35XX-P4-PLATFORM-PROBE/SD"

cp "$ROOT/out/p4-capability-probe/RG35XX-P4-CAPABILITY-PROBE/P4-CAPABILITY-PROBE-IDENTITY.txt" "$COMPONENTS/"
cp "$ROOT/out/p4-context-probe/RG35XX-P4-CONTEXT-PROBE/P4-CONTEXT-PROBE-IDENTITY.txt" "$COMPONENTS/"
cp "$ROOT/out/p4-platform-probe/RG35XX-P4-PLATFORM-PROBE/P4-PLATFORM-PROBE-IDENTITY.txt" "$COMPONENTS/"

mkdir -p "$(dirname "$APP")"
cat > "$APP" <<'EOF_APP'
#!/bin/sh
set +e

EVID=/mnt/mmc/RG35XX-P4-CAPABILITY-DECISION-EVIDENCE
LOG="$EVID/P4-CAPABILITY-DECISION.log"
APPS=/mnt/mmc/Roms/APPS
mkdir -p "$EVID"
: > "$LOG"

emit(){ echo "$*" >> "$LOG"; }
run_component(){
  name="$1"
  script="$2"
  emit "P4_COMPONENT_BEGIN=$name"
  if [ -x "$script" ]; then
    "$script" >> "$LOG" 2>&1
    rc=$?
  else
    emit "P4_COMPONENT_MISSING=$script"
    rc=127
  fi
  emit "P4_COMPONENT_END=$name RC=$rc"
  return 0
}

emit "PROJECT=RG35XX-AWEIGIT-R1"
emit "MODULE=P4_3D_CAPABILITY_DECISION"
emit "P4_PARENT_COMMIT=23a79d5d8bdf024382890f8d347cf50c85c91203"
emit "P4_CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63"
emit "P4_PHYSICAL_TEST_LEVEL=MODULE"
emit "P4_DIAGNOSTIC_ONLY=YES"
emit "P4_DO_NOT_REENABLE_3D=YES"
emit "M3G_REENABLED=NO"
emit "MICRO3D_REENABLED=NO"
emit "LWJGL_OPENGL_REENABLED=NO"
emit "DEVICE_PASS=NO"
emit "STABLE=NO"

run_component INVENTORY "$APPS/RG35XX-P4-CAPABILITY-PROBE.sh"
run_component EGL_GLES_CONTEXT "$APPS/RG35XX-P4-CONTEXT-PROBE.sh"
run_component EGL_PLATFORM_DEVICE "$APPS/RG35XX-P4-PLATFORM-PROBE.sh"

# Consolidate the three child logs into one evidence directory. Missing logs are
# explicit evidence, not silently ignored.
collect_log(){
  src="$1"
  dst="$2"
  if [ -f "$src" ]; then
    cp "$src" "$EVID/$dst"
    emit "P4_COLLECTED=$dst"
  else
    emit "P4_MISSING_EVIDENCE=$src"
  fi
}

collect_log /mnt/mmc/RG35XX-P4-CAPABILITY-EVIDENCE/P4-EGL-GLES-PROBE.log P4-EGL-GLES-PROBE.log
collect_log /mnt/mmc/RG35XX-P4-CONTEXT-EVIDENCE/P4-EGL-GLES-CONTEXT.log P4-EGL-GLES-CONTEXT.log
collect_log /mnt/mmc/RG35XX-P4-PLATFORM-EVIDENCE/P4-EGL-PLATFORM.log P4-EGL-PLATFORM.log

if [ -f "$EVID/P4-EGL-GLES-PROBE.log" ] && \
   [ -f "$EVID/P4-EGL-GLES-CONTEXT.log" ] && \
   [ -f "$EVID/P4-EGL-PLATFORM.log" ]; then
  emit "P4_CAPABILITY_DECISION_DEVICE_EVIDENCE=COLLECTED"
else
  emit "P4_CAPABILITY_DECISION_DEVICE_EVIDENCE=PARTIAL"
fi

# A probe PASS is not permission to enable a deferred feature. Human/source
# review must map measured EGL/GLES behavior to the pinned Miyoo native stack.
emit "P4_CAPABILITY_DECISION=REVIEW_REQUIRED"
emit "P4_PLATFORM_BASELINE_DEVICE_PASS=NO"
emit "P4_WRAPPER_END=$(date 2>/dev/null || echo UNKNOWN)"
sync

cat "$LOG"
exit 0
EOF_APP
chmod +x "$APP"

cat > "$PKGROOT/README-FIRST.txt" <<'EOF_README'
RG35XX P4 — Deferred capability decision, single physical module package

Purpose:
  Collect the complete read-only P4 hardware evidence in one original-RG35XX
  physical cycle. This package does NOT enable M3G, MascotCapsule/Micro3D,
  LWJGL/OpenGL, or modify the production FreeJ2ME runtime.

Install:
  Copy the SD/ tree to the root of the GarlicOS SD card.

Run exactly one launcher:
  /mnt/mmc/Roms/APPS/RG35XX-P4-CAPABILITY-DECISION.sh

Return this one evidence directory:
  /mnt/mmc/RG35XX-P4-CAPABILITY-DECISION-EVIDENCE

Required files after the run:
  P4-CAPABILITY-DECISION.log
  P4-EGL-GLES-PROBE.log
  P4-EGL-GLES-CONTEXT.log
  P4-EGL-PLATFORM.log

The expected final marker before review is:
  P4_CAPABILITY_DECISION=REVIEW_REQUIRED

That marker is intentional. A successful hardware probe is evidence for the
P4 decision; it is not authority to re-enable a deferred 3D provider.
EOF_README

cat > "$PKGROOT/P4-CAPABILITY-DECISION-IDENTITY.txt" <<'EOF_ID'
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P4_3D_CAPABILITY_DECISION
PACKAGE=RG35XX-P4-CAPABILITY-DECISION
PARENT_COMMIT=23a79d5d8bdf024382890f8d347cf50c85c91203
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
PHYSICAL_TEST_LEVEL=MODULE
RUNTIME_SEMANTIC_DELTA=NONE
DIAGNOSTIC_ONLY=YES
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
P4_CAPABILITY_DECISION=REVIEW_REQUIRED
DEVICE_PASS=NO
STABLE=NO
EOF_ID

(cd "$PKGROOT" && find . -type f -print | sort | xargs sha256sum > PAYLOAD-SHA256SUMS.txt)
(cd "$OUT" && zip -qr RG35XX-P4-CAPABILITY-DECISION.zip RG35XX-P4-CAPABILITY-DECISION)

echo "P4_CAPABILITY_DECISION_BUILD=PASS"
echo "P4_RUNTIME_SEMANTIC_DELTA=NONE"
echo "P4_PHYSICAL_TEST_LEVEL=MODULE"
echo "P4_CAPABILITY_DECISION_PACKAGE=$OUT/RG35XX-P4-CAPABILITY-DECISION.zip"
sha256sum "$OUT/RG35XX-P4-CAPABILITY-DECISION.zip"
