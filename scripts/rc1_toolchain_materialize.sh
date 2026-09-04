#!/bin/sh
set -eu

# RGJ-RC1-011T — materialize the exact SDK archive produced by 011S.
# This script verifies provenance, extracts/relocates the SDK, validates the
# compiler target, and emits paths consumable by scripts/rc1_compile.sh.
# It does not assemble FreeJ2ME, build GNU Classpath, invoke Ant, or link RC1.

PIN_PROVIDER="MiyooCFW/buildroot"
PIN_COMMIT="8087b52311da5c1e2fa1c50b0b064c07fd174a36"
PIN_DEFCONFIG="configs/miyoo_uclibc_defconfig"
PIN_DEFCONFIG_BLOB="58256d3e7afa3f9fa0dbd79b16fd0b21d93b9d7b"
SDK_NAME="arm-miyoo-linux-uclibcgnueabi_sdk-buildroot.tar.gz"
TRIPLE="arm-miyoo-linux-uclibcgnueabi"
TARGET_FLAGS="-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft"

: "${RG35XX_TOOLCHAIN_ARCHIVE:?set RG35XX_TOOLCHAIN_ARCHIVE to the 011S SDK archive}"
: "${RG35XX_TOOLCHAIN_SOURCE_MANIFEST:?set RG35XX_TOOLCHAIN_SOURCE_MANIFEST to the 011S provenance manifest}"
: "${RG35XX_TOOLCHAIN_ROOT:?set RG35XX_TOOLCHAIN_ROOT to a disposable SDK materialization directory}"

fail() { echo "RC1 TOOLCHAIN MATERIALIZE: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 TOOLCHAIN MATERIALIZE: $*"; }

command -v tar >/dev/null 2>&1 || fail "tar not found"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum not found"
command -v awk >/dev/null 2>&1 || fail "awk not found"
command -v find >/dev/null 2>&1 || fail "find not found"
command -v wc >/dev/null 2>&1 || fail "wc not found"

[ -s "$RG35XX_TOOLCHAIN_ARCHIVE" ] || fail "SDK archive missing: $RG35XX_TOOLCHAIN_ARCHIVE"
[ -s "$RG35XX_TOOLCHAIN_SOURCE_MANIFEST" ] || fail "011S manifest missing: $RG35XX_TOOLCHAIN_SOURCE_MANIFEST"

case "$RG35XX_TOOLCHAIN_ROOT" in
  ''|/|.|..) fail "unsafe RG35XX_TOOLCHAIN_ROOT: $RG35XX_TOOLCHAIN_ROOT" ;;
  *[[:space:]\']*) fail "toolchain root contains unsupported whitespace/apostrophe: $RG35XX_TOOLCHAIN_ROOT" ;;
esac

manifest_value() {
  key="$1"
  awk -F= -v k="$key" '$1 == k { sub(/^[^=]*=/, ""); print; found=1 } END { if (!found) exit 1 }' "$RG35XX_TOOLCHAIN_SOURCE_MANIFEST"
}

PROVIDER=$(manifest_value PROVIDER) || fail "manifest missing PROVIDER"
COMMIT=$(manifest_value COMMIT) || fail "manifest missing COMMIT"
DEFCONFIG=$(manifest_value DEFCONFIG) || fail "manifest missing DEFCONFIG"
DEFCONFIG_BLOB=$(manifest_value DEFCONFIG_GIT_BLOB) || fail "manifest missing DEFCONFIG_GIT_BLOB"
MANIFEST_SDK=$(manifest_value SDK) || fail "manifest missing SDK"
MANIFEST_SHA=$(manifest_value SDK_SHA256) || fail "manifest missing SDK_SHA256"
MANIFEST_SIZE=$(manifest_value SDK_SIZE) || fail "manifest missing SDK_SIZE"
MANIFEST_TRIPLE=$(manifest_value TARGET_TRIPLE) || fail "manifest missing TARGET_TRIPLE"

[ "$PROVIDER" = "$PIN_PROVIDER" ] || fail "unexpected provider: $PROVIDER"
[ "$COMMIT" = "$PIN_COMMIT" ] || fail "unexpected Buildroot commit: $COMMIT"
[ "$DEFCONFIG" = "$PIN_DEFCONFIG" ] || fail "unexpected defconfig: $DEFCONFIG"
[ "$DEFCONFIG_BLOB" = "$PIN_DEFCONFIG_BLOB" ] || fail "unexpected defconfig blob: $DEFCONFIG_BLOB"
[ "$MANIFEST_SDK" = "$SDK_NAME" ] || fail "unexpected SDK name: $MANIFEST_SDK"
[ "$MANIFEST_TRIPLE" = "$TRIPLE" ] || fail "unexpected target triple: $MANIFEST_TRIPLE"
[ "$(basename "$RG35XX_TOOLCHAIN_ARCHIVE")" = "$SDK_NAME" ] || fail "archive basename does not match manifest SDK name"

ACTUAL_SHA=$(sha256sum "$RG35XX_TOOLCHAIN_ARCHIVE" | awk '{print $1}')
ACTUAL_SIZE=$(wc -c < "$RG35XX_TOOLCHAIN_ARCHIVE" | tr -d ' ')
[ "$ACTUAL_SHA" = "$MANIFEST_SHA" ] || fail "SDK SHA-256 mismatch: $ACTUAL_SHA != $MANIFEST_SHA"
[ "$ACTUAL_SIZE" = "$MANIFEST_SIZE" ] || fail "SDK size mismatch: $ACTUAL_SIZE != $MANIFEST_SIZE"

if [ -e "$RG35XX_TOOLCHAIN_ROOT" ]; then
  [ -d "$RG35XX_TOOLCHAIN_ROOT" ] || fail "toolchain root exists but is not a directory"
  [ -z "$(find "$RG35XX_TOOLCHAIN_ROOT" -mindepth 1 -maxdepth 1 -print -quit)" ] || fail "toolchain root must be empty"
else
  mkdir -p "$RG35XX_TOOLCHAIN_ROOT"
fi

note "Extracting verified SDK archive"
tar -xzf "$RG35XX_TOOLCHAIN_ARCHIVE" -C "$RG35XX_TOOLCHAIN_ROOT"

RELOCATE_LIST=$(find "$RG35XX_TOOLCHAIN_ROOT" -type f -name relocate-sdk.sh -print)
RELOCATE_COUNT=$(printf '%s\n' "$RELOCATE_LIST" | sed '/^$/d' | wc -l | tr -d ' ')
case "$RELOCATE_COUNT" in
  0) note "No relocate-sdk.sh present; continuing with archive paths as produced" ;;
  1)
    RELOCATE=$(printf '%s\n' "$RELOCATE_LIST" | sed -n '1p')
    note "Running Buildroot SDK relocation: $RELOCATE"
    sh "$RELOCATE"
    ;;
  *) fail "expected at most one relocate-sdk.sh, found $RELOCATE_COUNT" ;;
