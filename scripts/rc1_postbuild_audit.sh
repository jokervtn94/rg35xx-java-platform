#!/bin/sh
set -eu

# RGJ-RC1-011P — post-compile artifact acceptance gate.
# This is a build artifact audit, not a device-test gate.
: "${RG35XX_ASSEMBLY_ROOT:?set RG35XX_ASSEMBLY_ROOT to the assembled FreeJ2ME tree}"
: "${RG35XX_CC:?set RG35XX_CC to the ARMv5TE uClibc gcc executable}"

fail() { echo "RC1 POSTBUILD: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 POSTBUILD: $*"; }

JAR="$RG35XX_ASSEMBLY_ROOT/build/freej2me_plus-lr.jar"
SO="$RG35XX_ASSEMBLY_ROOT/src/libretro/freej2me_plus_libretro.so"
MANIFEST="$RG35XX_ASSEMBLY_ROOT/rg35xx_runtime_files.list"
[ -s "$JAR" ] || fail "missing Java artifact: $JAR"
[ -s "$SO" ] || fail "missing native artifact: $SO"
[ -s "$MANIFEST" ] || fail "missing runtime deployment manifest"

NM="${RG35XX_NM:-${RG35XX_CC%gcc}nm}"
READELF="${RG35XX_READELF:-${RG35XX_CC%gcc}readelf}"
[ -x "$NM" ] || fail "target nm missing; set RG35XX_NM"
[ -x "$READELF" ] || fail "target readelf missing; set RG35XX_READELF"

if command -v file >/dev/null 2>&1; then
  file "$SO" | grep -qi 'ARM' || fail "core is not ARM"
fi

if "$NM" -u "$SO" 2>/dev/null | grep -q 'rg35xx_'; then
  "$NM" -u "$SO" 2>/dev/null | grep 'rg35xx_' >&2 || true
  fail "unresolved project-owned rg35xx_* symbols remain"
fi

ATTRS=$($READELF -A "$SO" 2>/dev/null || true)
if printf '%s\n' "$ATTRS" | grep -q 'Tag_ABI_VFP_args: VFP registers'; then
  fail "hard-float VFP argument ABI detected; RG35XX Original target is soft-float"
fi

DYNAMIC=$($READELF -d "$SO" 2>/dev/null || true)
if printf '%s\n' "$DYNAMIC" | grep -q 'Shared library: \[libc\.so\.6\]'; then
  fail "glibc libc.so.6 dependency detected in RG35XX/uClibc artifact"
fi
if printf '%s\n' "$DYNAMIC" | grep -q 'Shared library: \[ld-linux'; then
  fail "glibc dynamic-loader dependency detected"
fi

if command -v jar >/dev/null 2>&1; then
  JAR_LIST=$(jar tf "$JAR")
elif command -v unzip >/dev/null 2>&1; then
  JAR_LIST=$(unzip -Z1 "$JAR")
else
  fail "jar or unzip is required to audit Java artifact contents"
fi

# Core RG35XX Java owners that must be present in the consolidated jar.
for cls in \
  org/recompile/mobile/RG35XXPlatformProfile.class \
  org/recompile/mobile/RG35XXFrameScheduler.class \
  org/recompile/mobile/RG35XXImageCache.class \
  org/recompile/mobile/RG35XXInputEngine.class \
  org/recompile/mobile/RG35XXWavDecoder.class \
  org/recompile/mobile/RG35XXMediaProfile.class \
  org/recompile/mobile/RG35XXRuntimeStats.class; do
  printf '%s\n' "$JAR_LIST" | grep -Fxq "$cls" || fail "missing Java owner in jar: $cls"
done

# Historical font engine must stay removed/superseded.
if printf '%s\n' "$JAR_LIST" | grep -q 'RG35XXFontEngine\.class$'; then
  fail "superseded RG35XXFontEngine was reintroduced"
fi

# Deployment manifest must have one deterministic font entry and no host assembly leak.
[ "$(grep -c '^TYPE=font$' "$MANIFEST")" = 1 ] || fail "runtime manifest must contain exactly one font entry"
grep -q '^TARGET=/' "$MANIFEST" || fail "runtime font target must be absolute"
grep -Eq '^SHA256=[0-9a-fA-F]{64}$' "$MANIFEST" || fail "runtime font SHA256 missing/invalid"

note "POSTBUILD ARTIFACT AUDIT PASS"
note "Java artifact=$JAR"
note "Native artifact=$SO"
note "No unresolved rg35xx_* symbols, no hard-float VFP ABI, no glibc dependency, required Java owners present."
note "This is BUILD-PASS evidence only when rc1_compile.sh completed successfully in the same assembled tree."
note "DEVICE-TEST-PASS still requires RG35XX hardware execution."
