#!/bin/sh
set -eu

# RGJ-RC1-011S — source-pinned ARM/uClibc SDK acquisition.
# This builds the SDK from the exact MiyooCFW/buildroot source pin; it does not
# install the SDK or invoke the RC1 Java/native compile harness.

PIN_REPO="https://github.com/MiyooCFW/buildroot.git"
PIN_COMMIT="8087b52311da5c1e2fa1c50b0b064c07fd174a36"
PIN_DEFCONFIG="configs/miyoo_uclibc_defconfig"
PIN_DEFCONFIG_BLOB="58256d3e7afa3f9fa0dbd79b16fd0b21d93b9d7b"
SDK_NAME="arm-miyoo-linux-uclibcgnueabi_sdk-buildroot.tar.gz"
TRIPLE="arm-miyoo-linux-uclibcgnueabi"

: "${RG35XX_TOOLCHAIN_SOURCE_ROOT:?set RG35XX_TOOLCHAIN_SOURCE_ROOT to a disposable MiyooCFW/buildroot checkout path}"
: "${RG35XX_TOOLCHAIN_OUTPUT_DIR:?set RG35XX_TOOLCHAIN_OUTPUT_DIR to the directory that will receive the verified SDK archive}"
JOBS="${RG35XX_TOOLCHAIN_JOBS:-1}"

fail() { echo "RC1 TOOLCHAIN: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 TOOLCHAIN: $*"; }

command -v git >/dev/null 2>&1 || fail "git not found"
command -v make >/dev/null 2>&1 || fail "make not found"
command -v tar >/dev/null 2>&1 || fail "tar not found"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum not found"

case "$JOBS" in ''|*[!0-9]*) fail "RG35XX_TOOLCHAIN_JOBS must be a positive integer" ;; esac
[ "$JOBS" -ge 1 ] || fail "RG35XX_TOOLCHAIN_JOBS must be >= 1"

if [ -e "$RG35XX_TOOLCHAIN_SOURCE_ROOT" ] && [ ! -d "$RG35XX_TOOLCHAIN_SOURCE_ROOT/.git" ]; then
  fail "source root exists but is not a Git checkout: $RG35XX_TOOLCHAIN_SOURCE_ROOT"
fi

if [ ! -d "$RG35XX_TOOLCHAIN_SOURCE_ROOT/.git" ]; then
  mkdir -p "$RG35XX_TOOLCHAIN_SOURCE_ROOT"
  git -C "$RG35XX_TOOLCHAIN_SOURCE_ROOT" init
  git -C "$RG35XX_TOOLCHAIN_SOURCE_ROOT" remote add origin "$PIN_REPO"
fi

REMOTE=$(git -C "$RG35XX_TOOLCHAIN_SOURCE_ROOT" remote get-url origin 2>/dev/null || true)
[ "$REMOTE" = "$PIN_REPO" ] || fail "unexpected origin: $REMOTE"

git -C "$RG35XX_TOOLCHAIN_SOURCE_ROOT" fetch --depth=1 origin "$PIN_COMMIT"
git -C "$RG35XX_TOOLCHAIN_SOURCE_ROOT" checkout --detach --force FETCH_HEAD
HEAD=$(git -C "$RG35XX_TOOLCHAIN_SOURCE_ROOT" rev-parse HEAD)
[ "$HEAD" = "$PIN_COMMIT" ] || fail "Buildroot HEAD $HEAD != pinned $PIN_COMMIT"

DEFCONFIG="$RG35XX_TOOLCHAIN_SOURCE_ROOT/$PIN_DEFCONFIG"
[ -f "$DEFCONFIG" ] || fail "pinned defconfig missing: $PIN_DEFCONFIG"
DEFCONFIG_BLOB=$(git -C "$RG35XX_TOOLCHAIN_SOURCE_ROOT" hash-object "$PIN_DEFCONFIG")
[ "$DEFCONFIG_BLOB" = "$PIN_DEFCONFIG_BLOB" ] || fail "defconfig blob $DEFCONFIG_BLOB != pinned $PIN_DEFCONFIG_BLOB"

