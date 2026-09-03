#!/bin/sh
set -eu

# RC1 source-consolidation prebuild gate.
# Default: verify project-owned source/registry invariants.
# --build-ready: additionally require exact external build inputs.

MODE="${1:---project-static}"
case "$MODE" in
  --project-static|--build-ready) ;;
  *) echo "usage: sh scripts/rc1_prebuild_gate.sh [--project-static|--build-ready]" >&2; exit 2 ;;
esac

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PIN_FREEJ2ME="13ec186903087156c145268f8706eecfaf9f1e50"
PIN_SOUNDFONT_COMMIT="684543d5e5efaef08d02be50dcda8d552478fa60"
PIN_SOUNDFONT_BLOB="298b552d2e9d1307e03e5c5c99d2c046aaed9ec3"
PIN_SOUNDFONT_SIZE="32319396"

fail() { echo "RC1 PREBUILD GATE: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 PREBUILD GATE: $*"; }
require_file() { [ -f "$ROOT/$1" ] || fail "missing project source: $1"; }

require_file tasklog/TASKLOG.md
require_file tasklog/RC1-TASKLOG.md
require_file docs/PLATFORM-SOURCE-REGISTRY.md
require_file docs/RC1-INTEGRATION-MANIFEST.md
require_file docs/RC1-EXTERNAL-RUNTIME-ASSEMBLY.md

for f in \
  RG35XXPlatformProfile RG35XXFrameScheduler RG35XXImageCache RG35XXInputEngine \
  RG35XXWavDecoder RG35XXMediaProfile RG35XXMediaRegistry RG35XXAudioProtocol \
  RG35XXAudioTransport RG35XXAudioBootstrap RG35XXNativePlayer \
  RG35XXToneSequenceEncoder RG35XXTransformCache RG35XXRmsCoordinator \
  RG35XXRmsAtomicFile RG35XXLifecycle
do
  require_file "src/org/recompile/mobile/$f.java"
done
[ ! -e "$ROOT/src/org/recompile/mobile/RG35XXFontEngine.java" ] || \
  fail "superseded RG35XXFontEngine.java was reintroduced without a REVERT/REPLACE task"

for f in \
  rg35xx_audio_protocol.h \
  rg35xx_media_cache.h rg35xx_media_cache.c \
  rg35xx_media_events.h \
  rg35xx_media_event_queue.h rg35xx_media_event_queue.c \
  rg35xx_audio_dispatch.h rg35xx_audio_dispatch.c \
  rg35xx_audio_pipe.h rg35xx_audio_pipe.c \
  rg35xx_mixer.h rg35xx_mixer.c \
  rg35xx_midi_backend.h rg35xx_midi_backend.c \
  rg35xx_tsf_worker.h rg35xx_tsf_worker.c rg35xx_tsf_impl.c \
  rg35xx_soundfont_source.h rg35xx_soundfont_source.c \
  rg35xx_media_runtime.h rg35xx_media_runtime.c
do
  require_file "native/$f"
done

