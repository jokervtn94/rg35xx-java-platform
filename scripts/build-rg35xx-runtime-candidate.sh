#!/usr/bin/env bash
set -euo pipefail

# Build an isolated JamVM + GNU Classpath runtime candidate for the original
# RG35XX.  This script never installs into /mnt/mmc/CFW/java and never changes
# the accepted runtime.  The output is deliberately a diagnostic candidate.

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD="${BUILD_DIR:-$ROOT/build/rg35xx-runtime-candidate}"
OUT="${OUT_DIR:-$ROOT/out/rg35xx-runtime-candidate}"
CACHE="${RUNTIME_SOURCE_CACHE:-$ROOT/../artifacts/runtime-sources}"
TARGET="${TARGET:-arm-miyoo-linux-uclibcgnueabi}"
RUNTIME_DEVICE_ROOT="${RUNTIME_DEVICE_ROOT:-/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime}"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-/opt/miyoo}"
JAMVM_URL="${JAMVM_URL:-https://codeload.github.com/xranby/jamvm/tar.gz/master}"
CLASSPATH_URL="${CLASSPATH_URL:-https://ftp.gnu.org/gnu/classpath/classpath-0.99.tar.gz}"
JAMVM_SHA256="297c14d255f8c88534790818e00276ff97542c1d02d47d7f546537d8fa164491"
CLASSPATH_SHA256="f929297f8ae9b613a1a167e231566861893260651d913ad9b6c11933895fecc8"
TOOLCHAIN_IMAGE="docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e"

