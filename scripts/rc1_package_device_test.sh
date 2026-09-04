#!/bin/sh
set -eu

# RGJ-RC1-011BH / RGJ-RC1-011BI
# Host-side deterministic staging for real RG35XX validation.
# Exact core/JAR/device paths are locked from prior real-device logs.
# This script never marks DEVICE-TEST-PASS.

CORE_FILE=${CORE_FILE:-}
JAR_FILE=${JAR_FILE:-}
FONT_FILE=${FONT_FILE:-}
SOUNDFONT_FILE=${SOUNDFONT_FILE:-}
OUT=${OUT:-./rg35xx-java-rc1-device-test}
MAKE_ZIP=${MAKE_ZIP:-0}

CORE_SHA256=3e416345711891f7edeb4fe04bba82acc674b3c27f50863255376053a3974d58
JAR_SHA256=f9b96e4490a154b3d58632bf482e0ad9d324a264bd82c8c5bf3a81186a2cfe4b
FONT_SHA256=7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954
SOUNDFONT_SHA256=9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe
BUILD_COMMIT=086d4987c0d60b5eb9abc3887e73638b24a1b964
BUILD_RUN=33883673553
BUILD_ARTIFACT=9940954185
BUILD_ARTIFACT_SHA256=e2f3e70634026a1916f9cd75af5875b32c087fdae9622349d9f18afad943b630

fail() { echo "RC1 PACKAGE: ERROR: $*" >&2; exit 1; }
need_file() { [ -n "$1" ] || fail "$2 is not set"; [ -f "$1" ] || fail "$2 missing: $1"; }

have_sha256()
{
  command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required on the host"
}

verify_sha()
{
  file=$1
  expected=$2
  label=$3
  actual=$(sha256sum "$file" | awk '{print $1}')
  [ "$actual" = "$expected" ] || fail "$label SHA256 mismatch: got $actual expected $expected"
  echo "RC1 PACKAGE: $label SHA256 PASS: $actual"
}

need_file "$CORE_FILE" CORE_FILE
need_file "$JAR_FILE" JAR_FILE
need_file "$FONT_FILE" FONT_FILE
need_file "$SOUNDFONT_FILE" SOUNDFONT_FILE
need_file "scripts/rc1_device_evidence.sh" device-evidence-script
need_file "scripts/rc1_install_device.sh" device-installer-script
need_file "docs/RC1-DEVICE-VALIDATION.md" device-validation-doc
have_sha256

verify_sha "$CORE_FILE" "$CORE_SHA256" core
verify_sha "$JAR_FILE" "$JAR_SHA256" jar
verify_sha "$FONT_FILE" "$FONT_SHA256" font
verify_sha "$SOUNDFONT_FILE" "$SOUNDFONT_SHA256" soundfont

rm -rf "$OUT"
mkdir -p "$OUT/core" "$OUT/java" "$OUT/Java/runtime" "$OUT/tools" "$OUT/docs"

cp "$CORE_FILE" "$OUT/core/freej2me_plus_libretro.so"
cp "$JAR_FILE" "$OUT/java/freej2me_plus-lr.jar"
cp "$FONT_FILE" "$OUT/Java/runtime/DejaVuSans.ttf"
cp "$SOUNDFONT_FILE" "$OUT/Java/runtime/GeneralUser-GS.sf2"
cp scripts/rc1_device_evidence.sh "$OUT/tools/rc1_device_evidence.sh"
cp scripts/rc1_install_device.sh "$OUT/tools/rc1_install_device.sh"
cp docs/RC1-DEVICE-VALIDATION.md "$OUT/docs/RC1-DEVICE-VALIDATION.md"
chmod +x "$OUT/tools/rc1_device_evidence.sh" "$OUT/tools/rc1_install_device.sh" 2>/dev/null || true

cat > "$OUT/BUILD-IDENTITY.txt" <<EOF
RG35XX Java Platform RC1 device-validation package
build_commit=$BUILD_COMMIT
build_run=$BUILD_RUN
build_artifact=$BUILD_ARTIFACT
build_artifact_sha256=$BUILD_ARTIFACT_SHA256
core_sha256=$CORE_SHA256
jar_sha256=$JAR_SHA256
font_sha256=$FONT_SHA256
soundfont_sha256=$SOUNDFONT_SHA256
EOF

cat > "$OUT/INSTALL-MAP.txt" <<'EOF'
Exact paths proven by prior real-device logs for this RG35XX installation:
  core/freej2me_plus_libretro.so      -> /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so
  java/freej2me_plus-lr.jar           -> /mnt/mmc/BIOS/freej2me-lr.jar
  Java/runtime/DejaVuSans.ttf         -> /mnt/mmc/Java/runtime/DejaVuSans.ttf
  Java/runtime/GeneralUser-GS.sf2     -> /mnt/mmc/Java/runtime/GeneralUser-GS.sf2

Existing runtime/frontend paths confirmed by the same device logs:
  RetroArch                           = /mnt/mmc/CFW/retroarch/retroarch
  JamVM                               = /mnt/mmc/CFW/java/bin/jamvm
  Java games                          = /mnt/mmc/Roms/JAVA

Device install command from the package root:
  sh tools/rc1_install_device.sh

The installer verifies all four accepted payload SHA256 values, preserves one `.pre-rc1` backup for each existing deployed payload, stages through `.rc1-new`, verifies again, and replaces only these four files. It does not alter RetroArch configuration, firmware, launcher files, or game JARs.
EOF

(
  cd "$OUT"
  find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort | while IFS= read -r f; do
    sha256sum "$f"
  done > SHA256SUMS
)

if [ "$MAKE_ZIP" = "1" ]; then
  command -v zip >/dev/null 2>&1 || fail "MAKE_ZIP=1 but zip is unavailable"
  parent=$(dirname "$OUT")
  base=$(basename "$OUT")
  (cd "$parent" && rm -f "$base.zip" && zip -qr "$base.zip" "$base")
  echo "RC1 PACKAGE: zip created: $OUT.zip"
fi

echo "RC1 PACKAGE: PASS: $OUT"
echo "RC1 PACKAGE: exact RG35XX install map included"
echo "RC1 PACKAGE: this package is for manual real-device validation only; DEVICE-TEST-PASS is not implied."
