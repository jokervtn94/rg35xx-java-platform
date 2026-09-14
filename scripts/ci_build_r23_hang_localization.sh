#!/bin/sh
set -eu

UP="$GITHUB_WORKSPACE/upstream"
HIST="$GITHUB_WORKSPACE/history"
R23="$RUNNER_TEMP/audio-r23"
OUT="$RUNNER_TEMP/audio-r2.3-hang-localization-ab"
CC="/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft"
CXX="/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-g++ -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft"
R2CORE=a8e59eca633dfcaa3fc0e8c027fcffaa35f53d1ff5d127b7062edfd962fe7c57
R22RUNTIME=2cf28cd1832ba964c5db5e67c57e07ec5716bbc0aca88d8365c6188812f5d65b
R22CORE3072=1a06a00df7bcc4c1a80edf6808602202dbd1f493cf36c5569906d17a5fc907b6
LATIN_SHA=ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280
CJK_SHA=b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a
FONT_SHA=20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9

test -f project-rules/RG35XX_PROJECT_RULES.json
test -f tasklog/R2.3-HANG-LOCALIZATION-AB-PREFLIGHT.md
test "$(git -C "$UP" rev-parse HEAD)" = 13ec186903087156c145268f8706eecfaf9f1e50
test "$(git -C "$HIST" rev-parse HEAD)" = d79180df9ae8621f2ddcf00f4f0648e4a43dc374

FZ_UPSTREAM="$UP" FZ_ASSEMBLY="$R23" sh scripts/from_zero_assemble_v1.sh
python3 scripts/from_zero_apply_nomask_ab.py "$R23/src/org/recompile/mobile/PlatformGraphics.java"
python3 scripts/vc7_apply_golden_font.py "$R23/src/org/recompile/mobile/PlatformGraphics.java"
LATIN=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
CJK=$(fc-match -f '%{file}\n' 'Noto Sans CJK JP' | head -n1)
test "$(sha256sum "$LATIN"|awk '{print $1}')" = "$LATIN_SHA"
test "$(sha256sum "$CJK"|awk '{print $1}')" = "$CJK_SHA"
mkdir -p "$RUNNER_TEMP/r23-font" "$R23/resources/org/recompile/mobile"
python3 scripts/vc7r_reconstruct_font.py --font "$LATIN" --font "$CJK#0" --out "$RUNNER_TEMP/r23-font/rg35xx-font.bin" --manifest "$RUNNER_TEMP/r23-font/manifest.json"
test "$(sha256sum "$RUNNER_TEMP/r23-font/rg35xx-font.bin"|awk '{print $1}')" = "$FONT_SHA"
cp "$RUNNER_TEMP/r23-font/rg35xx-font.bin" "$R23/resources/org/recompile/mobile/rg35xx-font.bin"

mkdir -p "$R23/src/org/recompile/mobile" "$R23/src/libretro/rg35xx/vendor/TinySoundFont"
for f in RG35XXAudioBootstrap.java RG35XXAudioProtocol.java RG35XXAudioTransport.java RG35XXMediaProfile.java RG35XXMediaRegistry.java RG35XXNativePlayer.java RG35XXPlatformProfile.java RG35XXToneSequenceEncoder.java RG35XXWavDecoder.java; do cp "$HIST/src/org/recompile/mobile/$f" "$R23/src/org/recompile/mobile/$f"; done
for f in rg35xx_audio_protocol.h rg35xx_media_cache.h rg35xx_media_cache.c rg35xx_media_events.h rg35xx_media_event_queue.h rg35xx_media_event_queue.c rg35xx_audio_dispatch.h rg35xx_audio_dispatch.c rg35xx_audio_pipe.h rg35xx_audio_pipe.c rg35xx_mixer.h rg35xx_mixer.c rg35xx_midi_backend.h rg35xx_midi_backend.c rg35xx_tsf_worker.h rg35xx_tsf_worker.c rg35xx_tsf_impl.c rg35xx_soundfont_source.h rg35xx_soundfont_source.c rg35xx_media_runtime.h rg35xx_media_runtime.c; do cp "$HIST/native/$f" "$R23/src/libretro/rg35xx/$f"; done
sh "$HIST/native/vendor_tinysoundfont.sh"
cp "$HIST/native/vendor/TinySoundFont/tml.h" "$R23/src/libretro/rg35xx/vendor/TinySoundFont/tml.h"
cp "$HIST/native/vendor/TinySoundFont/tsf.h" "$R23/src/libretro/rg35xx/vendor/TinySoundFont/tsf.h"
python3 - "$R23/src/org/recompile/mobile/PlatformPlayer.java" "$R23/src/javax/microedition/media/Manager.java" <<'PY'
import pathlib,sys
for n in sys.argv[1:]:
 p=pathlib.Path(n);p.write_bytes(p.read_bytes().replace(b'\r\n',b'\n').replace(b'\r',b'\n'))