grep -Fxq 'BR2_arm=y' "$DEFCONFIG" || fail "ARM target missing from defconfig"
grep -Fxq 'BR2_TOOLCHAIN_BUILDROOT_VENDOR="miyoo"' "$DEFCONFIG" || fail "Miyoo vendor triplet owner missing"
grep -Fxq 'BR2_GCC_VERSION_9_X=y' "$DEFCONFIG" || fail "expected GCC 9.x toolchain config missing"
grep -Fxq 'BR2_TOOLCHAIN_BUILDROOT_CXX=y' "$DEFCONFIG" || fail "C++ support missing"
grep -Fxq 'BR2_TARGET_OPTIMIZATION="-mcpu=arm926ej-s -marm"' "$DEFCONFIG" || fail "ARM926/marm optimization baseline changed"

note "Configuring exact MiyooCFW uClibc SDK source"
(
  cd "$RG35XX_TOOLCHAIN_SOURCE_ROOT"
  make miyoo_uclibc_defconfig
)
CONFIG="$RG35XX_TOOLCHAIN_SOURCE_ROOT/.config"
[ -f "$CONFIG" ] || fail "Buildroot .config was not generated"
grep -Fxq 'BR2_TOOLCHAIN_BUILDROOT_UCLIBC=y' "$CONFIG" || fail "resolved Buildroot configuration is not uClibc"
grep -Fxq 'BR2_TOOLCHAIN_BUILDROOT_VENDOR="miyoo"' "$CONFIG" || fail "resolved vendor changed"
grep -Fxq 'BR2_TOOLCHAIN_BUILDROOT_CXX=y' "$CONFIG" || fail "resolved C++ support changed"

note "Building source-pinned SDK with make -j$JOBS sdk"
(
  cd "$RG35XX_TOOLCHAIN_SOURCE_ROOT"
  make -j"$JOBS" sdk
)

SDK_SOURCE="$RG35XX_TOOLCHAIN_SOURCE_ROOT/output/images/$SDK_NAME"
[ -s "$SDK_SOURCE" ] || fail "expected SDK archive missing: $SDK_SOURCE"
if ! tar -tzf "$SDK_SOURCE" | grep -Eq "/bin/${TRIPLE}-gcc$"; then
  fail "SDK archive does not contain ${TRIPLE}-gcc"
fi
if ! tar -tzf "$SDK_SOURCE" | grep -Eq "/bin/${TRIPLE}-g\+\+$"; then
  fail "SDK archive does not contain ${TRIPLE}-g++"
fi

mkdir -p "$RG35XX_TOOLCHAIN_OUTPUT_DIR"
SDK_OUT="$RG35XX_TOOLCHAIN_OUTPUT_DIR/$SDK_NAME"
cp "$SDK_SOURCE" "$SDK_OUT"
SDK_SHA256=$(sha256sum "$SDK_OUT" | awk '{print $1}')
SDK_SIZE=$(wc -c < "$SDK_OUT" | tr -d ' ')

MANIFEST="$RG35XX_TOOLCHAIN_OUTPUT_DIR/rg35xx_toolchain_source_manifest.txt"
cat > "$MANIFEST" <<EOF
PROVIDER=MiyooCFW/buildroot
COMMIT=$PIN_COMMIT
DEFCONFIG=$PIN_DEFCONFIG
DEFCONFIG_GIT_BLOB=$PIN_DEFCONFIG_BLOB
SDK=$SDK_NAME
SDK_SHA256=$SDK_SHA256
SDK_SIZE=$SDK_SIZE
TARGET_TRIPLE=$TRIPLE
EOF

note "SDK SOURCE BUILD PASS"
note "SDK: $SDK_OUT"
note "SHA256: $SDK_SHA256"
note "Manifest: $MANIFEST"
note "No BUILD-PASS: extract/relocate the SDK, then run compiler target/JNI/ClassPath/Ant/native compile gates."
