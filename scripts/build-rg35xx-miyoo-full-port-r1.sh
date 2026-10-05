#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "FULL_PORT_R1_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
P3_ARTIFACT_DIR="${P3_ARTIFACT_DIR:-}"
RUNTIME_ARTIFACT_DIR="${RUNTIME_ARTIFACT_DIR:-}"
[ -n "$JAVA8" ] || fail JAVA8_NOT_SET
[ -d "$P3_ARTIFACT_DIR" ] || fail P3_ARTIFACT_DIR_MISSING
[ -d "$RUNTIME_ARTIFACT_DIR" ] || fail RUNTIME_ARTIFACT_DIR_MISSING
for t in javac jar java; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done
for t in unzip zip sha256sum find awk sed grep python3; do command -v "$t" >/dev/null 2>&1 || fail "$t missing"; done

CANONICAL=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
P3_PARENT=8cd4f6b2b08d9fbc009719e4d6148f1726972b7b
EXPECTED_PLATFORM=b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117
EXPECTED_INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_FONT_NATIVE=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_FONT=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
EXPECTED_JAMVM=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
EXPECTED_GLIBJ=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
EXPECTED_CLASSES=ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86

OUT="$ROOT/out/full-port-r1"
WORK="$ROOT/build/full-port-r1"
PKGROOT="$OUT/RG35XX-MIYOO-FULL-PORT-R1"
SD="$PKGROOT/SD"
APP="$SD/Roms/APPS/FreeJ2ME-RG35XX"
RUNTIME_DST="$SD/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
TEST="$APP/test"
ZIP="$OUT/RG35XX-MIYOO-FULL-PORT-R1.zip"
rm -rf "$OUT" "$WORK"
mkdir -p "$OUT/stage" "$WORK/p3" "$WORK/runtime" "$APP" "$RUNTIME_DST" "$TEST/identities" "$APP/data" "$APP/rms" "$APP/config" "$SD/Roms/JAVA"

# Consume the exact accepted P3 physical artifact. No diagnostic branch is a
# production parent; this is byte-level artifact reuse from the accepted P3 lineage.
P3ZIP="$(find "$P3_ARTIFACT_DIR" -type f -name 'RG35XX-P3-RUNTIME-SERVICE-PHYSICAL-R1.zip' -print -quit)"
if [ -n "$P3ZIP" ]; then unzip -q "$P3ZIP" -d "$WORK/p3"; else cp -a "$P3_ARTIFACT_DIR"/. "$WORK/p3/"; fi
P3_PAYLOAD="$(find "$WORK/p3" -type d -path '*/SD/Roms/APPS/RG35XX-P3-RUNTIME-SERVICE' -print -quit)"
[ -n "$P3_PAYLOAD" ] || fail P3_PAYLOAD_NOT_FOUND

# Runtime artifact may already be unpacked by Actions or may contain the rebuild ZIP.
RUNTIME_SRC="$(find "$RUNTIME_ARTIFACT_DIR" -type f -path '*/runtime/bin/jamvm' -print -quit | sed 's#/bin/jamvm$##')"
if [ -z "$RUNTIME_SRC" ]; then
  RZIP="$(find "$RUNTIME_ARTIFACT_DIR" -type f -name 'RG35XX-RUNTIME-CANDIDATE-REBUILD.zip' -print -quit)"
  [ -n "$RZIP" ] || fail RUNTIME_PAYLOAD_NOT_FOUND
  unzip -q "$RZIP" -d "$WORK/runtime"
  RUNTIME_SRC="$(find "$WORK/runtime" -type f -path '*/runtime/bin/jamvm' -print -quit | sed 's#/bin/jamvm$##')"
fi
[ -n "$RUNTIME_SRC" ] || fail RUNTIME_ROOT_NOT_FOUND

