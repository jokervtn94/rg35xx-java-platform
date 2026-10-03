#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A7_AUDIO_NATIVE_BUILD_FAIL=$*" >&2; exit 1; }

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
DST="$ROOT/out/a7-audio-sdl1"
SRC="$ROOT/adapter/native/rg35xx_audio_sdl1_mixer.c"
[ -f "$DST/freej2me-rg35xx.jar" ] || fail "run build-a7-audio-java.sh first"
[ -f "$SRC" ] || fail "audio source missing"

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
  "$SRC" -Wl,--as-needed -ldl -o "$DST/libaudio.so"
"$STRIP" "$DST/libaudio.so"

"$READELF" -h "$DST/libaudio.so" > "$DST/libaudio.so.elf.txt"
"$READELF" -A "$DST/libaudio.so" > "$DST/libaudio.so.attr.txt" || true
"$READELF" -Ws "$DST/libaudio.so" > "$DST/libaudio.so.symbols.txt"
"$READELF" -d "$DST/libaudio.so" > "$DST/libaudio.so.dynamic.txt"

grep -q 'Class:.*ELF32' "$DST/libaudio.so.elf.txt" || fail "audio not ELF32"
grep -q 'Machine:.*ARM' "$DST/libaudio.so.elf.txt" || fail "audio not ARM"
grep -q 'Version5 EABI' "$DST/libaudio.so.elf.txt" || fail "audio not EABI5"
grep -q 'soft-float ABI' "$DST/libaudio.so.elf.txt" || fail "audio not soft-float ABI"
for sym in \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerInit \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadWav \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerPlayMusic \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerPlayWav \
  Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit; do
  grep -q "$sym" "$DST/libaudio.so.symbols.txt" || fail "missing JNI symbol $sym"
done
strings "$DST/libaudio.so" | grep -q '/usr/lib/libSDL_mixer-1.2.so.0' || fail "SDL1_mixer device identity missing"
strings "$DST/libaudio.so" | grep -q 'RG35XX_A7_AUDIO_INIT=PASS' || fail "A7 audio marker missing"
if strings "$DST/libaudio.so" | grep -q 'libSDL2'; then fail "SDL2_mixer contamination"; fi
if strings "$DST/libaudio.so" | grep -Eq 'MidiSystem|getSequencer|AudioSystem|getClip|/dev/snd/seq'; then
  fail "forbidden JavaSound/seq contamination"
fi

AUDIO_SHA="$(sha256sum "$DST/libaudio.so" | awk '{print $1}')"
SOURCE_SHA="$(sha256sum "$SRC" | awk '{print $1}')"
python3 - "$DST/A7-AUDIO-IDENTITY.txt" "$AUDIO_SHA" "$SOURCE_SHA" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); audio=sys.argv[2]; source=sys.argv[3]
s=p.read_text(encoding='utf-8')
s=s.replace('A7_AUDIO_NATIVE_SHA256=PENDING_NATIVE_BUILD', 'A7_AUDIO_NATIVE_SHA256='+audio)
s=s.replace('BUILD-PASS=NO_PENDING_NATIVE', 'A7_AUDIO_SOURCE_SHA256='+source+'\nA7_AUDIO_NATIVE_ABI=ARMV5TE_SOFT_FLOAT\nA7_AUDIO_SDL2_CONTAMINATION=NO\nBUILD-PASS=YES')
p.write_text(s,encoding='utf-8')
PY

(cd "$DST" && find . -maxdepth 1 -type f ! -name A7-ARTIFACT-SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum) > "$DST/A7-ARTIFACT-SHA256SUMS.txt"
(cd "$DST" && sha256sum -c A7-ARTIFACT-SHA256SUMS.txt)
echo A7_AUDIO_NATIVE_BUILD=PASS
cat "$DST/A7-AUDIO-IDENTITY.txt"
