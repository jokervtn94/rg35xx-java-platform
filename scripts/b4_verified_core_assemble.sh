#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${VC_UPSTREAM:?set VC_UPSTREAM to pinned FreeJ2ME checkout}"
: "${B4_ASSEMBLY:?set B4_ASSEMBLY to disposable B4 output directory}"

fail() { echo "B4 ASSEMBLY FAIL: $*" >&2; exit 1; }
note() { echo "B4 ASSEMBLY: $*"; }

# Start from the exact verified-clean VC0-VC3 source assembly.
VC_UPSTREAM="$VC_UPSTREAM" VC_ASSEMBLY="$B4_ASSEMBLY" sh "$ROOT/scripts/vc0_vc3_assemble.sh"

CORE="$B4_ASSEMBLY/src/libretro/freej2me_libretro.c"
[ -f "$CORE" ] || fail "assembled core source missing"

# B4 adds observability only.
python3 "$ROOT/scripts/b4_apply_early_native_log.py" "$CORE"

# Positive observability contract.
for marker in \
  'RG35XX_B4_EARLY_LOG' \
  'B4 CORE_INIT' \
  'B4 RUNTIME_PATH' \
  'B4 JAVA_OPEN_BEGIN' \
  'B4 PIPE_CREATE' \
  'B4 FORK_RESULT' \
  'B4 CHILD_PRE_EXEC' \
  'B4 CHILD_EXEC_FAIL' \
  'B4 JAVA_READY' \
  'B4 LOAD_GAME_ENTER' \
  'B4 GAME_PATH' \
  'B4 IPC_LOAD_SENT' \
  'B4 IPC_RUN_SENT' \
  'B4 CORE_DEINIT'
do
  grep -Fq "$marker" "$CORE" || fail "missing marker: $marker"
done

# Existing verified foundation must remain intact.
for marker in \
  'RETRO_PIXEL_FORMAT_RGB565' \
  'rg35xx_golden_video_start()' \
  'rg35xx_golden_video_present(' \
  '/mnt/mmc/CFW/java/bin/jamvm' \
  '/mnt/mmc/freej2me-java-error.log'
do
  grep -Fq "$marker" "$CORE" || fail "foundation token lost: $marker"
done

grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' \
  "$B4_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java" || fail "lazy media lost"
grep -Fq 'RG35XXGoldenFrameTransport' \
  "$B4_ASSEMBLY/src/org/recompile/freej2me/Libretro.java" || fail "Golden Java transport lost"

# No compatibility/font/audio/resolution experiment is admitted by B4.
for bad in \
  'RG35XX-PNG-COMPAT' \
  'rg35xxStripPngICCP' \
  'RG35XX-PNG-COMPAT-V2' \
  'RG35XX-CV:' \
  'rg35xx_cv_launch_java' \
  'rg35xx_cv_resolution_from_path' \
  'RG35XX-MediaWarmup'
do
  if grep -R -Fq "$bad" "$B4_ASSEMBLY/src"; then
    fail "unadmitted feature survived: $bad"
  fi
done

note "PASS: B4 source assembled at $B4_ASSEMBLY"
