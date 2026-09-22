#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${VC_UPSTREAM:?set VC_UPSTREAM to pinned FreeJ2ME checkout}"
: "${R2A_ASSEMBLY:?set R2A_ASSEMBLY to disposable output directory}"

fail(){ echo "RG35XX CLEAN R2A FAIL: $*" >&2; exit 1; }
note(){ echo "RG35XX CLEAN R2A: $*"; }

# R2A MUST inherit the exact current R1 source contract.
VC_UPSTREAM="$VC_UPSTREAM" R1_ASSEMBLY="$R2A_ASSEMBLY"   sh "$ROOT/scripts/rg35xx_clean_consolidated_r1_assemble.sh"

IMAGE="$R2A_ASSEMBLY/src/org/recompile/mobile/PlatformImage.java"
GRAPHICS="$R2A_ASSEMBLY/src/org/recompile/mobile/PlatformGraphics.java"
CANVAS="$R2A_ASSEMBLY/src/javax/microedition/lcdui/Canvas.java"
PLAYER="$R2A_ASSEMBLY/src/org/recompile/mobile/PlatformPlayer.java"
CORE="$R2A_ASSEMBLY/src/libretro/freej2me_libretro.c"

for p in "$IMAGE" "$GRAPHICS" "$CANVAS" "$PLAYER" "$CORE"; do
  [ -f "$p" ] || fail "missing required source: $p"
done

# Single R2A behavior change.
python3 "$ROOT/scripts/r2_apply_headless_image_normalize.py" "$IMAGE"

# Positive R1 inheritance gates.
grep -Fq 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk' "$IMAGE" || fail "R1 PNG iCCP lost"
grep -Fq 'RG35XX-VC7R2-VIEW:' "$R2A_ASSEMBLY/src/org/recompile/freej2me/Libretro.java" || fail "R1 dynamic view lost"
grep -Fq 'RG35XX-B4-FRAME-BIND stage=' "$R2A_ASSEMBLY/src/org/recompile/freej2me/Libretro.java" || fail "R1 frame bind lost"
grep -Fq 'RG35XX-B4-HOTPATH-R2-CLEAN' "$R2A_ASSEMBLY/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java" || fail "R1 hotpath cleanup lost"
grep -Fq 'fastBlit = !Mobile.funLightsEnabled;' "$GRAPHICS" || fail "R1 LCD mask bypass lost"
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' "$R2A_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java" || fail "R1 lazy media lost"

# R2A image contract.
[ "$(grep -Fc 'rg35xxR2ANormalizeDecodedImage(image);' "$IMAGE")" -eq 3 ] || fail "R2A normalize call count mismatch"
grep -Fq 'image.getRGB(0, 0, w, h, null, 0, w)' "$IMAGE" || fail "R2A getRGB path missing"
grep -Fq 'RG35XX-R2A-IMAGE-NORMALIZE' "$IMAGE" || fail "R2A marker missing"
! grep -Fq 'canvas.getGraphics().drawImage(image, 0, 0, null);' "$IMAGE" || fail "forbidden Graphics2D decoded-image normalize remains"

# PNG sanitizer remains at every decode boundary.
[ "$(grep -Fc 'ImageIO.read(rg35xxPngIccpCompat(stream))' "$IMAGE")" -eq 3 ] || fail "PNG decode boundary count mismatch"
! grep -Fq 'ImageIO.read(stream)' "$IMAGE" || fail "unguarded ImageIO decode boundary remains"

# Scope locks: R2A must not change audio/Canvas/native presentation semantics.
grep -Fq 'MidiSystem.getSequencer(false)' "$PLAYER" || fail "R2A unexpectedly changed current audio path"
grep -Fq 'AudioSystem.getClip()' "$PLAYER" || fail "R2A unexpectedly changed current WAV path"
grep -Fq 'paintLock.wait(1000)' "$CANVAS" || fail "R2A unexpectedly changed Canvas serviceRepaints semantics"
grep -Fq 'RETRO_PIXEL_FORMAT_RGB565' "$CORE" || fail "R2A native pixel-format foundation lost"

note "PASS: Clean Consolidated R2A source at $R2A_ASSEMBLY"