esac

find_one_tool() {
  name="$1"
  list=$(find "$RG35XX_TOOLCHAIN_ROOT" -type f -path "*/bin/$name" -print)
  count=$(printf '%s\n' "$list" | sed '/^$/d' | wc -l | tr -d ' ')
  [ "$count" = 1 ] || fail "expected exactly one $name, found $count"
  printf '%s\n' "$list" | sed -n '1p'
}

CC=$(find_one_tool "${TRIPLE}-gcc")
CXX=$(find_one_tool "${TRIPLE}-g++")
NM=$(find_one_tool "${TRIPLE}-nm")
READELF=$(find_one_tool "${TRIPLE}-readelf")

[ -x "$CC" ] || fail "gcc is not executable: $CC"
[ -x "$CXX" ] || fail "g++ is not executable: $CXX"
[ -x "$NM" ] || fail "nm is not executable: $NM"
[ -x "$READELF" ] || fail "readelf is not executable: $READELF"

CC_MACHINE=$($CC -dumpmachine 2>/dev/null || true)
CXX_MACHINE=$($CXX -dumpmachine 2>/dev/null || true)
case "$CC_MACHINE" in arm*-uclibc*|arm*-linux-uclibc*) ;; *) fail "unexpected gcc target: $CC_MACHINE" ;; esac
case "$CXX_MACHINE" in arm*-uclibc*|arm*-linux-uclibc*) ;; *) fail "unexpected g++ target: $CXX_MACHINE" ;; esac

PROBE_DIR="$RG35XX_TOOLCHAIN_ROOT/.rg35xx-probe"
mkdir -p "$PROBE_DIR"
printf 'int rg35xx_toolchain_probe(void) { return 0; }\n' > "$PROBE_DIR/probe.c"
"$CC" $TARGET_FLAGS -c "$PROBE_DIR/probe.c" -o "$PROBE_DIR/probe.o"
[ -s "$PROBE_DIR/probe.o" ] || fail "ARM compiler probe object missing"
"$READELF" -h "$PROBE_DIR/probe.o" | grep -Eq 'Machine:[[:space:]]+ARM' || fail "probe object is not ARM"

ENV_OUT="$RG35XX_TOOLCHAIN_ROOT/rg35xx_toolchain_env.sh"
cat > "$ENV_OUT" <<EOF
RG35XX_CC='$CC'
RG35XX_CXX='$CXX'
RG35XX_NM='$NM'
export RG35XX_CC RG35XX_CXX RG35XX_NM
EOF

MATERIALIZED_MANIFEST="$RG35XX_TOOLCHAIN_ROOT/rg35xx_toolchain_materialized_manifest.txt"
cat > "$MATERIALIZED_MANIFEST" <<EOF
PROVIDER=$PIN_PROVIDER
COMMIT=$PIN_COMMIT
DEFCONFIG=$PIN_DEFCONFIG
DEFCONFIG_GIT_BLOB=$PIN_DEFCONFIG_BLOB
SDK=$SDK_NAME
SDK_SHA256=$ACTUAL_SHA
SDK_SIZE=$ACTUAL_SIZE
TARGET_TRIPLE=$TRIPLE
CC=$CC
CXX=$CXX
NM=$NM
READELF=$READELF
CC_DUMPMACHINE=$CC_MACHINE
CXX_DUMPMACHINE=$CXX_MACHINE
TARGET_FLAGS=$TARGET_FLAGS
PROBE_OBJECT=$PROBE_DIR/probe.o
EOF

note "SDK MATERIALIZATION PASS"
note "Compiler: $CC"
note "C++ compiler: $CXX"
note "nm: $NM"
note "Environment: $ENV_OUT"
note "Manifest: $MATERIALIZED_MANIFEST"
note "No BUILD-PASS: source/ClassPath/Ant/native consolidated compile remains required."
