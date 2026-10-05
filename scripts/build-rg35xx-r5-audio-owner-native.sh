#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/adapter/native/rg35xx_audio_sdl1_mixer_r5_owner.c"
OUT="$ROOT/out/r5-audio-owner-native"
CC="${CC:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc}"
READELF="${READELF:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-readelf}"
STRIP="${STRIP:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-strip}"
JNI="$ROOT/upstream/freej2me-miyoomini/cpp/native/include"
fail(){ echo "R5_AUDIO_NATIVE_BUILD_FAIL=$*" >&2; exit 2; }
[ -f "$SRC" ] || fail SOURCE_MISSING
[ -x "$CC" ] && [ -x "$READELF" ] && [ -x "$STRIP" ] || fail TOOLCHAIN_MISSING
rm -rf "$OUT"; mkdir -p "$OUT"
"$CC" -shared -fPIC -Os -pipe -fno-strict-aliasing \
  -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft \
  -Wall -Wextra -I"$JNI" -I"$JNI/linux" \
  "$SRC" -Wl,--as-needed -ldl -o "$OUT/libaudio.so"
"$STRIP" "$OUT/libaudio.so"
"$READELF" -h "$OUT/libaudio.so" >"$OUT/libaudio.so.elf.txt"
"$READELF" -A "$OUT/libaudio.so" >"$OUT/libaudio.so.attr.txt" || true
"$READELF" -Ws "$OUT/libaudio.so" >"$OUT/libaudio.so.symbols.txt"
grep -q 'Class:.*ELF32' "$OUT/libaudio.so.elf.txt" || fail NOT_ELF32
grep -q 'Machine:.*ARM' "$OUT/libaudio.so.elf.txt" || fail NOT_ARM
grep -q 'Version5 EABI' "$OUT/libaudio.so.elf.txt" || fail NOT_EABI5
grep -q 'soft-float ABI' "$OUT/libaudio.so.elf.txt" || fail NOT_SOFT_FLOAT
for sym in \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerPlayMusic \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeMusic \
 Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit; do
  grep -q "$sym" "$OUT/libaudio.so.symbols.txt" || fail "MISSING_SYMBOL:$sym"
done
strings "$OUT/libaudio.so" | grep -q 'RG35XX_R5_AUDIO_OWNER_BIND=PASS' || fail OWNER_BIND_MARKER
strings "$OUT/libaudio.so" | grep -q 'RG35XX_R5_AUDIO_OWNER_RESUME=IGNORED_NONOWNER' || fail OWNER_RESUME_MARKER
strings "$OUT/libaudio.so" | grep -q 'postmix_cb=' || fail POSTMIX_TRACE_MARKER
strings "$OUT/libaudio.so" | grep -q 'postmix_last_peak=' || fail POSTMIX_PEAK_TRACE_MARKER
strings "$OUT/libaudio.so" | grep -q 'spec.actual' || fail MIX_SPEC_TRACE_MARKER
strings "$OUT/libaudio.so" | grep -q '/usr/lib/libSDL_mixer-1.2.so.0' || fail SDL1_MIXER_IDENTITY
! strings "$OUT/libaudio.so" | grep -Eq 'libSDL2|MidiSystem|getSequencer|AudioSystem|getClip|/dev/snd/seq' || fail FORBIDDEN_BACKEND
sha256sum "$OUT/libaudio.so" >"$OUT/libaudio.so.sha256"
echo R5_AUDIO_NATIVE_BUILD=PASS
echo R5_AUDIO_NATIVE_SHA256=$(awk '{print $1}' "$OUT/libaudio.so.sha256")
echo R5_AUDIO_NATIVE_SCOPE=SDL1_MIXER_PLAYER_MANAGER_OWNERSHIP_AND_POSTMIX_DIAGNOSTIC
