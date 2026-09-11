#!/usr/bin/env bash
set -euo pipefail

# Build the accepted VC7R19 runtime/core, then patch only PlatformImage semantics.
bash scripts/vc7r19_ci.sh

OUT="$RUNNER_TEMP/vc7r18"
I="$OUT/src/org/recompile/mobile/PlatformImage.java"
python3 scripts/vc7r20_apply_png_trns_semantics.py "$I"

grep -Fq 'RG35XX-VC7R20-PNG-TRNS' "$I"
grep -Fq 'rg35xxVC7R20CapturePngTransparency(raw)' "$I"
grep -Fq 'rg35xxVC7R20ApplyPngTransparency(pixels)' "$I"
grep -Fq 'trnsChanged==0' "$I"
! grep -Fq $'if(!sourceHasAlpha)\n\t\t{' "$I"

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
        raise SystemExit('VC7R20 Java major gate failed: '+os.path.join(b,f))
print('VC7R20_CLASS_COUNT=%d'%n)
PY

rm -rf /tmp/vc7r20-out
mkdir -p /tmp/vc7r20-out
cp "$OUT/build/freej2me_plus-lr.jar" /tmp/vc7r20-out/freej2me-lr-vc7r20.jar
cp "$OUT/src/libretro/freej2me_plus_libretro.so" /tmp/vc7r20-out/freej2me_plus_libretro-vc7r20.so
cp /tmp/vc7r19-out/VC7R19-FONT-MANIFEST.json /tmp/vc7r20-out/VC7R20-FONT-MANIFEST.json
cat > /tmp/vc7r20-out/STATUS.txt <<'EOF'
STATUS=BUILD-PASS-PENDING-CI
VC7R20_TRANSPARENCY=PNG_TRNS_METADATA_PRESERVED
VC7R20_POLICY=TRNS_FIRST_THEN_OPAQUE_REPAIR
VC7R20_WHITE_HEURISTIC=DISABLED
VC7R19_SOFTWARE_TRANSFORMS=PRESERVED
VC7R19_HOT_PATH_LOG_REMOVAL=PRESERVED
VC7R15_LCD_MASK_GATE_FIX=PRESERVED
VC7R12_CANONICAL_FRAMEBUFFER_BINDING=PRESERVED
VC7R3_NATIVE_AUDIO=PRESERVED
RGB_REFERENCE_STRIP=REMOVED
FONT_STATUS=RECONSTRUCTED-NOT-GOLDEN
DEVICE_TEST=PENDING
EOF
(cd /tmp/vc7r20-out && sha256sum * > SHA256SUMS.txt)
