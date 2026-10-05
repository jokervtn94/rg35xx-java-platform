#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "R1_AUDIO_ROUTE_R4_BUILD_FAIL=$*" >&2; exit 1; }

R3ZIP="${R3_DEVICE_ZIP:-}"
[ -f "$R3ZIP" ] || fail R3_DEVICE_ZIP_MISSING
for t in unzip zip sha256sum awk grep sed cp chmod find python3 head; do command -v "$t" >/dev/null 2>&1 || fail "$t missing"; done

EXPECTED_R3=93dab9974944b41b4153775aea1a7670ea0b269f55a121680f42ff47032643b3
EXPECTED_PLATFORM=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
EXPECTED_JAMVM=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
EXPECTED_GLIBJ=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
EXPECTED_CLASSES=ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86
EXPECTED_INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_FONT_NATIVE=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_FONT=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
EXPECTED_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e

[ "$(sha256sum "$R3ZIP"|awk '{print $1}')" = "$EXPECTED_R3" ] || fail R3_PARENT_HASH
OUT="$ROOT/out/r1-audio-route-r4"
WORK="$ROOT/build/r1-audio-route-r4"
rm -rf "$OUT" "$WORK"
mkdir -p "$OUT" "$WORK"
unzip -q "$R3ZIP" -d "$WORK"
BASE="$(find "$WORK" -type d -name 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R3' -print -quit)"
[ -n "$BASE" ] || fail R3_ROOT_NOT_FOUND
SD="$BASE/SD"
APPS="$SD/Roms/APPS"
APP="$APPS/FreeJ2ME-RG35XX"
RUNTIME="$APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime"
PRIME="$APP/a7-a1p5-rw-silence-prime.s32le"

hash_eq(){ [ -f "$1" ] || fail "MISSING:$1"; [ "$(sha256sum "$1"|awk '{print $1}')" = "$2" ] || fail "HASH:$1"; }
hash_eq "$APP/freej2me-rg35xx.jar" "$EXPECTED_PLATFORM"
hash_eq "$APP/librg35xx_input.so" "$EXPECTED_INPUT"
hash_eq "$APP/librg35xx_video.so" "$EXPECTED_VIDEO"
hash_eq "$APP/librg35xx_font.so" "$EXPECTED_FONT_NATIVE"
hash_eq "$APP/libaudio.so" "$EXPECTED_AUDIO"
hash_eq "$APP/font.ttf" "$EXPECTED_FONT"
hash_eq "$RUNTIME/bin/jamvm" "$EXPECTED_JAMVM"
hash_eq "$RUNTIME/share/classpath/glibj.zip" "$EXPECTED_GLIBJ"
hash_eq "$RUNTIME/share/jamvm/classes.zip" "$EXPECTED_CLASSES"

# Exact accepted A1P5 payload: 123480 zero bytes, no new audio data or codec.
head -c 123480 /dev/zero > "$PRIME"
hash_eq "$PRIME" "$EXPECTED_PRIME"

cat > "$APPS/RG35XX-R1-AUDIO-ROUTE-PRIME.sh" <<'EOF_PRIME'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APPS/FreeJ2ME-RG35XX"
PRIME="$PKG/a7-a1p5-rw-silence-prime.s32le"
EXPECTED_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
LOG="${RG35XX_AUDIO_ROUTE_LOG:-/mnt/mmc/RG35XX-R1-AUDIO-ROUTE-PRIME.log}"
sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
say(){ echo "$1" >>"$LOG"; }
[ -f "$PRIME" ] || { say A1P5_AUDIO_ROUTE_PRIME=FAIL:PCM_MISSING; exit 21; }
[ "$(sha "$PRIME")" = "$EXPECTED_PRIME" ] || { say A1P5_AUDIO_ROUTE_PRIME=FAIL:PCM_HASH; exit 21; }
APLAY="$(command -v aplay 2>/dev/null || true)"
[ -n "$APLAY" ] && [ -x "$APLAY" ] || { say A1P5_AUDIO_ROUTE_PRIME=FAIL:APLAY_MISSING; exit 21; }
export SDL_AUDIODRIVER=alsa
say A1P5_AUDIO_ROUTE_PRIME=BEGIN
"$APLAY" -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 "$PRIME" >>"$LOG" 2>&1
RC=$?
say A1P5_AUDIO_ROUTE_PRIME_EXIT_CODE=$RC
[ "$RC" -eq 0 ] || { say A1P5_AUDIO_ROUTE_PRIME=FAIL:APLAY; exit 21; }
say A1P5_AUDIO_ROUTE_PRIME=PASS
exit 0
EOF_PRIME
chmod +x "$APPS/RG35XX-R1-AUDIO-ROUTE-PRIME.sh"