PY
for p in 0003-manager-rg35xx-media-profile.patch 0018-manager-platformplayer-rg35xx-direct-media.patch 0019-platformplayer-tonecontrol-rg35xx.patch; do patch -d "$R23" -p1 --batch --forward --fuzz=0 < "$HIST/patches/$p"; done
python3 scripts/vc7r3_apply_native_audio.py "$R23/src/libretro/freej2me_libretro.c"
python3 scripts/vc7r3_apply_java_media_events.py "$R23/src/org/recompile/freej2me/Libretro.java" "$R23/src/org/recompile/mobile/PlatformPlayer.java" "$R23/src/javax/microedition/media/Manager.java"
python3 scripts/vc7r22r1_apply_worker_ring.py "$R23/src/libretro/freej2me_libretro.c"
python3 scripts/vc7r22r2_apply_golden_tsf.py "$R23/src/libretro/rg35xx/rg35xx_tsf_worker.c" "$R23/src/libretro/freej2me_libretro.c"
cat >> "$R23/src/libretro/Makefile.common" <<'EOF'
SOURCES_C += rg35xx/rg35xx_media_cache.c
SOURCES_C += rg35xx/rg35xx_media_event_queue.c
SOURCES_C += rg35xx/rg35xx_audio_dispatch.c
SOURCES_C += rg35xx/rg35xx_audio_pipe.c
SOURCES_C += rg35xx/rg35xx_mixer.c
SOURCES_C += rg35xx/rg35xx_midi_backend.c
SOURCES_C += rg35xx/rg35xx_tsf_worker.c
SOURCES_C += rg35xx/rg35xx_tsf_impl.c
SOURCES_C += rg35xx/rg35xx_soundfont_source.c
SOURCES_C += rg35xx/rg35xx_media_runtime.c
INCLUDES += -Irg35xx -Irg35xx/vendor/TinySoundFont
CFLAGS += -DRG35XX_SOUNDFONT_PATH='"/mnt/mmc/BIOS/freej2me.sf2"'
EOF

build_core(){ cd "$R23/src/libretro"; make clean >/dev/null; make platform=unix CC="$CC" CXX="$CXX" LDFLAGS='-lm -lpthread' >/dev/null; }
build_core
test "$(sha256sum "$R23/src/libretro/freej2me_plus_libretro.so"|awk '{print $1}')" = "$R2CORE"

python3 scripts/vc7r22r22_apply_filebacked_midi.py "$R23/src/org/recompile/mobile/RG35XXNativePlayer.java" "$R23/src/org/recompile/mobile/RG35XXAudioTransport.java" "$R23/src/org/recompile/mobile/RG35XXAudioProtocol.java" "$R23/src/libretro/rg35xx/rg35xx_audio_protocol.h" "$R23/src/libretro/rg35xx/rg35xx_audio_dispatch.c"
(cd "$R23" && ant >/dev/null)
test "$(sha256sum "$R23/build/freej2me_plus-lr.jar"|awk '{print $1}')" = "$R22RUNTIME"
build_core
test "$(sha256sum "$R23/src/libretro/freej2me_plus_libretro.so"|awk '{print $1}')" = "$R22CORE3072"

