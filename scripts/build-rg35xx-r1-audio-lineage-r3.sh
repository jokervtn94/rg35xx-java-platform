#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "R1_AUDIO_LINEAGE_R3_BUILD_FAIL=$*" >&2; exit 1; }

R2ZIP="${R2_DEVICE_ZIP:-}"
P3ART="${P3_ACCEPTED_ARTIFACT_DIR:-}"
[ -f "$R2ZIP" ] || fail R2_DEVICE_ZIP_MISSING
[ -d "$P3ART" ] || fail P3_ACCEPTED_ARTIFACT_DIR_MISSING
for t in unzip zip sha256sum awk grep sed cp chmod find python3; do command -v "$t" >/dev/null 2>&1 || fail "$t missing"; done

EXPECTED_R2=72492858d07b2c21d0c766c050f6b6af63fc3c883361916f2dd848503815b63e
PRE_FIX_PLATFORM=b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117
ACCEPTED_PLATFORM=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
EXPECTED_JAMVM=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
EXPECTED_GLIBJ=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
EXPECTED_CLASSES=ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86
EXPECTED_INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_FONT_NATIVE=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_FONT=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10

[ "$(sha256sum "$R2ZIP"|awk '{print $1}')" = "$EXPECTED_R2" ] || fail R2_PARENT_HASH
ACCEPTED_JAR="$(find "$P3ART" -type f -path '*/out/p3-audio-platform/freej2me-rg35xx.jar' -print -quit)"
[ -n "$ACCEPTED_JAR" ] || ACCEPTED_JAR="$(find "$P3ART" -type f -path '*/p3-audio-platform/freej2me-rg35xx.jar' -print -quit)"
[ -n "$ACCEPTED_JAR" ] || fail ACCEPTED_P3_PLATFORM_NOT_FOUND
[ "$(sha256sum "$ACCEPTED_JAR"|awk '{print $1}')" = "$ACCEPTED_PLATFORM" ] || fail ACCEPTED_P3_PLATFORM_HASH

OUT="$ROOT/out/r1-audio-lineage-r3"
WORK="$ROOT/build/r1-audio-lineage-r3"
rm -rf "$OUT" "$WORK"
mkdir -p "$OUT" "$WORK"
unzip -q "$R2ZIP" -d "$WORK"
BASE="$(find "$WORK" -type d -name 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-LAYOUT-R2' -print -quit)"
[ -n "$BASE" ] || fail R2_ROOT_NOT_FOUND
SD="$BASE/SD"
APPS="$SD/Roms/APPS"
APP="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
OLD_JAR="$APP/freej2me-rg35xx.jar"
[ "$(sha256sum "$OLD_JAR"|awk '{print $1}')" = "$PRE_FIX_PLATFORM" ] || fail PRE_FIX_PLATFORM_PARENT_HASH

# Prove the accepted P3 artifact is the already-approved RG35XXLauncher-only delta.
python3 - "$OLD_JAR" "$ACCEPTED_JAR" <<'PY'
import hashlib, sys, zipfile
old,new=sys.argv[1:]
with zipfile.ZipFile(old) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('R1_R3_ENTRY_SET_FAIL')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
    expected=[
      'org/recompile/rg35xx/RG35XXLauncher$1.class',
      'org/recompile/rg35xx/RG35XXLauncher$FramePresenter.class',
      'org/recompile/rg35xx/RG35XXLauncher$InputPump.class',
      'org/recompile/rg35xx/RG35XXLauncher.class',
    ]
    if diff != expected:
        raise SystemExit('R1_R3_SCOPE_FAIL='+repr(diff))
    data=b.read('org/recompile/rg35xx/RG35XXLauncher.class')
    for marker in (b'libaudio.so', b'RG35XX_A7_AUDIO_BRIDGE=LOADED', b'DEVICE_INIT=LAZY'):
        if marker not in data:
            raise SystemExit('R1_R3_AUDIO_LOADER_MARKER_FAIL='+repr(marker))
print('R1_R3_PLATFORM_DELTA_SCOPE=RG35XXLauncher_CLASS_FAMILY_ONLY')
print('R1_R3_ACCEPTED_AUDIO_LOADER_MARKER_GATE=PASS')
PY

cp "$ACCEPTED_JAR" "$OLD_JAR"
[ "$(sha256sum "$OLD_JAR"|awk '{print $1}')" = "$ACCEPTED_PLATFORM" ] || fail INSTALLED_PLATFORM_HASH

hash_eq(){ [ -f "$1" ] || fail "MISSING:$1"; [ "$(sha256sum "$1"|awk '{print $1}')" = "$2" ] || fail "HASH:$1"; }
hash_eq "$APP/librg35xx_input.so" "$EXPECTED_INPUT"
hash_eq "$APP/librg35xx_video.so" "$EXPECTED_VIDEO"
hash_eq "$APP/librg35xx_font.so" "$EXPECTED_FONT_NATIVE"
hash_eq "$APP/libaudio.so" "$EXPECTED_AUDIO"
hash_eq "$APP/font.ttf" "$EXPECTED_FONT"
hash_eq "$RUNTIME/bin/jamvm" "$EXPECTED_JAMVM"
hash_eq "$RUNTIME/share/classpath/glibj.zip" "$EXPECTED_GLIBJ"
hash_eq "$RUNTIME/share/jamvm/classes.zip" "$EXPECTED_CLASSES"
hash_eq "$APP/bootstrap-runtime/bin/jamvm" "$EXPECTED_JAMVM"
hash_eq "$APP/bootstrap-runtime/share/classpath/glibj.zip" "$EXPECTED_GLIBJ"
hash_eq "$APP/bootstrap-runtime/share/jamvm/classes.zip" "$EXPECTED_CLASSES"

