#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
A3="$ROOT/out/a3"
BUILD="$ROOT/build/a5"
OUT="$ROOT/out/a5"
APPS="$OUT/SD/Roms/APPS"
PKG="$APPS/RG35XX-AWEIGIT-R1-A5-CORE"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"

fail() { echo "A5_BUILD_FAIL=$*" >&2; exit 1; }

[ -f "$A3/freej2me-rg35xx.jar" ] || fail "platform jar missing"
[ -f "$A3/librg35xx_input.so" ] || fail "input native missing"
[ -f "$A3/librg35xx_video.so" ] || fail "video native missing"
[ -f "$A3/BUILD-IDENTITY.txt" ] || fail "A3 identity missing"
[ -f "$A3/CANONICAL-DIFF-MANIFEST.txt" ] || fail "canonical manifest missing"
[ -f "$A3/JAVA6-COMPAT-AUDIT.tsv" ] || fail "compat audit missing"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"

rm -rf "$BUILD" "$OUT"
mkdir -p "$BUILD/classes" "$BUILD/resources" "$PKG"

"$JAVA8/bin/javac" \
    -encoding UTF-8 \
    -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" \
    -classpath "$A3/freej2me-rg35xx.jar" \
    -d "$BUILD/classes" \
    "$ROOT/tests/a5/RG35XXA5CoreIntegrationMIDlet.java"

cp "$ROOT/tests/a5/a5-resource.txt" "$BUILD/resources/a5-resource.txt"
python3 - "$BUILD/resources/a5-pixel.png" <<'PY'
import base64, pathlib, sys
# 1x1 opaque grayscale PNG. This is a deterministic resource-decoding probe.
b64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='
pathlib.Path(sys.argv[1]).write_bytes(base64.b64decode(b64))
PY

cat > "$BUILD/a5-core.mf" <<'MF'
Manifest-Version: 1.0
MIDlet-1: RG35XX A5 Core,,org.recompile.rg35xx.a5.RG35XXA5CoreIntegrationMIDlet
MIDlet-Name: RG35XX A5 Core Integration
MIDlet-Vendor: RG35XX-AWEIGIT-R1
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

"$JAVA8/bin/jar" cfm "$PKG/rg35xx-a5-core.jar" "$BUILD/a5-core.mf" -C "$BUILD/classes" . -C "$BUILD/resources" .
cp "$A3/freej2me-rg35xx.jar" "$PKG/"
cp "$A3/librg35xx_input.so" "$PKG/"
cp "$A3/librg35xx_video.so" "$PKG/"
cp "$A3/BUILD-IDENTITY.txt" "$PKG/"
cp "$A3/CANONICAL-DIFF-MANIFEST.txt" "$PKG/"
cp "$A3/JAVA6-COMPAT-AUDIT.tsv" "$PKG/"
cp "$ROOT/packaging/a5/RG35XX-AWEIGIT-R1-A5-CORE.sh" "$APPS/"
chmod +x "$APPS/RG35XX-AWEIGIT-R1-A5-CORE.sh"

python3 - "$PKG/rg35xx-a5-core.jar" <<'PY'
import sys, zipfile
p=sys.argv[1]
required={
 'org/recompile/rg35xx/a5/RG35XXA5CoreIntegrationMIDlet.class',
 'a5-resource.txt','a5-pixel.png'
}
with zipfile.ZipFile(p) as z:
    names=set(z.namelist())
    missing=required-names
    if missing: raise SystemExit('A5_JAR_GATE_FAIL missing='+repr(sorted(missing)))
    majors=[]
    for n in names:
        if n.endswith('.class'):
            b=z.read(n); majors.append(int.from_bytes(b[6:8],'big'))
    if not majors or max(majors)>50: raise SystemExit('A5_JAVA6_GATE_FAIL majors='+repr(sorted(set(majors))))
print('A5_JAVA6_GATE=PASS')
print('A5_RESOURCE_GATE=PASS')
PY

(
    cd "$PKG"
    sha256sum \
        freej2me-rg35xx.jar \
        librg35xx_input.so \
        librg35xx_video.so \
        rg35xx-a5-core.jar \
        BUILD-IDENTITY.txt \
        CANONICAL-DIFF-MANIFEST.txt \
        JAVA6-COMPAT-AUDIT.tsv > PAYLOAD-SHA256SUMS.txt
    sha256sum -c PAYLOAD-SHA256SUMS.txt
)

ADAPTER_COMMIT="${GITHUB_SHA:-$(git rev-parse HEAD)}"
{
    echo 'PROJECT=RG35XX-AWEIGIT-R1'
    echo 'STAGE=A5-CORE-INTEGRATION'
    echo 'AWEIGIT_REPO=aweigit/freej2me-miyoomini'
    echo 'AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63'
    echo "ADAPTER_COMMIT=$ADAPTER_COMMIT"
    grep '^JAMVM_SHA256=' "$A3/BUILD-IDENTITY.txt"
    grep '^GLIBJ_SHA256=' "$A3/BUILD-IDENTITY.txt"
    echo "PLATFORM_JAR_SHA256=$(sha256sum "$PKG/freej2me-rg35xx.jar" | awk '{print $1}')"
    echo "INPUT_NATIVE_SHA256=$(sha256sum "$PKG/librg35xx_input.so" | awk '{print $1}')"
    echo "VIDEO_NATIVE_SHA256=$(sha256sum "$PKG/librg35xx_video.so" | awk '{print $1}')"
    echo "CORE_JAR_SHA256=$(sha256sum "$PKG/rg35xx-a5-core.jar" | awk '{print $1}')"
    echo 'A5_LOGICAL_LCD=240x320'
    echo 'A5_PHYSICAL_LCD=640x480'
    echo 'A5_PARENT_SCOPE=RESIZE,RESOURCE,IMAGE,TRANSPARENCY,FONT_TEXT,SPRITE_8_TRANSFORMS,COLLISION,TILEDLAYER,LAYERMANAGER,RMS_PERSISTENCE'
    echo 'BUILD-PASS=YES'
    echo 'DEVICE-PASS=NO'
    echo 'DEVICE_PASS_REVIEW=PENDING'
    echo 'STABLE=NO'
} > "$OUT/A5-BUILD-IDENTITY.txt"

if [ -d "$ROOT/packaging/a5/windows" ]; then
    cp "$ROOT/packaging/a5/windows/"* "$OUT/"
fi
if [ -f "$ROOT/packaging/a5/A5-TEST-INSTRUCTIONS.txt" ]; then
    cp "$ROOT/packaging/a5/A5-TEST-INSTRUCTIONS.txt" "$OUT/"
fi

(
    cd "$OUT"
    find . -type f ! -name A5-PACKAGE-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > A5-PACKAGE-SHA256SUMS.txt
    sha256sum -c A5-PACKAGE-SHA256SUMS.txt
)

echo 'A5_BUILD_GATE=PASS'
cat "$OUT/A5-BUILD-IDENTITY.txt"