hash_eq(){ local file="$1" expected="$2" tag="$3"; [ -f "$file" ] || fail "$tag:MISSING"; local got; got="$(sha256sum "$file"|awk '{print $1}')"; [ "$got" = "$expected" ] || fail "$tag:HASH:$got"; echo "$tag=PASS"; }
hash_eq "$P3_PAYLOAD/freej2me-rg35xx.jar" "$EXPECTED_PLATFORM" PLATFORM_HASH_GATE
hash_eq "$P3_PAYLOAD/librg35xx_input.so" "$EXPECTED_INPUT" INPUT_HASH_GATE
hash_eq "$P3_PAYLOAD/librg35xx_video.so" "$EXPECTED_VIDEO" VIDEO_HASH_GATE
hash_eq "$P3_PAYLOAD/librg35xx_font.so" "$EXPECTED_FONT_NATIVE" FONT_NATIVE_HASH_GATE
hash_eq "$P3_PAYLOAD/libaudio.so" "$EXPECTED_AUDIO" AUDIO_HASH_GATE
hash_eq "$P3_PAYLOAD/font.ttf" "$EXPECTED_FONT" FONT_HASH_GATE
hash_eq "$RUNTIME_SRC/bin/jamvm" "$EXPECTED_JAMVM" JAMVM_HASH_GATE
hash_eq "$RUNTIME_SRC/share/classpath/glibj.zip" "$EXPECTED_GLIBJ" GLIBJ_HASH_GATE
hash_eq "$RUNTIME_SRC/share/jamvm/classes.zip" "$EXPECTED_CLASSES" JAMVM_CLASSES_HASH_GATE

for f in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so librg35xx_font.so libaudio.so font.ttf; do cp -a "$P3_PAYLOAD/$f" "$APP/$f"; done
[ ! -d "$P3_PAYLOAD/licenses" ] || cp -a "$P3_PAYLOAD/licenses" "$APP/"
[ ! -f "$P3_PAYLOAD/NOTICE.txt" ] || cp "$P3_PAYLOAD/NOTICE.txt" "$APP/NOTICE.txt"
cp -a "$RUNTIME_SRC"/. "$RUNTIME_DST/"
chmod 0755 "$RUNTIME_DST/bin/jamvm"
cp "$APP/freej2me-rg35xx.jar" "$OUT/stage/freej2me-rg35xx.jar"

# Rebuild the already-accepted exercisers against the exact final R1 platform bytes.
mkdir -p "$ROOT/out/p1a-complete-graphics-candidate" "$ROOT/out/p2a-image-decode-candidate" "$ROOT/out/p2b-font-text-candidate-r1" "$ROOT/out/p2c-input-frontend-candidate-r1"
cp "$APP/freej2me-rg35xx.jar" "$ROOT/out/p1a-complete-graphics-candidate/freej2me-rg35xx.jar"
cp "$APP/freej2me-rg35xx.jar" "$ROOT/out/p2a-image-decode-candidate/freej2me-rg35xx.jar"
cp "$APP/freej2me-rg35xx.jar" "$ROOT/out/p2b-font-text-candidate-r1/freej2me-rg35xx.jar"
cp "$APP/freej2me-rg35xx.jar" "$ROOT/out/p2c-input-frontend-candidate-r1/freej2me-rg35xx.jar"
JAVA8="$JAVA8" bash "$ROOT/scripts/build-p1a-graphics-exerciser.sh"
JAVA8="$JAVA8" bash "$ROOT/scripts/build-p2a-image-exerciser.sh"
JAVA8="$JAVA8" bash "$ROOT/scripts/build-p2b-font-text-exerciser.sh"
P2C_SEM="$(python3 "$ROOT/scripts/p2c-semantic-jar-digest.py" "$APP/freej2me-rg35xx.jar")"
JAVA8="$JAVA8" EXPECTED_PLATFORM_SEMANTIC="$P2C_SEM" bash "$ROOT/scripts/build-p2c-input-frontend-exerciser.sh"
JAVA8="$JAVA8" P3_PLATFORM="$APP/freej2me-rg35xx.jar" bash "$ROOT/scripts/build-p3-runtime-service-exerciser.sh"
JAVA8="$JAVA8" P6_PLATFORM="$APP/freej2me-rg35xx.jar" bash "$ROOT/scripts/build-rg35xx-p6-integration-exerciser.sh"