fail() { echo "RUNTIME_CANDIDATE_BUILD=FAIL:$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "missing tool: $1"; }

need awk
need curl
need find
need make
need sha256sum
need tar
need zip
need autoconf
need autoheader
need automake
need aclocal
need libtoolize

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME is required; use JDK 8"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing: $JAVA8/bin/javac"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing: $JAVA8/bin/jar"
"$JAVA8/bin/javac" -version 2>&1 | grep -Eq 'javac 1\.8([._]|$)' || fail "JDK 8 is required"

CC="${CC:-$TOOLCHAIN_ROOT/bin/${TARGET}-gcc}"
CXX="${CXX:-$TOOLCHAIN_ROOT/bin/${TARGET}-g++}"
AR="${AR:-$TOOLCHAIN_ROOT/bin/${TARGET}-ar}"
RANLIB="${RANLIB:-$TOOLCHAIN_ROOT/bin/${TARGET}-ranlib}"
STRIP="${STRIP:-$TOOLCHAIN_ROOT/bin/${TARGET}-strip}"
READELF="${READELF:-$TOOLCHAIN_ROOT/bin/${TARGET}-readelf}"
for tool in "$CC" "$CXX" "$AR" "$RANLIB" "$STRIP" "$READELF"; do
  [ -x "$tool" ] || fail "cross-tool missing: $tool"
done
export CC CXX AR RANLIB STRIP READELF

mkdir -p "$CACHE" "$BUILD" "$OUT"

fetch_checked() {
  local url="$1" dst="$2" expected="$3"
  if [ ! -f "$dst" ]; then
    echo "Downloading $url"
    curl -L --fail --retry 3 --retry-delay 2 -o "$dst" "$url"
  fi
  local actual
  actual="$(sha256sum "$dst" | awk '{print tolower($1)}')"
  [ "$actual" = "$expected" ] || fail "source hash mismatch for $dst: $actual"
}

JAMVM_TARBALL="$CACHE/jamvm-2.0.0.tar.gz"
CLASSPATH_TARBALL="$CACHE/classpath-0.99.tar.gz"
fetch_checked "$JAMVM_URL" "$JAMVM_TARBALL" "$JAMVM_SHA256"
fetch_checked "$CLASSPATH_URL" "$CLASSPATH_TARBALL" "$CLASSPATH_SHA256"

rm -rf "$BUILD/source" "$BUILD/classpath-build" "$BUILD/jamvm-build" "$BUILD/stage"
mkdir -p "$BUILD/source" "$BUILD/classpath-build" "$BUILD/jamvm-build" "$BUILD/stage" "$OUT"
tar -xzf "$JAMVM_TARBALL" -C "$BUILD/source"
tar -xzf "$CLASSPATH_TARBALL" -C "$BUILD/source"

JAMVM_SRC="$(find "$BUILD/source" -mindepth 1 -maxdepth 1 -type d -name 'jamvm-*' | head -n 1)"
CLASSPATH_SRC="$(find "$BUILD/source" -mindepth 1 -maxdepth 1 -type d -name 'classpath-*' | head -n 1)"
[ -n "$JAMVM_SRC" ] || fail "JamVM source directory not found"
[ -n "$CLASSPATH_SRC" ] || fail "GNU Classpath source directory not found"

# The pinned JamVM GitHub source archive is generated from the repository and
# intentionally does not carry a pre-generated configure script.  Regenerate
# it inside the disposable build tree before the cross configure step.
(
  cd "$JAMVM_SRC"
  NOCONFIGURE=yes ./autogen.sh
)

# The device image is soft-float ARM/uClibc.  Keep all compile flags explicit
# so a host-default hard-float or ARMv7 build cannot silently pass this stage.
COMMON_CFLAGS="-Os -pipe -fno-strict-aliasing -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft"
COMMON_CPPFLAGS="-D_GNU_SOURCE"
COMMON_LDFLAGS="-Wl,--as-needed"
export PATH="$JAVA8/bin:$PATH"

echo "== GNU Classpath 0.99 =="
(
  cd "$BUILD/classpath-build"
  CC="$CC" CXX="$CXX" AR="$AR" RANLIB="$RANLIB" STRIP="$STRIP" \
  GCJ_JAVAC_TRUE="#" GCJ_JAVAC_FALSE= \
  CFLAGS="$COMMON_CFLAGS" CPPFLAGS="$COMMON_CPPFLAGS" LDFLAGS="$COMMON_LDFLAGS" \
  JAVAC="$JAVA8/bin/javac" \
  "$CLASSPATH_SRC/configure" \
    --build=x86_64-pc-linux-gnu \
    --host="$TARGET" \
    --prefix="$RUNTIME_DEVICE_ROOT" \
    --libdir="$RUNTIME_DEVICE_ROOT/lib" \
    --with-glibj-dir="$RUNTIME_DEVICE_ROOT/share/classpath" \
    --with-native-libdir="$RUNTIME_DEVICE_ROOT/lib/classpath" \
    --with-glibj=zip \
    --disable-gtk-peer \
    --disable-gconf-peer \
    --disable-alsa \
    --disable-dssi \
    --disable-plugin \
    --disable-gmp \
    --disable-gjdoc \
    --disable-examples \
    --disable-tools \
    --disable-tool-wrappers \
    --disable-Werror
  make -j"${JOBS:-2}"
  make DESTDIR="$BUILD/stage" install
)

echo "== JamVM 2.0.0 =="
STAGED_RUNTIME="$BUILD/stage$RUNTIME_DEVICE_ROOT"
[ -f "$STAGED_RUNTIME/share/classpath/glibj.zip" ] || fail "staged glibj.zip missing before JamVM build"
(
  cd "$BUILD/jamvm-build"
  CC="$CC" AR="$AR" RANLIB="$RANLIB" \
  CFLAGS="$COMMON_CFLAGS" CPPFLAGS="$COMMON_CPPFLAGS" LDFLAGS="$COMMON_LDFLAGS" \
  "$JAMVM_SRC/configure" \
    --build=x86_64-pc-linux-gnu \
    --host="$TARGET" \
    --prefix="$RUNTIME_DEVICE_ROOT" \
    --with-java-runtime-library=gnuclasspath \
    --with-classpath-install-dir="$RUNTIME_DEVICE_ROOT" \
    --disable-ffi \
    --enable-zip

  # JamVM's GNU Classpath helper classes are compiled on the host runner.
  # Keep the device path in configure/config.h, but use the staged glibj.zip
  # as javac's bootclasspath during this build.
  JAMVM_GNUCP_MAKEFILE="$BUILD/jamvm-build/src/classlib/gnuclasspath/lib/Makefile"
  [ -f "$JAMVM_GNUCP_MAKEFILE" ] || fail "JamVM GNU Classpath Makefile missing"
  sed -i "s|^CP_LIB_DIR = .*|CP_LIB_DIR = $STAGED_RUNTIME/share/classpath|" "$JAMVM_GNUCP_MAKEFILE"
  make -j"${JOBS:-2}"
  make DESTDIR="$BUILD/stage" install
)

[ -x "$STAGED_RUNTIME/bin/jamvm" ] || fail "staged jamvm missing"
[ -f "$STAGED_RUNTIME/share/classpath/glibj.zip" ] || fail "staged glibj.zip missing"

rm -rf "$OUT/runtime"
mkdir -p "$OUT/runtime/bin" "$OUT/runtime/share/classpath" "$OUT/runtime/lib"
cp -a "$STAGED_RUNTIME/bin/jamvm" "$OUT/runtime/bin/jamvm"
cp -a "$STAGED_RUNTIME/share/classpath/glibj.zip" "$OUT/runtime/share/classpath/glibj.zip"
if [ -d "$STAGED_RUNTIME/lib/classpath" ]; then
  cp -a "$STAGED_RUNTIME/lib/classpath" "$OUT/runtime/lib/"
fi
if [ -d "$STAGED_RUNTIME/lib" ]; then
  find "$STAGED_RUNTIME/lib" -maxdepth 1 -type f -name '*.so*' -exec cp -a {} "$OUT/runtime/lib/" \;
fi
chmod 0755 "$OUT/runtime/bin/jamvm"

"$READELF" -h "$OUT/runtime/bin/jamvm" > "$OUT/jamvm.readelf.txt"
"$READELF" -A "$OUT/runtime/bin/jamvm" > "$OUT/jamvm.attributes.txt" || true
cat "$OUT/jamvm.attributes.txt"
grep -q 'Class:.*ELF32' "$OUT/jamvm.readelf.txt" || fail "JamVM is not ELF32"
grep -q 'Machine:.*ARM' "$OUT/jamvm.readelf.txt" || fail "JamVM is not ARM"
grep -q 'Version5 EABI' "$OUT/jamvm.readelf.txt" || fail "JamVM is not EABI5"
if grep -Eq 'Tag_ABI_VFP_args:.*VFP registers|Tag_ABI_HardFP_use:[[:space:]]*[1-9]' "$OUT/jamvm.attributes.txt"; then
  fail "JamVM is hard-float ABI"
fi
if grep -Eq 'Tag_ABI_VFP_args:.*Base AAPCS' "$OUT/jamvm.attributes.txt"; then
  echo "ABI_SOFT_FLOAT=EXPLICIT_BASE_AAPCS"
else
  echo "ABI_SOFT_FLOAT=NO_HARD_FLOAT_MARKERS"
fi

JAMVM_OUT_SHA="$(sha256sum "$OUT/runtime/bin/jamvm" | awk '{print tolower($1)}')"
GLIBJ_OUT_SHA="$(sha256sum "$OUT/runtime/share/classpath/glibj.zip" | awk '{print tolower($1)}')"
cat > "$OUT/RUNTIME-CANDIDATE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
MODE=ALTERNATIVE_RUNTIME_REBUILD_DIAGNOSTIC_ONLY
BASE=MIYOO_AWEIGIT_PLATFORM
RUNTIME_OWNER=JAMVM_2.0.0_PLUS_GNU_CLASSPATH_0.99
DEVICE=ORIGINAL_RG35XX_GARLICOS
RUNTIME_PROTECTED_PATH_MUTATION=NO
DEVICE_PASS=NO
STABLE=NO
TOOLCHAIN_IMAGE=$TOOLCHAIN_IMAGE
TARGET=$TARGET
RUNTIME_DEVICE_ROOT=$RUNTIME_DEVICE_ROOT
JAMVM_SOURCE_URL=$JAMVM_URL
JAMVM_SOURCE_SHA256=$JAMVM_SHA256
CLASSPATH_SOURCE_URL=$CLASSPATH_URL
CLASSPATH_SOURCE_SHA256=$CLASSPATH_SHA256
CANDIDATE_JAMVM_SHA256=$JAMVM_OUT_SHA
CANDIDATE_GLIBJ_SHA256=$GLIBJ_OUT_SHA
ABI_GATE=PASS
BUILD=PASS
PHYSICAL_TEST=NOT_TESTED
EOF

rm -f "$OUT/RG35XX-RUNTIME-CANDIDATE-REBUILD.zip"
(cd "$OUT" && zip -qr "RG35XX-RUNTIME-CANDIDATE-REBUILD.zip" runtime RUNTIME-CANDIDATE-IDENTITY.txt jamvm.readelf.txt jamvm.attributes.txt)
echo "RUNTIME_CANDIDATE_BUILD=PASS"
echo "RUNTIME_CANDIDATE_ZIP=$OUT/RG35XX-RUNTIME-CANDIDATE-REBUILD.zip"