# The generic launcher owns all real-game starts. Prime immediately before JamVM.
python3 - "$APPS/FreeJ2ME-RG35XX.sh" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
if 'RG35XX-R1-AUDIO-ROUTE-PRIME.sh' in s:
    raise SystemExit(0)
anchor='RUNTIME_LIBS="$RUNTIME/lib/classpath:$RUNTIME/lib:"\n'
if anchor not in s: raise SystemExit('R4_GENERIC_ANCHOR_MISSING')
insert=anchor+'AUDIO_PRIME="$APPS/RG35XX-R1-AUDIO-ROUTE-PRIME.sh"\n[ -x "$AUDIO_PRIME" ] || fail AUDIO_ROUTE_PRIME_SCRIPT_MISSING\nRG35XX_AUDIO_ROUTE_LOG="${RG35XX_AUDIO_ROUTE_LOG:-/mnt/mmc/RG35XX-R1-AUDIO-ROUTE-PRIME.log}" "$AUDIO_PRIME" || fail AUDIO_ROUTE_PRIME_FAILED\nexport SDL_AUDIODRIVER=alsa\n'
p.write_text(s.replace(anchor,insert,1))
PY

# Full-platform campaign starts several JamVM processes through run_direct().
# Restore the accepted pre-Java route contract inside that helper so every
# direct Java process gets the exact Golden route setup immediately before JVM.
python3 - "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
if 'A1P5_AUDIO_ROUTE_PRIME_R4=ENABLED' in s:
    raise SystemExit(0)
anchor='RUNTIME_LIBS="$RUNTIME/lib/classpath:$RUNTIME/lib:"\n'
if anchor not in s: raise SystemExit('R4_P6_ANCHOR_MISSING')
block=anchor+'''AUDIO_PRIME="$APPS/RG35XX-R1-AUDIO-ROUTE-PRIME.sh"
[ -x "$AUDIO_PRIME" ] || { echo "FULL_PORT_R1_DEVICE=FAIL:AUDIO_ROUTE_PRIME_SCRIPT_MISSING" >> "$MASTER"; sync; exit 20; }
prime_audio(){
  RG35XX_AUDIO_ROUTE_LOG="$EVID/AUDIO-ROUTE-PRIME.log" "$AUDIO_PRIME" || { echo "FULL_PORT_R1_DEVICE=FAIL:AUDIO_ROUTE_PRIME" >> "$MASTER"; sync; exit 20; }
  export SDL_AUDIODRIVER=alsa
}
echo A1P5_AUDIO_ROUTE_PRIME_R4=ENABLED >> "$MASTER"
'''
s=s.replace(anchor,block,1)
needle='shift 4; set +e; LD_LIBRARY_PATH='
if needle not in s: raise SystemExit('R4_P6_RUN_DIRECT_ANCHOR_MISSING')
s=s.replace(needle,'shift 4; prime_audio; set +e; LD_LIBRARY_PATH=',1)
p.write_text(s)
print('R4_P6_PRIME_IN_RUN_DIRECT=PASS')
PY

# P7 delegates both Golden games to the generic launcher; no duplicate prime.
python3 - "$APPS/RG35XX-R1-P7-TIER0.sh" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
marker='P7_R4_AUDIO_ROUTE_OWNER=GENERIC_LAUNCHER\n'
if marker not in s:
    first='APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"\n'
    if first not in s: raise SystemExit('R4_P7_ANCHOR_MISSING')
    s=s.replace(first,first+'# P7_R4_AUDIO_ROUTE_OWNER=GENERIC_LAUNCHER\n',1)
p.write_text(s)
PY

chmod +x "$APPS/FreeJ2ME-RG35XX.sh" "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" "$APPS/RG35XX-R1-P7-TIER0.sh"

grep -q 'RG35XX-R1-AUDIO-ROUTE-PRIME.sh' "$APPS/FreeJ2ME-RG35XX.sh" || fail GENERIC_PRIME_GATE
grep -q 'A1P5_AUDIO_ROUTE_PRIME_R4=ENABLED' "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" || fail P6_PRIME_GATE
grep -q 'shift 4; prime_audio; set +e; LD_LIBRARY_PATH=' "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" || fail P6_RUN_DIRECT_PRIME_GATE
grep -q 'export SDL_AUDIODRIVER=alsa' "$APPS/FreeJ2ME-RG35XX.sh" || fail GENERIC_ALSA_GATE
grep -q 'export SDL_AUDIODRIVER=alsa' "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" || fail P6_ALSA_GATE

