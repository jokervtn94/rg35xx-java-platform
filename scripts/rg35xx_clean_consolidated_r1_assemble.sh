#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${VC_UPSTREAM:?set VC_UPSTREAM to pinned FreeJ2ME checkout}"
: "${R1_ASSEMBLY:?set R1_ASSEMBLY to disposable output directory}"

fail() { echo "RG35XX CLEAN R1 FAIL: $*" >&2; exit 1; }
note() { echo "RG35XX CLEAN R1: $*"; }

# Always reconstruct from the exact verified-clean B4 source foundation.
VC_UPSTREAM="$VC_UPSTREAM" B4_ASSEMBLY="$R1_ASSEMBLY" sh "$ROOT/scripts/b4_verified_core_assemble.sh"

IMAGE="$R1_ASSEMBLY/src/org/recompile/mobile/PlatformImage.java"
GRAPHICS="$R1_ASSEMBLY/src/org/recompile/mobile/PlatformGraphics.java"
LIBRETRO="$R1_ASSEMBLY/src/org/recompile/freej2me/Libretro.java"
TRANSPORT="$R1_ASSEMBLY/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
MOBILE="$R1_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java"

for p in "$IMAGE" "$GRAPHICS" "$LIBRETRO" "$TRANSPORT" "$MOBILE"; do
  [ -f "$p" ] || fail "missing required source: $p"
done

# 1. Device-exercised source-level PNG iCCP compatibility.
python3 "$ROOT/scripts/vc6_apply_png_iccp_compat.py" "$IMAGE"

# 2. Device-proven logical-view restoration; physical output remains native Smart-Fit.
python3 "$ROOT/scripts/vc7r2_apply_proven_dynamic_view.py" "$LIBRETRO"

# 3. Device-PASS RG35XX LCD software-mask bypass.
python3 "$ROOT/scripts/b4_apply_nomask_green_tint_fix.py" "$GRAPHICS"
python3 "$ROOT/scripts/b4_apply_nomask_hard_bypass.py" "$GRAPHICS"

# 4. Device-PASS removal of unbounded per-frame Java diagnostics.
python3 "$ROOT/scripts/b4_apply_hotpath_r2_cleanup.py" "$TRANSPORT"

# 5. Bind the current framebuffer object and its current int[] together.
python3 "$ROOT/scripts/b4_apply_canonical_framebuffer_r1.py" "$LIBRETRO"

# Foundation gates.
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' "$MOBILE" || fail "lazy media lost"
grep -Fq 'RG35XXGoldenFrameTransport' "$LIBRETRO" || fail "Golden transport lost"
grep -Fq 'rg35xxFrames.requestFrame(lcdWidth, lcdHeight, current, front);' "$LIBRETRO" || fail "canonical current frame request missing"
grep -Fq 'rg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, current, front);' "$LIBRETRO" || fail "canonical current control frame missing"
! grep -Fq 'requestFrame(lcdWidth, lcdHeight, lcdData' "$LIBRETRO" || fail "stale cached frame request remains"
! grep -Fq 'sendControlFrame(lcdWidth, lcdHeight, lcdData' "$LIBRETRO" || fail "stale cached control frame remains"

# PNG gates.
grep -Fq 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk' "$IMAGE" || fail "PNG iCCP marker missing"
[ "$(grep -Fc 'ImageIO.read(rg35xxPngIccpCompat(stream))' "$IMAGE")" -eq 3 ] || fail "PNG decode boundary count mismatch"
! grep -Fq 'ImageIO.read(stream)' "$IMAGE" || fail "unguarded ImageIO stream boundary remains"

# Dynamic-view gates.
grep -Fq 'RG35XX-VC7R2-VIEW:' "$LIBRETRO" || fail "dynamic-view marker missing"
grep -Fq 'rg35xxReassertFilenameLogicalSize("before-run")' "$LIBRETRO" || fail "before-run dynamic view missing"
grep -Fq 'rg35xxCaptureFilenameLogicalSize(path);' "$LIBRETRO" || fail "filename logical-size capture missing"

# Mask gates.
grep -Fq 'fastBlit = !Mobile.funLightsEnabled;' "$GRAPHICS" || fail "hard mask bypass missing"
grep -Fq 'canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i];' "$GRAPHICS" || fail "unmasked copy path missing"
! grep -Fq 'image.getDataBuffer()[srcRowIndex + i] & Mobile.lcdMaskColors[Mobile.maskIndex]' "$GRAPHICS" || fail "software LCD mask still applied"

# Hotpath gates.
grep -Fq 'RG35XX-B4-HOTPATH-R2-CLEAN' "$TRANSPORT" || fail "hotpath cleanup marker missing"
for bad in   'RG35XX-JAVA-DIAG: requestFrame ENTER'   'RG35XX-JAVA-DIAG: requestFrame SIGNALED'   'RG35XX-JAVA-DIAG: FrameWorker WAKE'   'RG35XX-JAVA-DIAG: sendFrame START pixels='   'RG35XX-JAVA-DIAG: RGB565 ENCODED bytes='   'RG35XX-JAVA-DIAG: IPC FLUSH PASS error='
do
  ! grep -Fq "$bad" "$TRANSPORT" || fail "unbounded hotpath marker survived: $bad"
done

for keep in   'RG35XX-JAVA-DIAG: FrameTransport constructor ENTER'   'RG35XX-JAVA-DIAG: FrameWorker ENTER'   'RG35XX-JAVA-DIAG: FrameWorker EXIT'   'RG35XX-VIDEO JAVA control-frame error:'   'RG35XX-VIDEO JAVA worker error:'
do
  grep -Fq "$keep" "$TRANSPORT" || fail "required bounded/error marker lost: $keep"
done

# Canonical framebuffer diagnostics are bounded (first 16/change/mismatch).
grep -Fq 'RG35XX-B4-FRAME-BIND stage=' "$LIBRETRO" || fail "frame-bind marker missing"
grep -Fq 'rg35xxB4FrameBindSeq <= 16 || changed || mismatch' "$LIBRETRO" || fail "frame-bind logging is not bounded"

# No rejected experiments/owners may leak into this source assembly.
for bad in   'RG35XX-CV:'   'rg35xx_cv_launch_java'   'rg35xx_cv_resolution_from_path'   'RG35XX-MediaWarmup'
do
  if grep -R -Fq "$bad" "$R1_ASSEMBLY/src"; then
    fail "forbidden experiment survived: $bad"
  fi
done

note "PASS: clean consolidated R1 source at $R1_ASSEMBLY"
