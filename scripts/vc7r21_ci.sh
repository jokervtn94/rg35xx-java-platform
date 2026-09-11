#!/usr/bin/env bash
set -euo pipefail

# Build accepted VC7R20 first, then add only the conservative legacy white-key
# compatibility layer. Native core/audio/video remain unchanged.
bash scripts/vc7r20_ci.sh

OUT="$RUNNER_TEMP/vc7r18"
I="$OUT/src/org/recompile/mobile/PlatformImage.java"
python3 scripts/vc7r21_apply_legacy_whitekey.py "$I"

grep -Fq 'RG35XX-VC7R21-LEGACY-WHITEKEY' "$I"
grep -Fq 'rg35xxVC7R21ApplyLegacyBorderWhiteKey' "$I"
grep -Fq 'final boolean hasTrns=rg35xxVC7R20PngTransparency.get()!=null' "$I"
grep -Fq '!sourceHasAlpha && !hasTrns' "$I"
grep -Fq 'if(w>=240 && h>=240) return 0' "$I"

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
        raise SystemExit('VC7R21 Java major gate failed: '+os.path.join(b,f))
print('VC7R21_CLASS_COUNT=%d'%n)
PY

rm -rf /tmp/vc7r21-out
mkdir -p /tmp/vc7r21-out
cp "$OUT/build/freej2me_plus-lr.jar" /tmp/vc7r21-out/freej2me-lr-vc7r21.jar
cp "$OUT/src/libretro/freej2me_plus_libretro.so" /tmp/vc7r21-out/freej2me_plus_libretro-vc7r21.so
cp /tmp/vc7r20-out/VC7R20-FONT-MANIFEST.json /tmp/vc7r21-out/VC7R21-FONT-MANIFEST.json
cat > /tmp/vc7r21-out/STATUS.txt <<'EOF'
STATUS=BUILD-PASS-PENDING-CI
VC7R21_TRANSPARENCY=CONSERVATIVE_BORDER_CONNECTED_PURE_WHITE_KEY
VC7R21_GLOBAL_WHITE_HEURISTIC=DISABLED
VC7R21_FULLSCREEN_GUARD=ENABLED_240x240_AND_LARGER
VC7R20_PNG_TRNS=PRESERVED_AND_HIGHER_PRIORITY
VC7R19_SOFTWARE_TRANSFORMS=PRESERVED
VC7R19_HOT_PATH_LOG_REMOVAL=PRESERVED
VC7R15_LCD_MASK_GATE_FIX=PRESERVED
VC7R12_CANONICAL_FRAMEBUFFER_BINDING=PRESERVED
VC7R3_NATIVE_AUDIO=PRESERVED
RGB_REFERENCE_STRIP=REMOVED
FONT_STATUS=RECONSTRUCTED-NOT-GOLDEN
DEVICE_TEST=PENDING
EOF
(cd /tmp/vc7r21-out && sha256sum * > SHA256SUMS.txt)