TSF_OWNER_COUNT=$(grep -l '^[[:space:]]*#define[[:space:]][[:space:]]*TSF_IMPLEMENTATION' "$ROOT"/native/*.c 2>/dev/null | wc -l | tr -d ' ')
TML_OWNER_COUNT=$(grep -l '^[[:space:]]*#define[[:space:]][[:space:]]*TML_IMPLEMENTATION' "$ROOT"/native/*.c 2>/dev/null | wc -l | tr -d ' ')
[ "$TSF_OWNER_COUNT" = "1" ] || fail "expected exactly one TSF_IMPLEMENTATION owner, found $TSF_OWNER_COUNT"
[ "$TML_OWNER_COUNT" = "1" ] || fail "expected exactly one TML_IMPLEMENTATION owner, found $TML_OWNER_COUNT"
grep -q 'TSF_IMPLEMENTATION' "$ROOT/native/rg35xx_tsf_impl.c" || fail "TSF owner is not rg35xx_tsf_impl.c"
grep -q 'TML_IMPLEMENTATION' "$ROOT/native/rg35xx_tsf_impl.c" || fail "TML owner is not rg35xx_tsf_impl.c"

for p in \
  0020-pinned-graphics-input-lifecycle-consolidation.patch \
  0021-pinned-rms-safe-baseline.patch \
  0022-pinned-headless-font-peer-consolidation.patch
do
  require_file "patches/$p"
done

require_file native/verify_tinysoundfont_vendor.sh
require_file native/vendor_tinysoundfont.sh

if [ -f "$ROOT/native/vendor/TinySoundFont/tml.h" ] || [ -f "$ROOT/native/vendor/TinySoundFont/tsf.h" ]; then
  sh "$ROOT/native/verify_tinysoundfont_vendor.sh" || fail "vendored TinySoundFont identity check failed"
else
  note "BLOCKER: exact TML/TSF headers are not materialized yet"
  [ "$MODE" != "--build-ready" ] || fail "build-ready requires exact vendored TML/TSF headers"
fi

if [ "$MODE" = "--build-ready" ]; then
  : "${RG35XX_FREEJ2ME_ROOT:?set RG35XX_FREEJ2ME_ROOT to the exact pinned FreeJ2ME checkout}"
  : "${RG35XX_CLASSPATH_ROOT:?set RG35XX_CLASSPATH_ROOT to the GNU Classpath 0.99 source tree}"
  : "${RG35XX_FONT_FILE:?set RG35XX_FONT_FILE to the authoritative target TTF/OTF resource}"
  : "${RG35XX_SOUNDFONT_FILE:?set RG35XX_SOUNDFONT_FILE to GeneralUser-GS.sf2 from pinned commit $PIN_SOUNDFONT_COMMIT}"

  [ -d "$RG35XX_FREEJ2ME_ROOT/.git" ] || fail "RG35XX_FREEJ2ME_ROOT is not a Git checkout"
  FREEJ2ME_HEAD=$(git -C "$RG35XX_FREEJ2ME_ROOT" rev-parse HEAD)
  [ "$FREEJ2ME_HEAD" = "$PIN_FREEJ2ME" ] || fail "FreeJ2ME HEAD $FREEJ2ME_HEAD != pinned $PIN_FREEJ2ME"

  [ -f "$RG35XX_FREEJ2ME_ROOT/src/org/recompile/mobile/PlatformGraphics.java" ] || fail "pinned PlatformGraphics.java missing"
  [ -f "$RG35XX_FREEJ2ME_ROOT/src/org/recompile/mobile/PlatformFont.java" ] || fail "pinned PlatformFont.java missing"
  [ -f "$RG35XX_FREEJ2ME_ROOT/src/org/recompile/mobile/PlatformImage.java" ] || fail "pinned PlatformImage.java missing"
  [ -f "$RG35XX_FREEJ2ME_ROOT/src/org/recompile/mobile/MobilePlatform.java" ] || fail "pinned MobilePlatform.java missing"
  [ -f "$RG35XX_FREEJ2ME_ROOT/src/org/recompile/freej2me/Libretro.java" ] || fail "pinned Libretro.java missing"
  [ -f "$RG35XX_FREEJ2ME_ROOT/src/libretro/freej2me_libretro.c" ] || fail "pinned freej2me_libretro.c missing"

  [ -f "$RG35XX_CLASSPATH_ROOT/gnu/java/awt/peer/headless/HeadlessToolkit.java" ] || fail "GNU Classpath HeadlessToolkit.java missing"
  [ -s "$RG35XX_FONT_FILE" ] || fail "authoritative target font resource is missing/empty"
  [ -s "$RG35XX_SOUNDFONT_FILE" ] || fail "authoritative SoundFont file is missing/empty"

  SOUNDFONT_SIZE=$(wc -c < "$RG35XX_SOUNDFONT_FILE" | tr -d ' ')
  [ "$SOUNDFONT_SIZE" = "$PIN_SOUNDFONT_SIZE" ] || fail "SoundFont size $SOUNDFONT_SIZE != pinned $PIN_SOUNDFONT_SIZE"
  SOUNDFONT_BLOB=$(git hash-object "$RG35XX_SOUNDFONT_FILE")
  [ "$SOUNDFONT_BLOB" = "$PIN_SOUNDFONT_BLOB" ] || fail "SoundFont blob $SOUNDFONT_BLOB != pinned $PIN_SOUNDFONT_BLOB"

  note "BUILD-INPUT PRECHECK PASS — this authorizes source assembly/build attempts, not BUILD-PASS"
else
  note "PROJECT STATIC PASS — external build inputs may still be blocked"
fi