cp "$ROOT/out/p1a-complete-graphics-candidate/RG35XX-Platform-Exerciser-P1A.jar" "$TEST/"
cp "$ROOT/out/p2a-image-decode-candidate/RG35XX-Platform-Exerciser-P2A-Image.jar" "$TEST/"
cp "$ROOT/out/p2b-font-text-candidate-r1/RG35XX-Platform-Exerciser-P2B-FontText.jar" "$TEST/"
cp "$ROOT/out/p2c-input-frontend-candidate-r1/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" "$TEST/"
cp "$ROOT/out/p3-runtime-service-exerciser/RG35XX-Platform-Exerciser-P3-RuntimeService.jar" "$TEST/"
cp "$ROOT/out/p6-integration-exerciser/RG35XX-Platform-Exerciser-P6-Integration.jar" "$TEST/"
for spec in \
  "$ROOT/out/p1a-complete-graphics-candidate/P1A-EXERCISER-IDENTITY.txt" \
  "$ROOT/out/p2a-image-decode-candidate/P2A-IMAGE-EXERCISER-IDENTITY.txt" \
  "$ROOT/out/p2b-font-text-candidate-r1/P2B-FONT-TEXT-EXERCISER-IDENTITY.txt" \
  "$ROOT/out/p2c-input-frontend-candidate-r1/P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt" \
  "$ROOT/out/p3-runtime-service-exerciser/P3-RUNTIME-SERVICE-EXERCISER-IDENTITY.txt" \
  "$ROOT/out/p6-integration-exerciser/P6-INTEGRATION-EXERCISER-IDENTITY.txt"; do
  [ -f "$spec" ] || fail "EXERCISER_IDENTITY_MISSING:$spec"; cp "$spec" "$TEST/identities/"
done

# Generic P5 launcher. It deliberately keeps the runtime at the exact path
# compiled and physically exercised in P2C/P3, avoiding a speculative relocation.
cat > "$SD/Roms/APPS/FreeJ2ME-RG35XX.sh" <<'EOF_LAUNCH'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
JARDIR=/mnt/mmc/Roms/JAVA
JAMVM="$RUNTIME/bin/jamvm"
GLIBJ="$RUNTIME/share/classpath/glibj.zip"
PLATFORM="$PKG/freej2me-rg35xx.jar"
LOG="${FREEJ2ME_LOG:-/mnt/mmc/FreeJ2ME-RG35XX.log}"
fail(){ echo "FREEJ2ME_R1_LAUNCH=FAIL:$1" >"$LOG"; sync; exit 20; }
[ -x "$JAMVM" ] || fail JAMVM_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_MISSING
[ -f "$PLATFORM" ] || fail PLATFORM_MISSING

