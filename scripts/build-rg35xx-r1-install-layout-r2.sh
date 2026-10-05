#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "R1_LAYOUT_R2_BUILD_FAIL=$*" >&2; exit 1; }

R1ZIP="${R1_DEVICE_ZIP:-}"
[ -f "$R1ZIP" ] || fail R1_DEVICE_ZIP_MISSING
for t in unzip zip sha256sum awk grep sed cp chmod find; do command -v "$t" >/dev/null 2>&1 || fail "$t missing"; done

EXPECTED_R1=d79f416538a32e43c8c4b666658a50dd367a176f712bbe6c74809833a9201d9b
EXPECTED_JAMVM=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
EXPECTED_GLIBJ=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
EXPECTED_CLASSES=ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86
EXPECTED_PLATFORM=b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117
EXPECTED_INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_FONT_NATIVE=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_FONT=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10

[ "$(sha256sum "$R1ZIP"|awk '{print $1}')" = "$EXPECTED_R1" ] || fail R1_PARENT_HASH
OUT="$ROOT/out/r1-install-layout-r2"
WORK="$ROOT/build/r1-install-layout-r2"
rm -rf "$OUT" "$WORK"
mkdir -p "$OUT" "$WORK"
unzip -q "$R1ZIP" -d "$WORK"
BASE="$(find "$WORK" -type d -name RG35XX-MIYOO-FULL-PORT-R1 -print -quit)"
[ -n "$BASE" ] || fail R1_ROOT_NOT_FOUND
SD="$BASE/SD"
APPS="$SD/Roms/APPS"
APP="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
[ -d "$RUNTIME" ] || fail PARENT_RUNTIME_MISSING

hash_eq(){ [ -f "$1" ] || fail "MISSING:$1"; [ "$(sha256sum "$1"|awk '{print $1}')" = "$2" ] || fail "HASH:$1"; }
hash_eq "$RUNTIME/bin/jamvm" "$EXPECTED_JAMVM"
hash_eq "$RUNTIME/share/classpath/glibj.zip" "$EXPECTED_GLIBJ"
hash_eq "$RUNTIME/share/jamvm/classes.zip" "$EXPECTED_CLASSES"
hash_eq "$APP/freej2me-rg35xx.jar" "$EXPECTED_PLATFORM"
hash_eq "$APP/librg35xx_input.so" "$EXPECTED_INPUT"
hash_eq "$APP/librg35xx_video.so" "$EXPECTED_VIDEO"
hash_eq "$APP/librg35xx_font.so" "$EXPECTED_FONT_NATIVE"
hash_eq "$APP/libaudio.so" "$EXPECTED_AUDIO"
hash_eq "$APP/font.ttf" "$EXPECTED_FONT"

# Install-layout-only delta: keep an exact byte copy under the main app payload.
BOOT_SRC="$APP/bootstrap-runtime"
rm -rf "$BOOT_SRC"
mkdir -p "$BOOT_SRC"
cp -R "$RUNTIME/." "$BOOT_SRC/"
chmod 0755 "$BOOT_SRC/bin/jamvm"
hash_eq "$BOOT_SRC/bin/jamvm" "$EXPECTED_JAMVM"
hash_eq "$BOOT_SRC/share/classpath/glibj.zip" "$EXPECTED_GLIBJ"
hash_eq "$BOOT_SRC/share/jamvm/classes.zip" "$EXPECTED_CLASSES"

cat > "$APPS/RG35XX-R1-RUNTIME-BOOTSTRAP.sh" <<'EOF_BOOT'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
APP="$APPS/FreeJ2ME-RG35XX"
SRC="$APP/bootstrap-runtime"
DST="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
LOG="${RG35XX_R1_BOOTSTRAP_LOG:-/mnt/mmc/RG35XX-R1-RUNTIME-BOOTSTRAP.log}"
EXPECTED_JAMVM=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
EXPECTED_GLIBJ=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
EXPECTED_CLASSES=ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86
say(){ echo "$1" >>"$LOG"; }
sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
ok(){ [ -f "$DST/bin/jamvm" ] && [ "$(sha "$DST/bin/jamvm")" = "$EXPECTED_JAMVM" ] && [ -f "$DST/share/classpath/glibj.zip" ] && [ "$(sha "$DST/share/classpath/glibj.zip")" = "$EXPECTED_GLIBJ" ] && [ -f "$DST/share/jamvm/classes.zip" ] && [ "$(sha "$DST/share/jamvm/classes.zip")" = "$EXPECTED_CLASSES" ]; }
: >"$LOG"
if ok; then say R1_RUNTIME_BOOTSTRAP=PASS:EXISTING_EXACT; exit 0; fi
[ -f "$SRC/bin/jamvm" ] || { say R1_RUNTIME_BOOTSTRAP=FAIL:SOURCE_JAMVM_MISSING; exit 20; }
[ "$(sha "$SRC/bin/jamvm")" = "$EXPECTED_JAMVM" ] || { say R1_RUNTIME_BOOTSTRAP=FAIL:SOURCE_JAMVM_HASH; exit 20; }
[ "$(sha "$SRC/share/classpath/glibj.zip")" = "$EXPECTED_GLIBJ" ] || { say R1_RUNTIME_BOOTSTRAP=FAIL:SOURCE_GLIBJ_HASH; exit 20; }
[ "$(sha "$SRC/share/jamvm/classes.zip")" = "$EXPECTED_CLASSES" ] || { say R1_RUNTIME_BOOTSTRAP=FAIL:SOURCE_CLASSES_HASH; exit 20; }
rm -rf "$DST"
mkdir -p "$DST" || { say R1_RUNTIME_BOOTSTRAP=FAIL:MKDIR; exit 20; }
cp -R "$SRC/." "$DST/" || { say R1_RUNTIME_BOOTSTRAP=FAIL:COPY; exit 20; }
chmod 0755 "$DST/bin/jamvm" 2>/dev/null || true
if ok; then say R1_RUNTIME_BOOTSTRAP=PASS:MATERIALIZED_EXACT; exit 0; fi
say R1_RUNTIME_BOOTSTRAP=FAIL:POST_COPY_HASH
exit 20
EOF_BOOT
chmod +x "$APPS/RG35XX-R1-RUNTIME-BOOTSTRAP.sh"

