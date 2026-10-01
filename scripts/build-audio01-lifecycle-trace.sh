#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "AUDIO01_BUILD_FAIL=$*" >&2; exit 1; }

BASE="$ROOT/out/a8-comp02-filltriangle-boundary"
DST="$ROOT/out/audio01-lifecycle-trace"
TRACE_SRC="$ROOT/build/audio01/rg35xx_audio_sdl1_mixer_trace.c"
ORIG_SRC="$ROOT/adapter/native/rg35xx_audio_sdl1_mixer.c"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"

EXPECTED_PLATFORM_SEMANTIC=a3e542cc0bb674396ee27684726cf79a726bdb03297e4c5792f1d9758f5c73cb
PHYSICAL_DEVICE_PLATFORM_RAW=3c7b22c3227a65897137c210744be1bcc41f075fa0dfa580fdcee7e47734056b
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO_PARENT=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
EXPECTED_SOURCE_BLOB=6c12bdf12e16e9ddfbdecf0e60e1330dcc4bcacc

semantic_digest() {
python3 - "$1" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in sorted(z.namelist()):
        b=z.read(n); nb=n.encode('utf-8')
        h.update(struct.pack('>I',len(nb))); h.update(nb)
        h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
}

for f in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so; do
  [ -f "$BASE/$f" ] || fail "COMP02 artifact missing: $f"
done
BASE_RAW="$(sha256sum "$BASE/freej2me-rg35xx.jar"|awk '{print $1}')"
BASE_SEMANTIC="$(semantic_digest "$BASE/freej2me-rg35xx.jar")"
[ "$BASE_SEMANTIC" = "$EXPECTED_PLATFORM_SEMANTIC" ] || fail PLATFORM_SEMANTIC_IDENTITY
[ "$(sha256sum "$BASE/librg35xx_input.so"|awk '{print $1}')" = "$EXPECTED_INPUT" ] || fail INPUT_IDENTITY
[ "$(sha256sum "$BASE/librg35xx_video.so"|awk '{print $1}')" = "$EXPECTED_VIDEO" ] || fail VIDEO_IDENTITY
[ "$(sha256sum "$BASE/libaudio.so"|awk '{print $1}')" = "$EXPECTED_AUDIO_PARENT" ] || fail AUDIO_PARENT_IDENTITY
[ "$(git hash-object "$ORIG_SRC")" = "$EXPECTED_SOURCE_BLOB" ] || fail AUDIO_SOURCE_IDENTITY

echo "AUDIO01_REBUILT_PLATFORM_RAW=$BASE_RAW"
echo "AUDIO01_REBUILT_PLATFORM_SEMANTIC=$BASE_SEMANTIC"
echo AUDIO01_PARENT_IDENTITY_GATE=PASS
python3 "$ROOT/scripts/stage-audio01-lifecycle-trace.py" "$ROOT"
[ -f "$TRACE_SRC" ] || fail TRACE_SOURCE_MISSING

rm -rf "$DST"
mkdir -p "$DST"
cp "$BASE/freej2me-rg35xx.jar" "$DST/"
cp "$BASE/librg35xx_input.so" "$DST/"
cp "$BASE/librg35xx_video.so" "$DST/"

CC="${CC:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc}"
READELF="${READELF:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-readelf}"
STRIP="${STRIP:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-strip}"
[ -x "$CC" ] || fail "cross compiler missing: $CC"
[ -x "$READELF" ] || fail "readelf missing: $READELF"
[ -x "$STRIP" ] || fail "strip missing: $STRIP"
JNI="$UPSTREAM/cpp/native/include"

"$CC" -shared -fPIC -Os -pipe -fno-strict-aliasing \
  -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft \
  -Wall -Wextra -I"$JNI" -I"$JNI/linux" \
  "$TRACE_SRC" -Wl,--as-needed -ldl -o "$DST/libaudio.so"
"$STRIP" "$DST/libaudio.so"

"$READELF" -h "$DST/libaudio.so" > "$DST/libaudio.so.elf.txt"
"$READELF" -A "$DST/libaudio.so" > "$DST/libaudio.so.attr.txt" || true
"$READELF" -Ws "$DST/libaudio.so" > "$DST/libaudio.so.symbols.txt"
grep -q 'Class:.*ELF32' "$DST/libaudio.so.elf.txt" || fail AUDIO_NOT_ELF32
grep -q 'Machine:.*ARM' "$DST/libaudio.so.elf.txt" || fail AUDIO_NOT_ARM
grep -q 'Version5 EABI' "$DST/libaudio.so.elf.txt" || fail AUDIO_NOT_EABI5
grep -q 'soft-float ABI' "$DST/libaudio.so.elf.txt" || fail AUDIO_NOT_SOFTFLOAT
for sym in \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerInit \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadWav \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerPlayMusic \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerPlayWav \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit; do
  grep -q "$sym" "$DST/libaudio.so.symbols.txt" || fail "missing JNI symbol $sym"