JAR_PATH="${1:-}"
W="${2:-}"
H="${3:-}"
if [ -z "$JAR_PATH" ]; then
  if [ -f "$JARDIR/selected.txt" ]; then
    SEL="$(sed -n '1p' "$JARDIR/selected.txt" | tr -d '\r\n')"
    [ -n "$SEL" ] || fail SELECTED_EMPTY
    JAR_PATH="$JARDIR/$SEL"
  else
    COUNT=0; ONLY=
    for F in "$JARDIR"/*.jar; do
      [ -f "$F" ] || continue
      COUNT=$((COUNT+1)); ONLY="$F"
    done
    [ "$COUNT" -eq 1 ] || fail "JAR_SELECTION_REQUIRED:$COUNT"
    JAR_PATH="$ONLY"
  fi
fi
[ -f "$JAR_PATH" ] || fail JAR_MISSING
[ -n "$W" ] || W=240
[ -n "$H" ] || H=320
case "$W:$H" in *[!0-9:]*|:*|*:) fail INVALID_RESOLUTION;; esac
NAME="$(basename "$JAR_PATH" .jar | tr -c 'A-Za-z0-9._-' '_')"
DATA="$PKG/data/$NAME"; RMS="$PKG/rms/$NAME"
mkdir -p "$DATA" "$RMS" || fail STORAGE_CREATE
RUNTIME_LIBS="$RUNTIME/lib/classpath:$RUNTIME/lib:"
: >"$LOG"
echo "FREEJ2ME_R1_LAUNCH=BEGIN" >>"$LOG"
echo "FREEJ2ME_R1_JAR=$JAR_PATH" >>"$LOG"
echo "FREEJ2ME_R1_RESOLUTION=${W}x${H}" >>"$LOG"
LD_LIBRARY_PATH="$RUNTIME_LIBS$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$JAMVM" -Xmx64m -Drg35xx.raw2d=true \
  -Drg35xx.native.dir="$PKG" -Drg35xx.font.path="$PKG/font.ttf" \
  -Drg35xx.font.native.path="$PKG/librg35xx_font.so" \
  -cp "$GLIBJ:$PLATFORM" org.recompile.rg35xx.RG35XXLauncher \
  "$JAR_PATH" "$W" "$H" "$DATA" "$RMS" >>"$LOG" 2>&1
RC=$?
echo "FREEJ2ME_R1_JVM_EXIT=$RC" >>"$LOG"
[ "$RC" -eq 0 ] && echo "FREEJ2ME_R1_LAUNCH=PASS" >>"$LOG" || echo "FREEJ2ME_R1_LAUNCH=FAIL:JVM_EXIT" >>"$LOG"
sync
exit "$RC"
EOF_LAUNCH
chmod +x "$SD/Roms/APPS/FreeJ2ME-RG35XX.sh"

P1J="$TEST/RG35XX-Platform-Exerciser-P1A.jar"
P2AJ="$TEST/RG35XX-Platform-Exerciser-P2A-Image.jar"
P2BJ="$TEST/RG35XX-Platform-Exerciser-P2B-FontText.jar"
P2CJ="$TEST/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar"
P3J="$TEST/RG35XX-Platform-Exerciser-P3-RuntimeService.jar"
P6J="$TEST/RG35XX-Platform-Exerciser-P6-Integration.jar"
P1SHA="$(sha256sum "$P1J"|awk '{print $1}')"; P2ASHA="$(sha256sum "$P2AJ"|awk '{print $1}')"; P2BSHA="$(sha256sum "$P2BJ"|awk '{print $1}')"
P2CSHA="$(sha256sum "$P2CJ"|awk '{print $1}')"; P3SHA="$(sha256sum "$P3J"|awk '{print $1}')"; P6SHA="$(sha256sum "$P6J"|awk '{print $1}')"

cat > "$SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh" <<'EOF_TEST'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
EVID=/mnt/mmc/RG35XX-FULL-PORT-R1-EVIDENCE
MASTER="$EVID/FULL-PORT-R1-RUN.log"
SUMMARY="$EVID/FULL-PORT-R1-SUMMARY.txt"
DATA="$EVID/data"; RMS="$EVID/rms"
JAMVM="$RUNTIME/bin/jamvm"; GLIBJ="$RUNTIME/share/classpath/glibj.zip"
RUNTIME_LIBS="$RUNTIME/lib/classpath:$RUNTIME/lib:"
EXPECTED_PLATFORM=__PLATFORM__
EXPECTED_INPUT=__INPUT__
EXPECTED_VIDEO=__VIDEO__
EXPECTED_FONT_NATIVE=__FONT_NATIVE__
EXPECTED_AUDIO=__AUDIO__
EXPECTED_FONT=__FONT__
EXPECTED_JAMVM=__JAMVM__
EXPECTED_GLIBJ=__GLIBJ__
EXPECTED_CLASSES=__CLASSES__
EXPECTED_P1=__P1__
EXPECTED_P2A=__P2A__
EXPECTED_P2B=__P2B__
EXPECTED_P2C=__P2C__
EXPECTED_P3=__P3__
EXPECTED_P6=__P6__
rm -rf "$EVID"; mkdir -p "$DATA" "$RMS" || exit 20
: >"$MASTER"
cat >"$SUMMARY" <<'EOF_SUM'
PROJECT=RG35XX-AWEIGIT-R1
PACKAGE=RG35XX-MIYOO-FULL-PORT-R1
PHYSICAL_TEST_LEVEL=FULL_PLATFORM_CAMPAIGN
P1_ACCEPTED_INPUT=PASS
P2_ACCEPTED_INPUT=PASS
P3_ACCEPTED_INPUT=PASS
P4_DEFERRED_CAPABILITY_DECISION=PASS
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
FULL_PORT_R1_PROGRAMMATIC=NOT_TESTED
AUDIO_AUDIBLE=REQUIRED_MANUAL
NORMAL_RETURN_TO_GARLICOS=REQUIRED_MANUAL
DEVICE_PASS=NO
STABLE=NO
EOF_SUM
fail(){ echo "FULL_PORT_R1_DEVICE=FAIL:$1" >>"$MASTER"; echo "FULL_PORT_R1_PROGRAMMATIC=FAIL:$1" >>"$SUMMARY"; sync; exit 20; }
hashcheck(){ [ -f "$1" ] || fail "MISSING:$1"; [ "$(sha256sum "$1"|awk '{print $1}')" = "$2" ] || fail "HASH:$1"; }
hashcheck "$PKG/freej2me-rg35xx.jar" "$EXPECTED_PLATFORM"
hashcheck "$PKG/librg35xx_input.so" "$EXPECTED_INPUT"
hashcheck "$PKG/librg35xx_video.so" "$EXPECTED_VIDEO"
hashcheck "$PKG/librg35xx_font.so" "$EXPECTED_FONT_NATIVE"
hashcheck "$PKG/libaudio.so" "$EXPECTED_AUDIO"
hashcheck "$PKG/font.ttf" "$EXPECTED_FONT"
hashcheck "$JAMVM" "$EXPECTED_JAMVM"
hashcheck "$GLIBJ" "$EXPECTED_GLIBJ"
hashcheck "$RUNTIME/share/jamvm/classes.zip" "$EXPECTED_CLASSES"
hashcheck "$PKG/test/RG35XX-Platform-Exerciser-P1A.jar" "$EXPECTED_P1"
hashcheck "$PKG/test/RG35XX-Platform-Exerciser-P2A-Image.jar" "$EXPECTED_P2A"
hashcheck "$PKG/test/RG35XX-Platform-Exerciser-P2B-FontText.jar" "$EXPECTED_P2B"
hashcheck "$PKG/test/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" "$EXPECTED_P2C"
hashcheck "$PKG/test/RG35XX-Platform-Exerciser-P3-RuntimeService.jar" "$EXPECTED_P3"
hashcheck "$PKG/test/RG35XX-Platform-Exerciser-P6-Integration.jar" "$EXPECTED_P6"
echo 'PHASE0_IDENTITY_HASHES=PASS' >>"$MASTER"

run_direct(){ J="$1" W="$2" H="$3" LOG="$4"; shift 4; set +e; LD_LIBRARY_PATH="$RUNTIME_LIBS$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$JAMVM" -Xmx64m "$@" -Drg35xx.raw2d=true -Drg35xx.native.dir="$PKG" -Drg35xx.font.path="$PKG/font.ttf" -Drg35xx.font.native.path="$PKG/librg35xx_font.so" -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" org.recompile.rg35xx.RG35XXLauncher "$J" "$W" "$H" "$DATA" "$RMS" >"$LOG" 2>&1; RC=$?; set -e; cat "$LOG" >>"$MASTER"; return "$RC"; }

FREEJ2ME_LOG="$EVID/01-P6-GENERIC-LAUNCH.log" "$APPS/FreeJ2ME-RG35XX.sh" "$PKG/test/RG35XX-Platform-Exerciser-P6-Integration.jar" 176 208 || fail P6_GENERIC_LAUNCH
cat "$EVID/01-P6-GENERIC-LAUNCH.log" >>"$MASTER"
grep -q '^P6_INTEGRATION_RESULT=PASS$' "$EVID/01-P6-GENERIC-LAUNCH.log" || fail P6_INTEGRATION_MARKER
echo 'PHASE1_P5_GENERIC_LAUNCH_P6_INTEGRATION=PASS' >>"$MASTER"

run_direct "$PKG/test/RG35XX-Platform-Exerciser-P1A.jar" 176 208 "$EVID/02-P1-GRAPHICS.log" || fail P1_GRAPHICS
grep -q '^P1A_EXERCISER_RESULT=PASS' "$EVID/02-P1-GRAPHICS.log" || fail P1_MARKER
echo 'PHASE2_CORE2D_GRAPHICS=PASS' >>"$MASTER"

run_direct "$PKG/test/RG35XX-Platform-Exerciser-P2A-Image.jar" 176 208 "$EVID/03-P2A-IMAGE.log" || fail P2A_IMAGE
grep -q '^P2A_EXERCISER_RESULT=PASS' "$EVID/03-P2A-IMAGE.log" || fail P2A_MARKER
echo 'PHASE3_IMAGE_DECODE=PASS' >>"$MASTER"

run_direct "$PKG/test/RG35XX-Platform-Exerciser-P2B-FontText.jar" 176 208 "$EVID/04-P2B-FONT.log" || fail P2B_FONT
grep -q '^P2B_EXERCISER_RESULT=PASS' "$EVID/04-P2B-FONT.log" || fail P2B_MARKER
echo 'PHASE4_FONT_TEXT=PASS' >>"$MASTER"

rm -f "$DATA/keymap.cfg"; rm -rf "$DATA/config"
run_direct "$PKG/test/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" 176 208 "$EVID/05-P2C-PHASE1.log" -Dp2c.exerciser.phase=1 || fail P2C_PHASE1
grep -q '^P2C_EXERCISER_RESULT=PASS PHASE=1$' "$EVID/05-P2C-PHASE1.log" || fail P2C_PHASE1_MARKER
cat >"$DATA/keymap.cfg" <<'EOF_KEYMAP'
{
"左键":"A",
"右键":"Y",
"OK":"B",
"*":"START",
"#":"SELECT",
"0":"X",
"1":"R",
"3":"L",
"7":"R2",
"9":"L2"
}
EOF_KEYMAP
run_direct "$PKG/test/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" 176 208 "$EVID/06-P2C-PHASE2.log" -Dp2c.exerciser.phase=2 || fail P2C_PHASE2
grep -q '^P2C_EXERCISER_RESULT=PASS PHASE=2$' "$EVID/06-P2C-PHASE2.log" || fail P2C_PHASE2_MARKER
cat >"$DATA/keymap.cfg" <<'EOF_BAD'
{"invalid":"mapping"}
EOF_BAD
rm -rf "$DATA/config"
run_direct "$PKG/test/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" 176 208 "$EVID/07-P2C-PHASE3.log" -Dp2c.exerciser.phase=3 || fail P2C_PHASE3
grep -q '^P2C_EXERCISER_RESULT=PASS PHASE=3$' "$EVID/07-P2C-PHASE3.log" || fail P2C_PHASE3_MARKER
echo 'PHASE5_7_INPUT_FRONTEND=PASS' >>"$MASTER"

run_direct "$PKG/test/RG35XX-Platform-Exerciser-P3-RuntimeService.jar" 176 208 "$EVID/08-P3-RUNTIME.log" || fail P3_RUNTIME
for M in P3_RUNTIME_SERVICE_RESULT=PASS P3_RMS_CRUD_ENUMERATE=PASS P3_RMS_REOPEN_DELETE=PASS P3_FILE_CREATE_WRITE_READ_DELETE=PASS P3_MMAPI_WAV_PAUSE_RESUME=PASS P3_MMAPI_MIDI_END_OF_MEDIA=PASS; do grep -q "^$M$" "$EVID/08-P3-RUNTIME.log" || fail "P3_MARKER:$M"; done
echo 'PHASE8_RUNTIME_SERVICES=PASS' >>"$MASTER"

cat >"$EVID/MANUAL-OBSERVATION.txt" <<'EOF_MANUAL'
FULL_PORT_R1_AUDIO_AUDIBLE=NOT_TESTED
FULL_PORT_R1_P2C_ROTATION_VISUAL=NOT_TESTED
FULL_PORT_R1_NORMAL_RETURN_TO_GARLICOS=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_MANUAL
echo 'FULL_PORT_R1_PROGRAMMATIC=PASS' >>"$SUMMARY"
echo 'PHYSICAL_MANUAL_REVIEW=REQUIRED' >>"$SUMMARY"
echo 'DEVICE_PASS=NO' >>"$SUMMARY"
echo 'STABLE=NO' >>"$SUMMARY"
echo 'FULL_PORT_R1_PROGRAMMATIC=PASS' >>"$MASTER"
sync
exit 0
EOF_TEST
python3 - "$SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh" <<PY
import sys
p=sys.argv[1]
s=open(p,encoding='utf-8').read()
repl={
'__PLATFORM__':'$EXPECTED_PLATFORM','__INPUT__':'$EXPECTED_INPUT','__VIDEO__':'$EXPECTED_VIDEO','__FONT_NATIVE__':'$EXPECTED_FONT_NATIVE','__AUDIO__':'$EXPECTED_AUDIO','__FONT__':'$EXPECTED_FONT','__JAMVM__':'$EXPECTED_JAMVM','__GLIBJ__':'$EXPECTED_GLIBJ','__CLASSES__':'$EXPECTED_CLASSES','__P1__':'$P1SHA','__P2A__':'$P2ASHA','__P2B__':'$P2BSHA','__P2C__':'$P2CSHA','__P3__':'$P3SHA','__P6__':'$P6SHA'}
for k,v in repl.items(): s=s.replace(k,v)
open(p,'w',encoding='utf-8').write(s)
PY
chmod +x "$SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh"

cat > "$APP/FULL-PORT-R1-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
PACKAGE=RG35XX-MIYOO-FULL-PORT-R1
CANONICAL_AWEIGIT=$CANONICAL
PRODUCTION_PARENT=$P3_PARENT
PRODUCTION_PARENT_ROLE=P3_PHYSICAL_ACCEPTED_LINEAGE
PLATFORM_JAR_SHA256=$EXPECTED_PLATFORM
INPUT_NATIVE_SHA256=$EXPECTED_INPUT
VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
FONT_NATIVE_SHA256=$EXPECTED_FONT_NATIVE
AUDIO_NATIVE_SHA256=$EXPECTED_AUDIO
FONT_SHA256=$EXPECTED_FONT
RUNTIME_SOURCE=CANDIDATE_PROBE
RUNTIME_DEVICE_ROOT=/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime
RUNTIME_JAMVM_SHA256=$EXPECTED_JAMVM
RUNTIME_GLIBJ_SHA256=$EXPECTED_GLIBJ
RUNTIME_CLASSES_SHA256=$EXPECTED_CLASSES
RUNTIME_RELOCATION=NO
P1_ACCEPTED_INPUT=PASS
P2_ACCEPTED_INPUT=PASS
P3_ACCEPTED_INPUT=PASS
P4_DEFERRED_CAPABILITY_DECISION=PASS
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
BLUETOOTH_JSR82=DEFER_CAPABILITY
SENSOR_JSR256=DEFER_CAPABILITY
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
P5_GENERIC_INSTALLER_HOST=PASS
P6_FULL_PLATFORM_HOST_BUILD=PASS
P6_ORIGINAL_RG35XX_PHYSICAL=NOT_TESTED
P7_TIER0_REGRESSION=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
EOF_ID

cat > "$SD/Roms/JAVA/README-PUT-JARS-HERE.txt" <<'EOF_JAVA'
Place Java ME .jar files in this directory.
If there is exactly one .jar, FreeJ2ME-RG35XX.sh launches it automatically.
If there are multiple .jar files, put the selected filename on the first line of selected.txt.
Optional explicit launch syntax:
  FreeJ2ME-RG35XX.sh /mnt/mmc/Roms/JAVA/example.jar 176 208
EOF_JAVA
cat > "$PKGROOT/README-FIRST.txt" <<'EOF_README'
RG35XX Miyoo Full Port R1 integration candidate.

Copy the contents of SD/ to the root of the original RG35XX GarlicOS SD card.
For the full platform campaign run:
  /mnt/mmc/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh

For a generic Java ME JAR run:
  /mnt/mmc/Roms/APPS/FreeJ2ME-RG35XX.sh /mnt/mmc/Roms/JAVA/<file>.jar <width> <height>

The R1 campaign reuses the accepted P1/P2/P3 exerciser sources on the final P3
platform bytes. P2C is human-driven and must follow the on-screen prompts.
Audio audibility, P2C rotation orientation and normal return to GarlicOS remain
manual physical observations. Programmatic PASS is not DEVICE-PASS.

M3G, MascotCapsule/Micro3D and LWJGL/OpenGL remain deferred and disabled.
EOF_README

# Host gates: Java 6 bytecode, no optional 3D payload, no game-specific active code.
python3 - "$APP" <<'PY'
import os,sys,zipfile
root=sys.argv[1]
for fn in []:
    pass
jars=[]
for base,dirs,files in os.walk(root):
    for f in files:
        if f.endswith('.jar'): jars.append(os.path.join(base,f))
for jar in jars:
    with zipfile.ZipFile(jar) as z:
        for n in z.namelist():
            if not n.endswith('.class'): continue
            b=z.read(n)
            if len(b)<8 or b[:4]!=b'\xca\xfe\xba\xbe': raise SystemExit('JAVA6_GATE_BAD_CLASS '+jar+' '+n)
            major=int.from_bytes(b[6:8],'big')
            if major>50: raise SystemExit('JAVA6_GATE_FAIL '+jar+' '+n+' major='+str(major))
print('FULL_PORT_R1_JAVA6_GATE=PASS')
PY
find "$APP" -type f \( -name 'libm3g.so' -o -name 'libmicro3d.so' -o -name '*lwjgl*.so' \) | grep . && fail OPTIONAL_3D_NATIVE_INCLUDED || true
if grep -R -I -n -E 'Vua Cướp Biển|God of War|Bolacthoitiensu|BOLACTHOITIENSU' "$APP" "$SD/Roms/APPS/FreeJ2ME-RG35XX.sh" "$SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh"; then fail GAME_SPECIFIC_ACTIVE_PACKAGE; fi

echo 'P5_GENERIC_INSTALLER_HOST=PASS'
echo 'P6_FULL_PLATFORM_HOST_BUILD=PASS'
(cd "$APP" && find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PAYLOAD-SHA256SUMS.txt && sha256sum -c PAYLOAD-SHA256SUMS.txt)
(cd "$RUNTIME_DST" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > "$APP/RUNTIME-PAYLOAD-SHA256SUMS.txt")
rm -f "$ZIP"
(cd "$OUT" && zip -qr "$(basename "$ZIP")" "$(basename "$PKGROOT")")
ZIP_SHA="$(sha256sum "$ZIP"|awk '{print $1}')"
echo "FULL_PORT_R1_ZIP=$ZIP"
echo "FULL_PORT_R1_ZIP_SHA256=$ZIP_SHA"
echo FULL_PORT_R1_HOST_BUILD=PASS
echo P6_ORIGINAL_RG35XX_PHYSICAL=NOT_TESTED
echo DEVICE_PASS=NO
echo STABLE=NO
