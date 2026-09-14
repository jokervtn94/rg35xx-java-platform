#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PIN="13ec186903087156c145268f8706eecfaf9f1e50"
: "${FZ_UPSTREAM:?set FZ_UPSTREAM to pristine pinned FreeJ2ME checkout}"
: "${FZ_ASSEMBLY:?set FZ_ASSEMBLY to disposable output directory}"

fail() { echo "FROM_ZERO ASSEMBLY FAIL: $*" >&2; exit 1; }
note() { echo "FROM_ZERO ASSEMBLY: $*"; }

[ -d "$FZ_UPSTREAM/.git" ] || fail "upstream is not a git checkout"
HEAD=$(git -C "$FZ_UPSTREAM" rev-parse HEAD)
[ "$HEAD" = "$PIN" ] || fail "upstream HEAD $HEAD != $PIN"
[ -z "$(git -C "$FZ_UPSTREAM" status --porcelain)" ] || fail "upstream checkout is dirty"
[ "$FZ_ASSEMBLY" != "$FZ_UPSTREAM" ] || fail "assembly must be disposable/separate"

# VC6 starts from VC0-VC3/B4 on a fresh upstream copy and admits only lazy-media,
# Golden async RGB565 receiver/Smart-Fit, bounded early native observability,
# then source-level PNG iCCP compatibility.
VC_UPSTREAM="$FZ_UPSTREAM" VC6_ASSEMBLY="$FZ_ASSEMBLY" \
  sh "$ROOT/scripts/vc6_png_iccp_assemble.sh"

LIBRETRO="$FZ_ASSEMBLY/src/org/recompile/freej2me/Libretro.java"
IMAGE="$FZ_ASSEMBLY/src/org/recompile/mobile/PlatformImage.java"
GRAPHICS="$FZ_ASSEMBLY/src/org/recompile/mobile/PlatformGraphics.java"
TRANSPORT="$FZ_ASSEMBLY/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"

# Remove historical per-frame diagnostics before adding any later production fix.
python3 "$ROOT/scripts/from_zero_cleanup_transport_logs.py" "$TRANSPORT"

# Device-proven logical LCD behavior. Physical 640x480 stays native Smart-Fit.
python3 "$ROOT/scripts/vc7r2_apply_proven_dynamic_view.py" "$LIBRETRO"

# Production semantics extracted from device-proven graphics checkpoints.
# This deliberately does NOT import their diagnostic probes/logging.
python3 "$ROOT/scripts/from_zero_apply_proven_graphics.py" \
  "$LIBRETRO" "$IMAGE" "$GRAPHICS"

# --------------------------- Positive gates -------------------------------
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' \
  "$FZ_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java" || fail "lazy media missing"
grep -Fq 'RG35XXGoldenFrameTransport' "$LIBRETRO" || fail "Golden Java frame worker missing"
grep -Fq 'RG35XX-VC7R2-VIEW:' "$LIBRETRO" || fail "proven logical view missing"
grep -Fq 'rg35xxRequestCurrentFrame()' "$LIBRETRO" || fail "current-frontbuffer binding missing"
grep -Fq 'rg35xxPngIccpCompat' "$IMAGE" || fail "PNG iCCP boundary missing"
grep -Fq 'rg35xxNormalizeDecodedImage' "$IMAGE" || fail "headless-safe image normalization missing"
grep -Fq '(!Mobile.renderLCDMask || Mobile.maskIndex == 0)' "$GRAPHICS" || fail "LCD mask gate missing"

grep -Fq 'RETRO_PIXEL_FORMAT_RGB565' "$FZ_ASSEMBLY/src/libretro/freej2me_libretro.c" || fail "RGB565 contract missing"
grep -Fq 'read_header_resync' "$FZ_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.c" || fail "receiver resync missing"
grep -Fq 'publish_back' "$FZ_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.c" || fail "double-buffer publish missing"
grep -Fq 'fit_geometry' "$FZ_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.c" || fail "Smart-Fit missing"
grep -Fq 'B4 CORE_INIT' "$FZ_ASSEMBLY/src/libretro/freej2me_libretro.c" || fail "bounded early log missing"

# --------------------------- Negative gates -------------------------------
for bad in 'RG35XX-CV:' 'rg35xx_cv_' 'RG35XX-CW' 'RG35XX-MediaWarmup'; do
  if grep -R -Fq "$bad" "$FZ_ASSEMBLY/src"; then fail "forbidden marker: $bad"; fi
done

python3 - "$FZ_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java" <<'PY'
import pathlib, sys
s=pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
r=s.index('public void runJar()')
e=s.find('\n\tpublic ', r+1)
if e < 0: e=len(s)
body=s[r:e]
if 'prepareMediaEngine();' in body: raise SystemExit('FROM_ZERO FAIL: eager media survived runJar')
if 'RG35XX-MediaWarmup' in body: raise SystemExit('FROM_ZERO FAIL: media warmup survived runJar')
PY

# No diagnostic VC7R probes, experimental audio restoration, reconstructed font,
# transform cache, or tracing should enter foundation v1.
for bad in \
  'RG35XX-VC7R4' 'RG35XX-VC7R5' 'RG35XX-VC7R6' 'RG35XX-VC7R9' \
  'RG35XX-VC7R10-IMAGE-NORMALIZE' 'RG35XX-VC7R11' 'RG35XX-VC7R12-FRAME-BIND' \
  'RG35XX-VC7R13' 'RG35XX-VC7R14' 'RG35XX-VC7R15-LCD-MASK' 'RG35XX-VC7R16' \
  'RG35XX-VC7R18' 'RG35XX-VC7R19' 'RG35XX-VC7R20' 'RG35XX-VC7R21' \
  'RG35XX-VC7R22' 'RG35XX-VC7R23' \
  'RG35XXTransformCache' 'rg35xx-font.bin' 'GET_SEQUENCER'
do
  if grep -R -Fq "$bad" "$FZ_ASSEMBLY/src" "$FZ_ASSEMBLY/resources" 2>/dev/null; then
    fail "unadmitted experiment/diagnostic: $bad"
  fi
done

# Hot-path production rule: known per-frame diagnostics must be absent.
for bad in 'RG35XX-JAVA-DIAG:' 'IMAGE-BLIT:' 'FRAME-BIND:' 'FULLSCREEN:' 'TRANSFORM:'; do
  if grep -R -Fq "$bad" "$FZ_ASSEMBLY/src"; then fail "hot-path diagnostic survived: $bad"; fi
done

note "PASS: clean from-zero source tree at $FZ_ASSEMBLY"
note "UPSTREAM=$PIN"
note "FONT=UPSTREAM/UNMODIFIED (Golden font deferred)"
note "AUDIO=UPSTREAM/UNMODIFIED (Golden worker-ring deferred)"
note "TRANSPARENCY_EXTENSIONS=DEFERRED"
