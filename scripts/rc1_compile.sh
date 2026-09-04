#!/bin/sh
set -eu

# RGJ-RC1-011O/011P — deterministic first-build harness.
# This script does not assemble source; run rc1_assemble.sh and
# rc1_runtime_build_overlay.sh first. It preserves the pinned upstream
# Makefile's own CFLAGS/CXXFLAGS/INCLUDES/fPIC definitions instead of
# replacing them from the command line.

: "${RG35XX_ASSEMBLY_ROOT:?set RG35XX_ASSEMBLY_ROOT to the disposable assembled FreeJ2ME tree}"
: "${RG35XX_CC:?set RG35XX_CC to the ARMv5TE uClibc gcc executable}"
: "${RG35XX_CXX:?set RG35XX_CXX to the ARMv5TE uClibc g++ executable}"

fail() { echo "RC1 COMPILE: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 COMPILE: $*"; }

[ -x "$RG35XX_CC" ] || fail "RG35XX_CC is not executable: $RG35XX_CC"
[ -x "$RG35XX_CXX" ] || fail "RG35XX_CXX is not executable: $RG35XX_CXX"
[ -f "$RG35XX_ASSEMBLY_ROOT/build.xml" ] || fail "assembled FreeJ2ME build.xml missing"
[ -f "$RG35XX_ASSEMBLY_ROOT/src/libretro/Makefile" ] || fail "assembled libretro Makefile missing"
[ -f "$RG35XX_ASSEMBLY_ROOT/src/libretro/rg35xx/rc1_make_overlay.mk" ] || fail "RG35XX Make overlay missing"
[ -f "$RG35XX_ASSEMBLY_ROOT/rg35xx_runtime_files.list" ] || fail "runtime deployment manifest missing; run rc1_runtime_build_overlay.sh first"
[ "$(grep -c '^include rg35xx/rc1_make_overlay\.mk$' "$RG35XX_ASSEMBLY_ROOT/src/libretro/Makefile.common")" = 1 ] || fail "Makefile.common must include RG35XX overlay exactly once"

CC_MACHINE=$($RG35XX_CC -dumpmachine 2>/dev/null || true)
CXX_MACHINE=$($RG35XX_CXX -dumpmachine 2>/dev/null || true)
case "$CC_MACHINE" in arm*-uclibc*|arm*-linux-uclibc*) ;; *) fail "unexpected C compiler target: $CC_MACHINE" ;; esac
case "$CXX_MACHINE" in arm*-uclibc*|arm*-linux-uclibc*) ;; *) fail "unexpected C++ compiler target: $CXX_MACHINE" ;; esac

TARGET_FLAGS="-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft"
CC_CMD="$RG35XX_CC $TARGET_FLAGS"
CXX_CMD="$RG35XX_CXX $TARGET_FLAGS"

command -v ant >/dev/null 2>&1 || fail "ant not found"
command -v make >/dev/null 2>&1 || fail "make not found"

# The pinned Makefile appends -O3, -Wall, -D__LIBRETRO__, INCLUDES and -fPIC.
# Never pass CFLAGS/CXXFLAGS on the make command line: GNU make command-line
# variables can override normal makefile assignments and silently remove those
# required flags. CPU/ABI flags are carried by the compiler command itself,
# matching the known-good RG35XX cross-compile invocation used during device work.
MAKEFILE="$RG35XX_ASSEMBLY_ROOT/src/libretro/Makefile"
grep -q 'CFLAGS[[:space:]]*+=[[:space:]]*-Wall' "$MAKEFILE" || fail "pinned Makefile CFLAGS baseline changed"
grep -q 'CXXFLAGS[[:space:]]*+=[[:space:]]*-Wall' "$MAKEFILE" || fail "pinned Makefile CXXFLAGS baseline changed"
grep -q 'D__LIBRETRO__' "$MAKEFILE" || fail "pinned Makefile libretro define missing"
grep -q '$(INCLUDES)' "$MAKEFILE" || fail "pinned Makefile include expansion missing"
grep -q '$(fpic)' "$MAKEFILE" || fail "pinned Makefile fPIC expansion missing"

note "Java compile: clean Ant build against consolidated source"
(
  cd "$RG35XX_ASSEMBLY_ROOT"
  rm -rf build
  ant
)
JAVA_JAR="$RG35XX_ASSEMBLY_ROOT/build/freej2me_plus-lr.jar"
[ -s "$JAVA_JAR" ] || fail "Ant completed but build/freej2me_plus-lr.jar is missing"

note "Native compile: ARMv5TE/uClibc, soft-float, preserving upstream Makefile flags"
(
  cd "$RG35XX_ASSEMBLY_ROOT/src/libretro"
  make clean
  # Remove host/user flag leakage. Project flags are reintroduced by Makefile +
  # rg35xx/rc1_make_overlay.mk; target CPU/ABI flags stay in CC/CXX commands.
  unset CFLAGS CXXFLAGS LDFLAGS CPPFLAGS
  make platform=unix \
    CC="$CC_CMD" \
    CXX="$CXX_CMD"
)
CORE_SO="$RG35XX_ASSEMBLY_ROOT/src/libretro/freej2me_plus_libretro.so"
[ -s "$CORE_SO" ] || fail "native build completed but libretro core is missing"

# Static artifact checks only. Device validation remains separate.
if command -v file >/dev/null 2>&1; then
  file "$CORE_SO" | grep -qi 'ARM' || fail "built core is not identified as ARM"
fi

NM="${RG35XX_NM:-${RG35XX_CC%gcc}nm}"
if [ -x "$NM" ]; then
  if "$NM" -u "$CORE_SO" 2>/dev/null | grep -q 'rg35xx_'; then
    "$NM" -u "$CORE_SO" 2>/dev/null | grep 'rg35xx_' >&2 || true
    fail "built core still has unresolved RG35XX symbols"
  fi
  note "RG35XX undefined-symbol scan passed using $NM"
else
  fail "target nm is required for unresolved RG35XX symbol audit; set RG35XX_NM"
fi

note "COMPILE PASS CANDIDATE: Java JAR and ARM core were produced."
note "Java artifact: $JAVA_JAR"
note "Native artifact: $CORE_SO"
note "Do not mark BUILD-PASS until compiler/link output has been reviewed for warnings/errors."
note "Do not mark DEVICE-TEST-PASS until the artifacts have been exercised on the RG35XX."
