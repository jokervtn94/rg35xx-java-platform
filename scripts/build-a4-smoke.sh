#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
A3="$ROOT/out/a3"
BUILD="$ROOT/build/a4"
OUT="$ROOT/out/a4"
PKG="$OUT/SD/Roms/APPS/RG35XX-AWEIGIT-R1-A4-SMOKE"
APPS="$OUT/SD/Roms/APPS"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"

fail() { echo "A4_BUILD_FAIL=$*" >&2; exit 1; }

[ -f "$A3/freej2me-rg35xx.jar" ] || fail "A3 platform jar missing"
[ -f "$A3/librg35xx_input.so" ] || fail "A3 input native missing"
[ -f "$A3/librg35xx_video.so" ] || fail "A3 video native missing"
[ -f "$A3/BUILD-IDENTITY.txt" ] || fail "A3 BUILD-IDENTITY missing"
[ -f "$A3/CANONICAL-DIFF-MANIFEST.txt" ] || fail "A3 canonical diff manifest missing"
[ -f "$A3/JAVA6-COMPAT-AUDIT.tsv" ] || fail "A3 Java6 audit missing"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"

rm -rf "$BUILD" "$OUT"
mkdir -p "$BUILD/classes" "$PKG"

"$JAVA8/bin/javac" \
    -encoding UTF-8 \
    -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" \
    -classpath "$A3/freej2me-rg35xx.jar" \
    -d "$BUILD/classes" \
    "$ROOT/tests/a4/RG35XXA4SmokeMIDlet.java"

cat > "$BUILD/a4-smoke.mf" <<'MF'
Manifest-Version: 1.0
MIDlet-1: RG35XX A4 Smoke,,org.recompile.rg35xx.smoke.RG35XXA4SmokeMIDlet
MIDlet-Name: RG35XX A4 Smoke
MIDlet-Vendor: RG35XX-AWEIGIT-R1
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

"$JAVA8/bin/jar" cfm "$PKG/rg35xx-a4-smoke.jar" "$BUILD/a4-smoke.mf" -C "$BUILD/classes" .
cp "$A3/freej2me-rg35xx.jar" "$PKG/"
cp "$A3/librg35xx_input.so" "$PKG/"
cp "$A3/librg35xx_video.so" "$PKG/"
cp "$A3/BUILD-IDENTITY.txt" "$PKG/"
cp "$A3/CANONICAL-DIFF-MANIFEST.txt" "$PKG/"
cp "$A3/JAVA6-COMPAT-AUDIT.tsv" "$PKG/"
cp "$ROOT/packaging/a4/RG35XX-AWEIGIT-R1-A4-SMOKE.sh" "$APPS/"
chmod +x "$APPS/RG35XX-AWEIGIT-R1-A4-SMOKE.sh"

(
    cd "$PKG"
    sha256sum \
        freej2me-rg35xx.jar \
        librg35xx_input.so \
        librg35xx_video.so \
        rg35xx-a4-smoke.jar \
        BUILD-IDENTITY.txt \
        CANONICAL-DIFF-MANIFEST.txt \
        JAVA6-COMPAT-AUDIT.tsv > PAYLOAD-SHA256SUMS.txt
    sha256sum -c PAYLOAD-SHA256SUMS.txt
)

cp "$ROOT/packaging/a4/INSTALL-RG35XX-AWEIGIT-R1-A4.ps1" "$OUT/"
cp "$ROOT/packaging/a4/COLLECT-RG35XX-AWEIGIT-R1-A4.ps1" "$OUT/"
cp "$ROOT/packaging/a4/A4-TEST-INSTRUCTIONS.txt" "$OUT/"

ADAPTER_COMMIT="${GITHUB_SHA:-$(git rev-parse HEAD)}"
{
    echo 'PROJECT=RG35XX-AWEIGIT-R1'
    echo 'STAGE=A4-SMOKE'
    echo 'AWEIGIT_REPO=aweigit/freej2me-miyoomini'
    echo 'AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63'
    echo "ADAPTER_COMMIT=$ADAPTER_COMMIT"
    grep '^JAMVM_SHA256=' "$A3/BUILD-IDENTITY.txt"
    grep '^GLIBJ_SHA256=' "$A3/BUILD-IDENTITY.txt"
    echo "PLATFORM_JAR_SHA256=$(sha256sum "$PKG/freej2me-rg35xx.jar" | awk '{print $1}')"
    echo "INPUT_NATIVE_SHA256=$(sha256sum "$PKG/librg35xx_input.so" | awk '{print $1}')"
    echo "VIDEO_NATIVE_SHA256=$(sha256sum "$PKG/librg35xx_video.so" | awk '{print $1}')"
    echo "SMOKE_JAR_SHA256=$(sha256sum "$PKG/rg35xx-a4-smoke.jar" | awk '{print $1}')"
    echo "CANONICAL_DIFF_MANIFEST_SHA256=$(sha256sum "$PKG/CANONICAL-DIFF-MANIFEST.txt" | awk '{print $1}')"
    echo 'BUILD-PASS=YES'
    echo 'DEVICE-PASS=NO'
    echo 'DEVICE_PASS_REVIEW=PENDING'
    echo 'STABLE=NO'
} > "$OUT/A4-BUILD-IDENTITY.txt"

(
    cd "$OUT"
    find . -type f ! -name A4-PACKAGE-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > A4-PACKAGE-SHA256SUMS.txt
    sha256sum -c A4-PACKAGE-SHA256SUMS.txt
)

echo 'A4_BUILD_GATE=PASS'
cat "$OUT/A4-BUILD-IDENTITY.txt"