inject_bootstrap(){
  local f="$1" marker="$2"
  [ -f "$f" ] || fail "launcher missing:$f"
  python3 - "$f" "$marker" <<'PY'
import sys
p, marker=sys.argv[1:]
s=open(p,'r',encoding='utf-8').read()
if 'RG35XX-R1-RUNTIME-BOOTSTRAP.sh' in s:
    raise SystemExit(0)
needle=marker+'\n'
if needle not in s:
    raise SystemExit('marker not found: '+marker)
block=needle+'BOOTSTRAP="$APPS/RG35XX-R1-RUNTIME-BOOTSTRAP.sh"\n[ -x "$BOOTSTRAP" ] || { echo "R1_RUNTIME_BOOTSTRAP=FAIL:SCRIPT_MISSING"; exit 20; }\nRG35XX_R1_BOOTSTRAP_LOG="${RG35XX_R1_BOOTSTRAP_LOG:-/mnt/mmc/RG35XX-R1-RUNTIME-BOOTSTRAP.log}" "$BOOTSTRAP" || exit $?\n'
s=s.replace(needle,block,1)
open(p,'w',encoding='utf-8').write(s)
PY
}
# All three launchers define APPS immediately after shebang.
inject_bootstrap "$APPS/FreeJ2ME-RG35XX.sh" 'APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"'
inject_bootstrap "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" 'APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"'
if [ -f "$APPS/RG35XX-R1-P7-TIER0.sh" ]; then
  inject_bootstrap "$APPS/RG35XX-R1-P7-TIER0.sh" 'APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"'
fi
chmod +x "$APPS/FreeJ2ME-RG35XX.sh" "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" "$APPS/RG35XX-R1-RUNTIME-BOOTSTRAP.sh"
[ ! -f "$APPS/RG35XX-R1-P7-TIER0.sh" ] || chmod +x "$APPS/RG35XX-R1-P7-TIER0.sh"

cat > "$BASE/INSTALL-LAYOUT-R2-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
SCOPE=INSTALL_LAYOUT_BOUNDARY_ONLY
PARENT_R1_DEVICE_ZIP_SHA256=$EXPECTED_R1
RUNTIME_SEMANTIC_DELTA=NONE
PLATFORM_SEMANTIC_DELTA=NONE
JAMVM_SHA256=$EXPECTED_JAMVM
GLIBJ_SHA256=$EXPECTED_GLIBJ
CLASSES_SHA256=$EXPECTED_CLASSES
PLATFORM_SHA256=$EXPECTED_PLATFORM
INPUT_SHA256=$EXPECTED_INPUT
VIDEO_SHA256=$EXPECTED_VIDEO
FONT_NATIVE_SHA256=$EXPECTED_FONT_NATIVE
AUDIO_SHA256=$EXPECTED_AUDIO
FONT_SHA256=$EXPECTED_FONT
BOOTSTRAP_SOURCE=Roms/APPS/FreeJ2ME-RG35XX/bootstrap-runtime
BOOTSTRAP_TARGET=Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime
P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
P7_PHYSICAL_REGRESSION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_ID

# Rebuild package checksums for modified main app payload.
(cd "$APP" && find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PAYLOAD-SHA256SUMS.txt)

FINALROOT="$OUT/RG35XX-MIYOO-FULL-PORT-R1-LAYOUT-R2"
mkdir -p "$FINALROOT"
cp -R "$SD" "$FINALROOT/SD"
cp "$BASE/README-FIRST.txt" "$FINALROOT/README-FIRST.txt" 2>/dev/null || true
cp "$BASE/INSTALL-LAYOUT-R2-IDENTITY.txt" "$FINALROOT/INSTALL-LAYOUT-R2-IDENTITY.txt"
cat > "$FINALROOT/README-LAYOUT-R2.txt" <<'EOF_README'
RG35XX Full Port R1 — install/layout R2 physical candidate.

Why R2 exists:
The first R1 physical run reached the test launcher but the expected app-local
runtime sibling was absent on SD. This package changes only installation/bootstrap
behavior. It does not rebuild JamVM, glibj, platform JAR, input, video, font or audio.

Install:
Copy the CONTENTS of SD/ to the GarlicOS SD root.
Run RG35XX-FULL-PORT-R1-TEST. The launcher will first materialize and hash-check
the exact runtime at its compiled prefix if it is missing.

If P6 succeeds, then run RG35XX-R1-P7-TIER0 if present.
DEVICE_PASS remains NO until physical review.
EOF_README
ZIP="$OUT/RG35XX-MIYOO-FULL-PORT-R1-LAYOUT-R2.zip"
rm -f "$ZIP"
(cd "$OUT" && zip -qr "$(basename "$ZIP")" "$(basename "$FINALROOT")")
echo R1_LAYOUT_R2_BUILD=PASS
echo RUNTIME_SEMANTIC_DELTA=NONE
echo PLATFORM_SEMANTIC_DELTA=NONE
echo R1_LAYOUT_R2_ZIP="$ZIP"
echo R1_LAYOUT_R2_ZIP_SHA256="$(sha256sum "$ZIP"|awk '{print $1}')"
echo DEVICE_PASS=NO
echo STABLE=NO
