#!/bin/sh
set -eu

# RGJ-RC1-011J deterministic assembly driver.
# Assemble into a disposable tree; never mutate the pinned upstream checkout.
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PIN_FREEJ2ME="13ec186903087156c145268f8706eecfaf9f1e50"
: "${RG35XX_FREEJ2ME_ROOT:?set RG35XX_FREEJ2ME_ROOT to the pinned FreeJ2ME checkout}"
: "${RG35XX_ASSEMBLY_ROOT:?set RG35XX_ASSEMBLY_ROOT to a disposable output directory}"
fail() { echo "RC1 ASSEMBLY: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 ASSEMBLY: $*"; }

[ -d "$RG35XX_FREEJ2ME_ROOT/.git" ] || fail "FreeJ2ME root is not a Git checkout"
HEAD=$(git -C "$RG35XX_FREEJ2ME_ROOT" rev-parse HEAD)
[ "$HEAD" = "$PIN_FREEJ2ME" ] || fail "FreeJ2ME HEAD $HEAD != pinned $PIN_FREEJ2ME"
[ "$RG35XX_ASSEMBLY_ROOT" != "$RG35XX_FREEJ2ME_ROOT" ] || fail "assembly root must not be the upstream checkout"
sh "$ROOT/scripts/rc1_prebuild_gate.sh" --build-ready

rm -rf "$RG35XX_ASSEMBLY_ROOT" && mkdir -p "$RG35XX_ASSEMBLY_ROOT"
( cd "$RG35XX_FREEJ2ME_ROOT" && tar --exclude=.git -cf - . ) | ( cd "$RG35XX_ASSEMBLY_ROOT" && tar -xf - )

mkdir -p "$RG35XX_ASSEMBLY_ROOT/src/org/recompile/mobile"
for src in "$ROOT"/src/org/recompile/mobile/RG35XX*.java; do [ -f "$src" ] && cp "$src" "$RG35XX_ASSEMBLY_ROOT/src/org/recompile/mobile/"; done
[ ! -e "$RG35XX_ASSEMBLY_ROOT/src/org/recompile/mobile/RG35XXFontEngine.java" ] || fail "superseded RG35XXFontEngine was assembled"

NATIVE_DST="$RG35XX_ASSEMBLY_ROOT/src/libretro/rg35xx"
mkdir -p "$NATIVE_DST/vendor/TinySoundFont"
for f in \
 rg35xx_audio_protocol.h rg35xx_media_cache.h rg35xx_media_cache.c rg35xx_media_events.h \
 rg35xx_media_event_queue.h rg35xx_media_event_queue.c rg35xx_audio_dispatch.h rg35xx_audio_dispatch.c \
 rg35xx_audio_pipe.h rg35xx_audio_pipe.c rg35xx_mixer.h rg35xx_mixer.c \
 rg35xx_midi_backend.h rg35xx_midi_backend.c rg35xx_tsf_worker.h rg35xx_tsf_worker.c \
 rg35xx_tsf_impl.c rg35xx_soundfont_source.h rg35xx_soundfont_source.c rg35xx_media_runtime.h rg35xx_media_runtime.c
do cp "$ROOT/native/$f" "$NATIVE_DST/$f"; done
cp "$ROOT/native/vendor/TinySoundFont/tml.h" "$NATIVE_DST/vendor/TinySoundFont/tml.h"
cp "$ROOT/native/vendor/TinySoundFont/tsf.h" "$NATIVE_DST/vendor/TinySoundFont/tsf.h"

# Apply only the authoritative active contracts. 0009 is superseded by 0021;
# 0012/0013 are superseded by the consolidated 0020 and must not be double-applied.
PATCH_ORDER="
0003-manager-rg35xx-media-profile.patch
0004-libretro-dedicated-audio-pipe.patch
0005-libretro-java-audio-bootstrap.patch
0006-platformplayer-native-backend.patch
0007-platformgraphics-rg35xx-fast-drawrgb.patch
0008-platformgraphics-transform-cache.patch
0010-libretro-platform-lifecycle.patch
0011-platformimage-rg35xx-cache.patch
0014-libretro-native-media-events.patch
0015-libretro-native-media-runtime.patch
0016-libretro-java-audio-fd-exact.patch
0017-libretro-media-process-boundary.patch
0018-manager-platformplayer-rg35xx-direct-media.patch
0019-platformplayer-tonecontrol-rg35xx.patch
0020-pinned-graphics-input-lifecycle-consolidation.patch
0021-pinned-rms-safe-baseline.patch
"
for p in $PATCH_ORDER; do
 [ -f "$ROOT/patches/$p" ] || fail "missing integration contract: $p"
 if patch -d "$RG35XX_ASSEMBLY_ROOT" -p1 --forward --dry-run < "$ROOT/patches/$p" >/dev/null 2>&1; then
   patch -d "$RG35XX_ASSEMBLY_ROOT" -p1 --forward < "$ROOT/patches/$p" >/dev/null
 else
   fail "integration contract does not apply cleanly at pinned source: $p"
 fi
done
[ -f "$ROOT/patches/0022-pinned-headless-font-peer-consolidation.patch" ] || fail "missing GNU Classpath font contract 0022"

cat > "$NATIVE_DST/rc1_sources.mk" <<'EOF'
RG35XX_NATIVE_SRCS := \
  rg35xx/rg35xx_media_cache.c \
  rg35xx/rg35xx_media_event_queue.c \
  rg35xx/rg35xx_audio_dispatch.c \
  rg35xx/rg35xx_audio_pipe.c \
  rg35xx/rg35xx_mixer.c \
  rg35xx/rg35xx_midi_backend.c \
  rg35xx/rg35xx_tsf_worker.c \
  rg35xx/rg35xx_tsf_impl.c \
  rg35xx/rg35xx_soundfont_source.c \
  rg35xx/rg35xx_media_runtime.c
RG35XX_NATIVE_CFLAGS := -Irg35xx -Irg35xx/vendor/TinySoundFont
EOF

[ "$(find "$RG35XX_ASSEMBLY_ROOT" -name RG35XXFontEngine.java | wc -l | tr -d ' ')" = 0 ] || fail "superseded font engine present"
[ "$(find "$RG35XX_ASSEMBLY_ROOT/src/libretro" -maxdepth 1 -name freej2me_libretro.c | wc -l | tr -d ' ')" = 1 ] || fail "expected one libretro core entrypoint"
TSF_COUNT=$(grep -l '^[[:space:]]*#define[[:space:]][[:space:]]*TSF_IMPLEMENTATION' "$NATIVE_DST"/*.c | wc -l | tr -d ' ')
TML_COUNT=$(grep -l '^[[:space:]]*#define[[:space:]][[:space:]]*TML_IMPLEMENTATION' "$NATIVE_DST"/*.c | wc -l | tr -d ' ')
[ "$TSF_COUNT" = 1 ] || fail "assembled TSF implementation owner count is $TSF_COUNT"
[ "$TML_COUNT" = 1 ] || fail "assembled TML implementation owner count is $TML_COUNT"
note "ASSEMBLY PASS: $RG35XX_ASSEMBLY_ROOT"
note "Next: apply GNU Classpath 0022 and integrate rc1_sources.mk into the pinned native Makefile; no BUILD-PASS claimed."
