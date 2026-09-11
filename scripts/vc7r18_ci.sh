#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y --no-install-recommends ant python3 python3-pil python3-fonttools fonts-dejavu-core fonts-noto-cjk patch git
ROOT="$GITHUB_WORKSPACE"
UP="$RUNNER_TEMP/upstream"
HIST="$RUNNER_TEMP/history"
OUT="$RUNNER_TEMP/vc7r18"
git clone -q https://github.com/TASEmulators/freej2me-plus.git "$UP"
git -C "$UP" checkout -q 13ec186903087156c145268f8706eecfaf9f1e50
git clone -q "$ROOT" "$HIST"
git -C "$HIST" checkout -q d79180df9ae8621f2ddcf00f4f0648e4a43dc374
VC_UPSTREAM="$UP" VC6_ASSEMBLY="$OUT" sh scripts/vc6_png_iccp_assemble.sh
python3 scripts/vc7r2_apply_proven_dynamic_view.py "$OUT/src/org/recompile/freej2me/Libretro.java"
python3 scripts/vc7_apply_golden_font.py "$OUT/src/org/recompile/mobile/PlatformGraphics.java"
LATIN=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
CJK="$(fc-match -f '%{file}\n' 'Noto Sans CJK JP' | head -n1)"
test "$(sha256sum "$LATIN"|awk '{print $1}')" = ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280
test "$(sha256sum "$CJK"|awk '{print $1}')" = b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a
mkdir -p "$OUT/resources/org/recompile/mobile" "$RUNNER_TEMP/vc7r18-font"
python3 scripts/vc7r_reconstruct_font.py --font "$LATIN" --font "$CJK#0" --out "$RUNNER_TEMP/vc7r18-font/rg35xx-font.bin" --manifest "$RUNNER_TEMP/vc7r18-font/manifest.json"
test "$(sha256sum "$RUNNER_TEMP/vc7r18-font/rg35xx-font.bin"|awk '{print $1}')" = 20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9
cp "$RUNNER_TEMP/vc7r18-font/rg35xx-font.bin" "$OUT/resources/org/recompile/mobile/rg35xx-font.bin"
for f in RG35XXAudioBootstrap.java RG35XXAudioProtocol.java RG35XXAudioTransport.java RG35XXMediaProfile.java RG35XXMediaRegistry.java RG35XXNativePlayer.java RG35XXPlatformProfile.java RG35XXToneSequenceEncoder.java RG35XXWavDecoder.java; do cp "$HIST/src/org/recompile/mobile/$f" "$OUT/src/org/recompile/mobile/$f"; done
python3 - "$OUT/src/org/recompile/mobile/PlatformPlayer.java" "$OUT/src/javax/microedition/media/Manager.java" "$OUT/src/org/recompile/mobile/PlatformGraphics.java" "$OUT/src/org/recompile/mobile/PlatformImage.java" "$OUT/src/org/recompile/mobile/MobilePlatform.java" "$OUT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java" "$OUT/src/org/recompile/freej2me/Libretro.java" <<'PY'
import pathlib,sys
for n in sys.argv[1:]:
 p=pathlib.Path(n); p.write_bytes(p.read_bytes().replace(b'\r\n',b'\n').replace(b'\r',b'\n'))