python3 scripts/vc7r22r23_apply_hang_localization.py "$R23/src/libretro/freej2me_libretro.c" "$R23/src/libretro/rg35xx/golden/rg35xx_golden_video.c"
grep -Fq 'R23 WORKER_HB' "$R23/src/libretro/freej2me_libretro.c"
grep -Fq 'R23 VIDEO_HB' "$R23/src/libretro/rg35xx/golden/rg35xx_golden_video.c"
build_core
cp "$R23/src/libretro/freej2me_plus_libretro.so" "$RUNNER_TEMP/r23-prime3072.so"
R23_3072=$(sha256sum "$RUNNER_TEMP/r23-prime3072.so"|awk '{print $1}')
strings -a "$RUNNER_TEMP/r23-prime3072.so" | grep -Fq 'R23 CALLBACK_HB'
strings -a "$RUNNER_TEMP/r23-prime3072.so" | grep -Fq 'target=3072 chunk=1470'

python3 scripts/vc7r22r21_apply_prime2048_ab.py "$R23/src/libretro/freej2me_libretro.c"
build_core
cp "$R23/src/libretro/freej2me_plus_libretro.so" "$RUNNER_TEMP/r23-prime2048.so"
R23_2048=$(sha256sum "$RUNNER_TEMP/r23-prime2048.so"|awk '{print $1}')
strings -a "$RUNNER_TEMP/r23-prime2048.so" | grep -Fq 'R23 CALLBACK_HB'
strings -a "$RUNNER_TEMP/r23-prime2048.so" | grep -Fq 'target=2048 chunk=1470'

mkdir -p "$OUT/payload" "$OUT/installer" "$OUT/evidence"
cp "$RUNNER_TEMP/r23-prime3072.so" "$OUT/payload/freej2me_plus_libretro-r23-prime3072.so"
cp "$RUNNER_TEMP/r23-prime2048.so" "$OUT/payload/freej2me_plus_libretro-r23-prime2048.so"
(cd "$OUT/payload" && sha256sum *.so > PAYLOAD-SHA256.txt)
cp installer/INSTALL-AUDIO-R2.3-HANG-LOCALIZATION-AB.ps1 installer/INSTALL-AUDIO-R2.3-HANG-LOCALIZATION-AB.cmd "$OUT/installer/"
cp tasklog/R2.3-HANG-LOCALIZATION-AB-PREFLIGHT.md "$OUT/evidence/"
cat > "$OUT/STATUS.txt" <<EOF
STATUS=BUILD-PASS_DEVICE-TEST-PENDING
CHECKPOINT=R2.3-HANG-LOCALIZATION-AB
PRIMARY_DELTA=BOUNDED_NATIVE_DIAGNOSTICS_ONLY
BASELINE_RUNTIME_SHA256=$R22RUNTIME
CORE_PRIME3072_SHA256=$R23_3072
CORE_PRIME2048_SHA256=$R23_2048
LOG=/mnt/mmc/freej2me-vc3-early.log
CHECKPOINTS=1,8,32,128,512,2048,8192
AUDIO_BEHAVIOR=UNCHANGED_R2.2
VIDEO_BEHAVIOR=UNCHANGED_R2.2
DEVICE_PASS=NO
STABLE=NO
EOF
(cd "$OUT" && find . -type f ! -name PACKAGE-SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum) > "$OUT/PACKAGE-SHA256SUMS.txt"
(cd "$OUT" && sha256sum -c PACKAGE-SHA256SUMS.txt)
echo "R23_CORE3072_SHA256=$R23_3072"
echo "R23_CORE2048_SHA256=$R23_2048"
echo BUILD_PASS=YES