# Update only package identities and runtime hash gates that refer to the platform byte identity.
for f in \
  "$BASE/INSTALL-LAYOUT-R2-IDENTITY.txt" \
  "$APP/FULL-PORT-R1-IDENTITY.txt" \
  "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" \
  "$APPS/RG35XX-R1-P7/P7-TIER0-IDENTITY.txt" \
  "$APPS/RG35XX-R1-P7-TIER0.sh"; do
  [ -f "$f" ] || fail "IDENTITY_OR_LAUNCHER_MISSING:$f"
  sed -i "s/$PRE_FIX_PLATFORM/$ACCEPTED_PLATFORM/g" "$f"
done

grep -q "$ACCEPTED_PLATFORM" "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" || fail P6_EXPECTED_PLATFORM_NOT_UPDATED
grep -q "$ACCEPTED_PLATFORM" "$APPS/RG35XX-R1-P7-TIER0.sh" || fail P7_EXPECTED_PLATFORM_NOT_UPDATED

cat > "$BASE/AUDIO-LINEAGE-R3-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
SCOPE=FULL_PORT_INTEGRATION_ARTIFACT_SELECTION_ONLY
FAILURE_OWNER=RG35XX_AUDIO_BOUNDARY_ARTIFACT_SELECTION
EVIDENCE=P3_RUNTIME_SERVICE_RESULT_FAIL_UNSATISFIEDLINK_sdlMixerInit
PRE_FIX_PLATFORM_SHA256=$PRE_FIX_PLATFORM
ACCEPTED_P3_PLATFORM_SHA256=$ACCEPTED_PLATFORM
ACCEPTED_P3_ARTIFACT_ID=11306309186
ACCEPTED_P3_WORKFLOW_RUN=37211752518
ACCEPTED_P3_COMMIT=4fe82701dc98f29b96585e85deb146093ac14cc3
PLATFORM_DELTA_SCOPE=RG35XXLauncher_CLASS_FAMILY_ONLY
CANONICAL_MMAPI=UNCHANGED
CANONICAL_PLATFORMPLAYER=UNCHANGED
CANONICAL_SDLMIXERMANAGER=UNCHANGED
RUNTIME_SEMANTIC_DELTA=NONE
NATIVE_AUDIO_DELTA=NONE
JAMVM_SHA256=$EXPECTED_JAMVM
GLIBJ_SHA256=$EXPECTED_GLIBJ
INPUT_SHA256=$EXPECTED_INPUT
VIDEO_SHA256=$EXPECTED_VIDEO
FONT_NATIVE_SHA256=$EXPECTED_FONT_NATIVE
AUDIO_SHA256=$EXPECTED_AUDIO
FONT_SHA256=$EXPECTED_FONT
P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
P7_PHYSICAL_REGRESSION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_ID

# Recompute main payload checksums because the platform JAR and identity text changed.
(cd "$APP" && find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PAYLOAD-SHA256SUMS.txt)

FINALROOT="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R3"
mkdir -p "$FINALROOT"
cp -R "$SD" "$FINALROOT/SD"
cp "$BASE/README-FIRST.txt" "$FINALROOT/README-FIRST.txt" 2>/dev/null || true
cp "$BASE/README-LAYOUT-R2.txt" "$FINALROOT/README-LAYOUT-R2.txt" 2>/dev/null || true
cp "$BASE/AUDIO-LINEAGE-R3-IDENTITY.txt" "$FINALROOT/AUDIO-LINEAGE-R3-IDENTITY.txt"
cat > "$FINALROOT/README-R3.txt" <<'EOF_README'
RG35XX Full Port R1 — R3 audio-lineage correction.

Evidence from the R2 physical campaign showed P1/P2/P2C running, while P3 stopped
at java.lang.UnsatisfiedLinkError: sdlMixerInit. This exactly matches the P3
pre-fix failure already resolved and physically accepted on the original RG35XX.

R3 does not invent a new audio fix. It restores the exact previously accepted
P3 audio-loader platform JAR (SHA256 a72df911...) from Actions artifact
11306309186 / run 37211752518. The only JAR delta versus the R2 pre-fix platform
is the RG35XXLauncher class family. JamVM, glibj, MMAPI, PlatformPlayer,
SdlMixerManager, libaudio.so, input, video and font native binaries are unchanged.

Install by replacing the prior R1/R2 APPS payload with the contents of SD/.
Run RG35XX-FULL-PORT-R1-TEST first. Only after P6 programmatic and physical review
succeeds should RG35XX-R1-P7-TIER0 be run.
EOF_README

ZIP="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R3.zip"
rm -f "$ZIP"
(cd "$OUT" && zip -qr "$(basename "$ZIP")" "$(basename "$FINALROOT")")
echo R1_AUDIO_LINEAGE_R3_BUILD=PASS
echo R1_AUDIO_LINEAGE_R3_PLATFORM_SHA256=$ACCEPTED_PLATFORM
echo R1_AUDIO_LINEAGE_R3_RUNTIME_SEMANTIC_DELTA=NONE
echo R1_AUDIO_LINEAGE_R3_NATIVE_AUDIO_DELTA=NONE
echo R1_AUDIO_LINEAGE_R3_ZIP="$ZIP"
echo R1_AUDIO_LINEAGE_R3_ZIP_SHA256="$(sha256sum "$ZIP"|awk '{print $1}')"
echo P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
echo P7_PHYSICAL_REGRESSION=NOT_TESTED
echo DEVICE_PASS=NO
echo STABLE=NO
