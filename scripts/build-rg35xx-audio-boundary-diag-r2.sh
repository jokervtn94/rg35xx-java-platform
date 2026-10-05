#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PARENT_ZIP="${AUDIO_DIAG_PARENT_ZIP:-}"
[ -n "$PARENT_ZIP" ] && [ -f "$PARENT_ZIP" ] || { echo AUDIO_DIAG_R2_BUILD_FAIL=PARENT_ZIP_MISSING >&2; exit 2; }
EXPECTED_PARENT_SHA=75a6085729f282918bf9b7c43eb8b5d067862322648282063edd2773c5e5c8dc
[ "$(sha256sum "$PARENT_ZIP" | awk '{print $1}')" = "$EXPECTED_PARENT_SHA" ] || { echo AUDIO_DIAG_R2_BUILD_FAIL=PARENT_HASH >&2; exit 3; }

WORK="$ROOT/build/audio-boundary-diag-r2"
OUT="$ROOT/out/audio-boundary-diag-r2"
STAGE="$WORK/stage"
rm -rf "$WORK" "$OUT"
mkdir -p "$STAGE" "$OUT"
unzip -q "$PARENT_ZIP" -d "$STAGE"

SCRIPT="$STAGE/SD/Roms/APPS/RG35XX-AUDIO-BOUNDARY-DIAG.sh"
JAR="$STAGE/SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Audio-Boundary-Diagnostic.jar"
[ -f "$SCRIPT" ] || { echo AUDIO_DIAG_R2_BUILD_FAIL=SCRIPT_MISSING >&2; exit 4; }
[ -f "$JAR" ] || { echo AUDIO_DIAG_R2_BUILD_FAIL=JAR_MISSING >&2; exit 5; }
EXPECTED_JAR_SHA=8600a6aaeb5782486a55570e54f11e67cf9edcc2d5233329fdf2b5177d9e0f09
[ "$(sha256sum "$JAR" | awk '{print $1}')" = "$EXPECTED_JAR_SHA" ] || { echo AUDIO_DIAG_R2_BUILD_FAIL=JAR_HASH >&2; exit 6; }

cat > "$SCRIPT" <<'SH'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
JAMVM="$RUNTIME/bin/jamvm"
GLIBJ="$RUNTIME/share/classpath/glibj.zip"
PLATFORM="$PKG/freej2me-rg35xx.jar"
JAR="$PKG/test/RG35XX-Audio-Boundary-Diagnostic.jar"
PRIME="$PKG/a7-a1p5-rw-silence-prime.s32le"
LOG=/mnt/mmc/RG35XX-AUDIO-BOUNDARY-DIAG.log
PRIMELOG=/mnt/mmc/RG35XX-AUDIO-BOUNDARY-DIAG-PRIME.log
OBS=/mnt/mmc/RG35XX-AUDIO-BOUNDARY-DIAG-OBSERVATION.txt

sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
fail(){ echo "AUDIO_DIAG_LAUNCH=FAIL:$1" >"$LOG"; sync; exit 20; }
gate(){ [ -f "$1" ] || fail "MISSING:$1"; [ "$(sha "$1")" = "$2" ] || fail "HASH:$1"; }

[ -x "$JAMVM" ] || fail JAMVM_MISSING
gate "$JAMVM" 0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
gate "$GLIBJ" c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
gate "$PLATFORM" a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
gate "$PKG/librg35xx_input.so" 6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
gate "$PKG/librg35xx_video.so" c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
gate "$PKG/librg35xx_font.so" 29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
gate "$PKG/libaudio.so" 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
gate "$PRIME" 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
gate "$PKG/font.ttf" 1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
gate "$JAR" 8600a6aaeb5782486a55570e54f11e67cf9edcc2d5233329fdf2b5177d9e0f09
command -v aplay >/dev/null 2>&1 || fail APLAY_MISSING

: >"$PRIMELOG"
echo "A1P5_AUDIO_ROUTE_PRIME=BEGIN" >>"$PRIMELOG"
aplay -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 < "$PRIME" >>"$PRIMELOG" 2>&1
PRC=$?
echo "A1P5_AUDIO_ROUTE_PRIME_EXIT_CODE=$PRC" >>"$PRIMELOG"
[ "$PRC" -eq 0 ] || fail AUDIO_ROUTE_PRIME_FAILED
echo "A1P5_AUDIO_ROUTE_PRIME=PASS" >>"$PRIMELOG"

cat >"$OBS" <<'OBSERVATION'
A_COMPLEX_FORMAT1_AUDIBLE=NOT_TESTED
B1_INITIAL_BGM_AUDIBLE=NOT_TESTED
B2_HIGH_FX_AUDIBLE=NOT_TESTED
B3_BGM_RETURN_AUDIBLE=NOT_TESTED
INTERPRETATION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
OBSERVATION

