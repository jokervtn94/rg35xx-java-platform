#!/usr/bin/env bash
set -euo pipefail

# Reproduce the accepted VC7R18 foundation first (including clean native core),
# then apply VC7R19 only to the assembled Java runtime. This keeps native audio,
# Smart-Fit, JamVM/glibj contracts and the no-RGB-strip core unchanged.
bash scripts/vc7r18_ci.sh

OUT="$RUNNER_TEMP/vc7r18"
python3 scripts/vc7r19_apply_transparency_stability_fix.py \
  "$OUT/src/org/recompile/mobile/PlatformGraphics.java" \
  "$OUT/src/org/recompile/mobile/PlatformImage.java" \
  "$OUT/src/org/recompile/mobile/MobilePlatform.java" \
  "$OUT/src/org/recompile/freej2me/Libretro.java"

G="$OUT/src/org/recompile/mobile/PlatformGraphics.java"
I="$OUT/src/org/recompile/mobile/PlatformImage.java"
M="$OUT/src/org/recompile/mobile/MobilePlatform.java"
L="$OUT/src/org/recompile/freej2me/Libretro.java"

grep -Fq 'rg35xxVC7R19SoftwareTransform' "$G"
grep -Fq 'drawRGB(out, 0, outW, dx, dy, outW, outH, true)' "$G"
grep -Fq 'pixels[i] |= 0xFF000000' "$I"
! grep -Fq 'System.err.println("RG35XX-VC7R14-FLUSH-BRIDGE' "$G"
! grep -Fq 'System.err.println("RG35XX-VC7R14-MOBILE-FLUSH' "$M"
! grep -Fq 'System.err.println("RG35XX-VC7R12-FRAME-BIND: REQUEST' "$L"
! grep -Fq 'System.err.println("RG35XX-VC7R16-TRANSFORM' "$G"
! grep -Fq 'System.err.println("RG35XX-VC7R16-TEXT' "$G"

(cd "$OUT" && ant)
python3 - "$OUT/build/classes" <<'PY'
import os,struct,sys
n=0
for b,_,fs in os.walk(sys.argv[1]):
  for f in fs:
    if f.endswith('.class'):
      n+=1
      h=open(os.path.join(b,f),'rb').read(8)
      if len(h)!=8 or h[:4]!=b'\xca\xfe\xba\xbe' or struct.unpack('>H',h[6:8])[0]!=50:
        raise SystemExit('VC7R19 Java major gate failed: '+os.path.join(b,f))
print('VC7R19_CLASS_COUNT=%d'%n)
PY

rm -rf /tmp/vc7r19-out
mkdir -p /tmp/vc7r19-out
cp "$OUT/build/freej2me_plus-lr.jar" /tmp/vc7r19-out/freej2me-lr-vc7r19.jar
cp "$OUT/src/libretro/freej2me_plus_libretro.so" /tmp/vc7r19-out/freej2me_plus_libretro-vc7r19.so
cp /tmp/vc7r18-out/VC7R18-FONT-MANIFEST.json /tmp/vc7r19-out/VC7R19-FONT-MANIFEST.json
cat > /tmp/vc7r19-out/STATUS.txt <<'EOF'
STATUS=BUILD-PASS-PENDING-CI
VC7R19_TRANSPARENCY=SOFTWARE_EXACT_SIZE_TRANSFORMS_PRESERVE_RAW_ARGB
VC7R19_TRANSFORM0=UNCHANGED_DEVICE_PROVEN_DRAWRGB_ALPHA
VC7R19_OPAQUE_ALPHA_REPAIR=VC7R18_PRESERVED
VC7R19_STABILITY=HOT_PATH_DIAGNOSTIC_SD_WRITES_REMOVED
VC7R19_SCALED_TRANSFORMS=UPSTREAM_FALLBACK
VC7R15_LCD_MASK_GATE_FIX=PRESERVED
VC7R12_CANONICAL_FRAMEBUFFER_BINDING=PRESERVED
VC7R3_NATIVE_AUDIO=PRESERVED
RGB_REFERENCE_STRIP=REMOVED
FONT_STATUS=RECONSTRUCTED-NOT-GOLDEN
DEVICE_TEST=PENDING
EOF
(cd /tmp/vc7r19-out && sha256sum * > SHA256SUMS.txt)