PY
for p in 0003-manager-rg35xx-media-profile.patch 0018-manager-platformplayer-rg35xx-direct-media.patch 0019-platformplayer-tonecontrol-rg35xx.patch; do patch -d "$OUT" -p1 --batch --forward --fuzz=0 < "$HIST/patches/$p"; done
python3 scripts/vc7r3_apply_java_media_events.py "$OUT/src/org/recompile/freej2me/Libretro.java" "$OUT/src/org/recompile/mobile/PlatformPlayer.java" "$OUT/src/javax/microedition/media/Manager.java"
patch -d "$OUT" -p1 --batch --forward --fuzz=0 < patches/0007-platformgraphics-rg35xx-fast-drawrgb.patch
python3 scripts/vc7r9_apply_image_blit_probe.py "$OUT/src/org/recompile/mobile/PlatformGraphics.java"
python3 scripts/vc7r10_apply_headless_image_normalize.py "$OUT/src/org/recompile/mobile/PlatformImage.java"
python3 scripts/vc7r11_apply_graphics_state_probe.py "$OUT/src/org/recompile/mobile/PlatformGraphics.java" "$OUT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
python3 scripts/vc7r12_apply_canonical_framebuffer_binding.py "$OUT/src/org/recompile/freej2me/Libretro.java"
python3 scripts/vc7r13_apply_fullscreen_composition_probe.py "$OUT/src/org/recompile/mobile/PlatformGraphics.java" "$OUT/src/org/recompile/mobile/PlatformImage.java"
python3 scripts/vc7r14_apply_gamecanvas_flush_probe.py "$OUT/src/org/recompile/mobile/PlatformGraphics.java" "$OUT/src/org/recompile/mobile/MobilePlatform.java"
python3 scripts/vc7r15_apply_lcd_mask_gate_fix.py "$OUT/src/org/recompile/mobile/PlatformGraphics.java"
python3 scripts/vc7r16_apply_render_text_probe.py "$OUT/src/org/recompile/mobile/PlatformGraphics.java"
python3 scripts/vc7r18_apply_alpha_stability_fix.py "$OUT/src/org/recompile/mobile/PlatformImage.java" "$OUT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
G="$OUT/src/org/recompile/mobile/PlatformGraphics.java"; I="$OUT/src/org/recompile/mobile/PlatformImage.java"; T="$OUT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
grep -Fq 'RG35XX-VC7R18-ALPHA' "$I"; grep -Fq 'image.getColorModel().hasAlpha()' "$I"; grep -Fq 'rg35xxVC7R18DiagCount' "$T"; grep -Fq 'RG35XX-VC7R15-LCD-MASK' "$G"; ! grep -Fq 'RG35XXTransformCache' "$G"; test ! -e "$OUT/src/org/recompile/mobile/RG35XXTransformCache.java"
(cd "$OUT" && ant)
python3 - "$OUT/build/classes" <<'PY'
import os,struct,sys
n=0
for b,_,fs in os.walk(sys.argv[1]):
 for f in fs:
  if f.endswith('.class'):
   n+=1; h=open(os.path.join(b,f),'rb').read(8)
   assert h[:4]==b'\xca\xfe\xba\xbe' and struct.unpack('>H',h[6:8])[0]==50
print('VC7R18_CLASS_COUNT=%d'%n)
PY
mkdir -p /tmp/vc7r18-out
cp "$OUT/build/freej2me_plus-lr.jar" /tmp/vc7r18-out/freej2me-lr-vc7r18.jar
cp "$RUNNER_TEMP/vc7r18-font/manifest.json" /tmp/vc7r18-out/VC7R18-FONT-MANIFEST.json
cat > /tmp/vc7r18-out/STATUS.txt <<'EOF'
STATUS=BUILD-PASS-RUNTIME-ONLY-DEVICE-TEST-PENDING
VC7R18_OPAQUE_ALPHA_REPAIR=COLOR_MODEL_GATED
VC7R18_FRAME_DIAGNOSTICS=BOUNDED_48
VC7R18_IMAGE_DIAGNOSTICS=BOUNDED_96
VC7R17_TRANSFORM_CACHE=DISABLED_USE_PINNED_UPSTREAM_ARITHMETIC
VC7R15_LCD_MASK_GATE_FIX=PRESERVED
VC7R12_CANONICAL_FRAMEBUFFER_BINDING=PRESERVED
FONT_STATUS=RECONSTRUCTED-NOT-GOLDEN
AUDIO=UNCHANGED
DEVICE_TEST=PENDING
EOF
(cd /tmp/vc7r18-out && sha256sum * > SHA256SUMS.txt)