cat > "$BASE/AUDIO-ROUTE-R4-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
SCOPE=RG35XX_AUDIO_ROUTE_LAUNCHER_BOUNDARY_ONLY
PARENT_R3_SHA256=$EXPECTED_R3
FAILURE_EVIDENCE=P6_AUDIBLE_FAIL+GOW_GAMEPLAY_AUDIO_FAIL
GOLDEN_OWNER=A1P5_AUDIO_ROUTE_PRIME
PRIME_PCM_SHA256=$EXPECTED_PRIME
PRIME_PCM_SIZE=123480
PRIME_COMMAND=aplay_-q_-D_hw:0,0_-t_raw_-f_S32_LE_-c_2_-r_44100
SDL_AUDIODRIVER=alsa
PLATFORM_SHA256=$EXPECTED_PLATFORM
JAMVM_SHA256=$EXPECTED_JAMVM
GLIBJ_SHA256=$EXPECTED_GLIBJ
INPUT_SHA256=$EXPECTED_INPUT
VIDEO_SHA256=$EXPECTED_VIDEO
FONT_NATIVE_SHA256=$EXPECTED_FONT_NATIVE
AUDIO_SHA256=$EXPECTED_AUDIO
FONT_SHA256=$EXPECTED_FONT
CANONICAL_MMAPI=UNCHANGED
CANONICAL_PLATFORMPLAYER=UNCHANGED
CANONICAL_SDLMIXERMANAGER=UNCHANGED
RUNTIME_SEMANTIC_DELTA=NONE
NATIVE_AUDIO_DELTA=NONE
GAME_SPECIFIC_CODE=NO
P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
P7_PHYSICAL_REGRESSION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_ID

# Main payload changed only by the protected prime file; refresh its manifest.
(cd "$APP" && find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PAYLOAD-SHA256SUMS.txt)

FINALROOT="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4"
mkdir -p "$FINALROOT"
cp -R "$SD" "$FINALROOT/SD"
cp "$BASE/README-FIRST.txt" "$FINALROOT/README-FIRST.txt" 2>/dev/null || true
cp "$BASE/AUDIO-ROUTE-R4-IDENTITY.txt" "$FINALROOT/AUDIO-ROUTE-R4-IDENTITY.txt"
cat > "$FINALROOT/README-R4.txt" <<'EOF_README'
RG35XX Full Port R1 — R4 protected audio-route reconstruction.

R3 physical evidence:
- full programmatic P6 PASS;
- P6 audible WAV/MIDI FAIL;
- Vua physical PASS;
- God of War menu audio audible, gameplay audio FAIL.

R4 does not change canonical MMAPI, PlatformPlayer, SdlMixerManager, JamVM,
glibj, platform JAR, libaudio.so, input, video or font. It restores the exact
A1P5/A8 original-RG35XX pre-Java audio route contract already protected by the
Golden baseline: SDL_AUDIODRIVER=alsa plus 123480-byte zero PCM prime through
aplay hw:0,0 S32_LE stereo 44100 Hz.

Install by replacing the prior R1/R2/R3 APPS payload with SD/. Do not remove
Roms/JAVA. Run the full P6 campaign first. Audible WAV/MIDI is mandatory. Only
then run P7 and require God of War audio continuity into gameplay.
EOF_README

ZIP="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4.zip"
rm -f "$ZIP"
(cd "$OUT" && zip -qr "$(basename "$ZIP")" "$(basename "$FINALROOT")")
echo R1_AUDIO_ROUTE_R4_BUILD=PASS
echo R1_AUDIO_ROUTE_R4_PRIME_SHA256=$EXPECTED_PRIME
echo R1_AUDIO_ROUTE_R4_RUNTIME_SEMANTIC_DELTA=NONE
echo R1_AUDIO_ROUTE_R4_NATIVE_AUDIO_DELTA=NONE
echo R1_AUDIO_ROUTE_R4_ZIP="$ZIP"
echo R1_AUDIO_ROUTE_R4_ZIP_SHA256="$(sha256sum "$ZIP"|awk '{print $1}')"
echo P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
echo P7_PHYSICAL_REGRESSION=NOT_TESTED
echo DEVICE_PASS=NO
echo STABLE=NO