done
strings "$DST/libaudio.so" | grep -q 'RG35XX_AUDIO01_TRACE' || fail TRACE_MARKER_MISSING
strings "$DST/libaudio.so" | grep -q 'PLAY_MIDI_BEFORE_HALT' || fail TRACE_PLAY_MARKER_MISSING
strings "$DST/libaudio.so" | grep -q 'CALLBACK_BEGIN' || fail TRACE_CALLBACK_MARKER_MISSING
strings "$DST/libaudio.so" | grep -q '/usr/lib/libSDL_mixer-1.2.so.0' || fail SDL1_MIXER_IDENTITY_MISSING
if strings "$DST/libaudio.so" | grep -q 'libSDL2'; then fail SDL2_CONTAMINATION; fi
TRACE_AUDIO_SHA="$(sha256sum "$DST/libaudio.so"|awk '{print $1}')"
[ "$TRACE_AUDIO_SHA" != "$EXPECTED_AUDIO_PARENT" ] || fail TRACE_BINARY_UNCHANGED

head -c 123480 /dev/zero > "$DST/a7-a1p5-rw-silence-prime.s32le"
[ "$(sha256sum "$DST/a7-a1p5-rw-silence-prime.s32le"|awk '{print $1}')" = "$EXPECTED_PRIME" ] || fail PRIME_IDENTITY

cat > "$DST/RUNTIME-SHA256SUMS.txt" <<EOF
$BASE_RAW  freej2me-rg35xx.jar
$EXPECTED_INPUT  librg35xx_input.so
$EXPECTED_VIDEO  librg35xx_video.so
$TRACE_AUDIO_SHA  libaudio.so
$EXPECTED_PRIME  a7-a1p5-rw-silence-prime.s32le
EOF
(cd "$DST" && sha256sum -c RUNTIME-SHA256SUMS.txt)

cat > "$DST/AUDIO01-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=AUDIO01-LIFECYCLE-TRACE-ONLY
BASE_BRANCH=a8-comp02-filltriangle-boundary-only
BASE_COMMIT=e373f3b59423aa7aec5deee8563f0b5ff3a191cb
FAILURE_OWNER=RG35XX_AUDIO_MEDIA
PURPOSE=TRACE_MMAPI_MIDI_WAV_LIFECYCLE_ONLY
TRACE_EVENTS=LOAD,PLAY_BEFORE_HALT,PLAY_AFTER_HALT,PLAY_AFTER_PLAY,PAUSE,RESUME,STOP,ISPLAYING,FREE,CALLBACK,QUIT
PLATFORM_REBUILD_RAW_SHA256=$BASE_RAW
PLATFORM_SEMANTIC_SHA256=$BASE_SEMANTIC
PHYSICAL_DEVICE_PLATFORM_REQUIRED_SHA256=$PHYSICAL_DEVICE_PLATFORM_RAW
INPUT_NATIVE_SHA256=$EXPECTED_INPUT
VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
AUDIO_PARENT_SHA256=$EXPECTED_AUDIO_PARENT
AUDIO_TRACE_SHA256=$TRACE_AUDIO_SHA
PRIME_PCM_SHA256=$EXPECTED_PRIME
AUDIO_SOURCE_GIT_BLOB=$EXPECTED_SOURCE_BLOB
JAVA_CHANGED=NO
GRAPHICS_CHANGED=NO
INPUT_CHANGED=NO
VIDEO_CHANGED=NO
AUDIO_PLAYBACK_CONTROL_FLOW_INTENDED_DELTA=NONE_TRACE_ONLY
GAME_SPECIFIC_RUNTIME_CODE=NO
DIAGNOSTIC_ONLY=YES
BUILD_PASS=YES
DEVICE_PASS=NO
STABLE=NO
EOF

(cd "$DST" && find . -maxdepth 1 -type f ! -name AUDIO01-SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum) > "$DST/AUDIO01-SHA256SUMS.txt"
(cd "$DST" && sha256sum -c AUDIO01-SHA256SUMS.txt)
echo AUDIO01_LIFECYCLE_TRACE_BUILD=PASS
cat "$DST/AUDIO01-IDENTITY.txt"