NAME="RG35XX-Audio-Boundary-Diagnostic"
DATA="$PKG/data/$NAME"
RMS="$PKG/rms/$NAME"
mkdir -p "$DATA" "$RMS" || fail STORAGE_CREATE
RUNTIME_LIBS="$RUNTIME/lib/classpath:$RUNTIME/lib:"
export SDL_AUDIODRIVER=alsa
: >"$LOG"
echo "AUDIO_DIAG_LAUNCH=BEGIN" >>"$LOG"
echo "AUDIO_DIAG_PACKAGING_REVISION=R2_DIRECT_R4" >>"$LOG"
echo "AUDIO_DIAG_IDENTITY_GATE=PASS" >>"$LOG"
echo "AUDIO_DIAG_AUDIO_ROUTE_PRIME=PASS" >>"$LOG"
LD_LIBRARY_PATH="$RUNTIME_LIBS$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$JAMVM" -Xmx64m -Drg35xx.raw2d=true \
  -Drg35xx.native.dir="$PKG" \
  -Drg35xx.font.path="$PKG/font.ttf" \
  -Drg35xx.font.native.path="$PKG/librg35xx_font.so" \
  -cp "$GLIBJ:$PLATFORM" org.recompile.rg35xx.RG35XXLauncher \
  "$JAR" 240 320 "$DATA" "$RMS" >>"$LOG" 2>&1
RC=$?
echo "AUDIO_DIAG_JVM_EXIT=$RC" >>"$LOG"
[ "$RC" -eq 0 ] && echo "AUDIO_DIAG_LAUNCH=PASS" >>"$LOG" || echo "AUDIO_DIAG_LAUNCH=FAIL:JVM_EXIT" >>"$LOG"
echo "AUDIO_DIAG_PHYSICAL_REVIEW_REQUIRED=YES" >>"$LOG"
sync
exit "$RC"
SH
chmod +x "$SCRIPT"

cat > "$STAGE/README.txt" <<'EOF'
RG35XX generic audio boundary diagnostic R2 — diagnostic only.

R2 is packaging-only. It preserves the exact diagnostic JAR/fixtures from R1 and removes the accidental dependency on RG35XX-R1-RUNTIME-BOOTSTRAP.sh and FreeJ2ME-RG35XX.sh. It hash-gates the already-installed exact R4 runtime/platform/native payload, runs the exact A1P5 zero-PCM prime directly, then launches JamVM directly with the same R4 arguments.

Copy contents of SD/ to SD root, then run RG35XX-AUDIO-BOUNDARY-DIAG.
Listen to four phases shown on screen:
A  = complex format-1 MIDI, should be clearly audible for ~6 sec.
B1 = low repeating BGM, should be audible for ~4 sec.
B2 = short high FX, then silence.
B3 = low BGM must return for ~5 sec.

Interpretation:
- A silent: complex SDL1 MIDI boundary implicated.
- A+B1+B2 audible, B3 silent: multi-Player/global Mix_Music lifecycle collision proven.
- A+B3 audible: current hypothesis not reproduced; do not patch production.

PARENT_DIAG_ZIP_SHA256=75a6085729f282918bf9b7c43eb8b5d067862322648282063edd2773c5e5c8dc
DIAG_JAR_SHA256=8600a6aaeb5782486a55570e54f11e67cf9edcc2d5233329fdf2b5177d9e0f09
DIAGNOSTIC_SEMANTIC_DELTA=NONE
PACKAGING_DELTA=DIRECT_R4_LAUNCH_ONLY
RUNTIME_SEMANTIC_DELTA=NONE
PLATFORM_SEMANTIC_DELTA=NONE
NATIVE_AUDIO_DELTA=NONE
GAME_SPECIFIC_CODE=NO
DEVICE_PASS=NO
STABLE=NO
EOF

OUTZIP="$OUT/RG35XX-AUDIO-BOUNDARY-DIAG-R2.zip"
(cd "$STAGE" && zip -qr -X "$OUTZIP" .)

echo AUDIO_DIAG_R2_BUILD=PASS
echo AUDIO_DIAG_R2_PARENT_SHA256=$EXPECTED_PARENT_SHA
echo AUDIO_DIAG_R2_JAR_SHA256=$EXPECTED_JAR_SHA
echo AUDIO_DIAG_R2_DIAGNOSTIC_SEMANTIC_DELTA=NONE
echo AUDIO_DIAG_R2_PACKAGING_DELTA=DIRECT_R4_LAUNCH_ONLY
echo AUDIO_DIAG_R2_ZIP_SHA256=$(sha256sum "$OUTZIP" | awk '{print $1}')