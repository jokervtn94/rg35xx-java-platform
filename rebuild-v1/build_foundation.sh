#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

LOCK=faa49f9b941db5394265d9b13413e4576ef4694f
PIN=13ec186903087156c145268f8706eecfaf9f1e50
TREE=ad47ab16e9025f0eb3d2067bc3b1897dc71987df
JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
JAVA8=${JAVA8:-/usr/lib/jvm/java-8-openjdk-amd64}
CC=${CC:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc}
READELF=${READELF:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-readelf}
STRIP=${STRIP:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-strip}

rm -rf build-dp-r1 upstream out/garlicos
mkdir -p build-dp-r1/locked build-dp-r1/midlets build-dp-r1/manifests out/garlicos/Roms/APPS/RG35XX-JAVA-DP-R1

locked() {
  p="$1"; d="build-dp-r1/locked/$p"
  mkdir -p "$(dirname "$d")"
  git cat-file -e "$LOCK:$p"
  git show "$LOCK:$p" > "$d"
}

PATCHES=(
miyoo-m1/m1_9/patch_headless_platformfont.py
miyoo-m1/m1_9/patch_headless_platformimage_probe.py
miyoo-m1/m1_9/patch_headless_platformgraphics_probe.py
miyoo-m1/m1_9/patch_headless_platformgraphics_fillrect.py
miyoo-m1/m1_9/patch_mobileplatform_resize_diagnostics.py
miyoo-m1/m1_10/patch_mobileplatform_headless_flush.py
miyoo-m1/m1_11/patch_headless_ascii_text.py
miyoo-m1/m1_12/patch_headless_unicode_bitmap_text.py
miyoo-m1/m1_13/patch_hybrid_font_layout_v1.py
miyoo-m1/m1_13/patch_bitmap_raster_column_bound_r2.py
miyoo-m1/m1_14/patch_headless_font_metrics_v1.py
miyoo-m1/m1_14/patch_decoupled_size_semantics_r3.py
miyoo-m1/m1_14/patch_bold_only_r4a.py
miyoo-m1/m1_14/patch_italic_only_r4b.py
miyoo-m1/m1_14/patch_underline_only_r4c.py
miyoo-m1/m1_14/patch_monospace_face_semantics_r5a.py
miyoo-m1/m1_14/patch_proportional_glyph_bounds_r5c.py
miyoo-m1/m1_16/patch_platformimage_blank_dimensions_r12.py
)
FILES=(
miyoo-m1/m1_7_input_jni.c
miyoo-m1/m1_8/M1Input.java
miyoo-m1/m1_8/M1InputDispatch.java
miyoo-m1/m1_8/m1_8_input_jni.c
miyoo-m1/m1_9/M19InputPump.java
miyoo-m1/m1_9/M19SdlPresenter.java
miyoo-m1/m1_9/M19CanvasLifecycleLauncher.java
miyoo-m1/m1_9/m1_9e_presenter_jni.c
miyoo-m1/m1_9/M19CanvasE2EMIDlet.java
miyoo-m1/m1_10/M110GameCanvasE2EMIDlet.java
miyoo-m1/m1_14/M114R6FontMatrixRegressionMIDlet.java
miyoo-m1/m1_15/M115R1RmsDiagnosticMIDlet.java
miyoo-m1/m1_15/M115R11RmsPersistenceMIDlet.java
miyoo-m1/m1_16/M116R12PlatformImageBlankDiagnosticMIDlet.java
)
for f in "${PATCHES[@]}" "${FILES[@]}"; do locked "$f"; done

M17=$(sha256sum build-dp-r1/locked/miyoo-m1/m1_7_input_jni.c|awk '{print $1}')
test "$M17" = 34e0e19297a3c7e32520e0684ce7031f361fc8bcbf585093149dc8db7f39d603
! grep -R -E 'Libretro|retro_' build-dp-r1/locked/miyoo-m1/m1_8 build-dp-r1/locked/miyoo-m1/m1_9/M19InputPump.java build-dp-r1/locked/miyoo-m1/m1_9/M19SdlPresenter.java build-dp-r1/locked/miyoo-m1/m1_9/m1_9e_presenter_jni.c

git clone -q https://github.com/TASEmulators/freej2me-plus.git upstream
git -C upstream checkout -q "$PIN"
test "$(git -C upstream rev-parse HEAD)" = "$PIN"
test "$(git -C upstream rev-parse HEAD^{tree})" = "$TREE"
for p in "${PATCHES[@]}"; do python3 "build-dp-r1/locked/$p"; done

for f in M1Input.java M1InputDispatch.java; do cp "build-dp-r1/locked/miyoo-m1/m1_8/$f" upstream/src/org/recompile/mobile/; done
for f in M19InputPump.java M19SdlPresenter.java M19CanvasLifecycleLauncher.java; do cp "build-dp-r1/locked/miyoo-m1/m1_9/$f" upstream/src/org/recompile/mobile/; done
(cd upstream && JAVA_HOME="$JAVA8" ant -noinput -buildfile build.xml)
PLATFORM=upstream/build/freej2me_plus.jar
test -f "$PLATFORM"

JH="$JAVA8/include"
"$CC" -shared -fPIC -Os -pipe -fno-strict-aliasing -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft -Wall -Wextra -I"$JH" -I"$JH/linux" build-dp-r1/locked/miyoo-m1/m1_8/m1_8_input_jni.c -o build-dp-r1/libm1_8_input.so
"$CC" -shared -fPIC -Os -pipe -fno-strict-aliasing -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft -Wall -Wextra -I"$JH" -I"$JH/linux" build-dp-r1/locked/miyoo-m1/m1_9/m1_9e_presenter_jni.c -Wl,--as-needed -ldl -o build-dp-r1/libm1_9e_presenter.so
"$STRIP" build-dp-r1/libm1_8_input.so build-dp-r1/libm1_9e_presenter.so
for so in build-dp-r1/libm1_8_input.so build-dp-r1/libm1_9e_presenter.so; do
  "$READELF" -h "$so" >"$so.elf.txt"
  "$READELF" -A "$so" >"$so.attr.txt" || true
  grep -q 'Class:.*ELF32' "$so.elf.txt"
  grep -q 'Machine:.*ARM' "$so.elf.txt"
  grep -q 'Version5 EABI' "$so.elf.txt"
  grep -q 'soft-float ABI' "$so.elf.txt"
done
strings build-dp-r1/libm1_9e_presenter.so|grep -q SDL_VIDEODRIVER
! strings build-dp-r1/libm1_9e_presenter.so|grep -q SDL2
strings build-dp-r1/libm1_8_input.so|grep -q /dev/input/js0

compile_midlet() {
  src="$1"; main="$2"; label="$3"; out="$4"; c="build-dp-r1/midlets/$out"
  mkdir -p "$c"
  "$JAVA8/bin/javac" -source 1.5 -target 1.5 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$PLATFORM" -d "$c" "build-dp-r1/locked/$src"
  printf 'Manifest-Version: 1.0\nMIDlet-1: %s,,%s\nMIDlet-Name: %s\nMIDlet-Vendor: RG35XX\nMIDlet-Version: 1.0\nMicroEdition-Configuration: CLDC-1.1\nMicroEdition-Profile: MIDP-2.0\n' "$label" "$main" "$label" >"build-dp-r1/manifests/$out.mf"
  "$JAVA8/bin/jar" cfm "build-dp-r1/$out.jar" "build-dp-r1/manifests/$out.mf" -C "$c" .
}
compile_midlet miyoo-m1/m1_9/M19CanvasE2EMIDlet.java org.recompile.mobile.M19CanvasE2EMIDlet DP-R1-Canvas dp-r1-canvas
compile_midlet miyoo-m1/m1_10/M110GameCanvasE2EMIDlet.java org.recompile.mobile.M110GameCanvasE2EMIDlet DP-R1-GameCanvas dp-r1-gamecanvas
compile_midlet miyoo-m1/m1_14/M114R6FontMatrixRegressionMIDlet.java org.recompile.mobile.M114R6FontMatrixRegressionMIDlet DP-R1-Font dp-r1-font-matrix
compile_midlet miyoo-m1/m1_15/M115R1RmsDiagnosticMIDlet.java org.recompile.mobile.M115R1RmsDiagnosticMIDlet DP-R1-RMS dp-r1-rms
compile_midlet miyoo-m1/m1_15/M115R11RmsPersistenceMIDlet.java org.recompile.mobile.M115R11RmsPersistenceMIDlet DP-R1-RMS-Persist dp-r1-rms-persist
compile_midlet miyoo-m1/m1_16/M116R12PlatformImageBlankDiagnosticMIDlet.java org.recompile.mobile.M116R12PlatformImageBlankDiagnosticMIDlet DP-R1-PlatformImage dp-r1-platformimage

python3 - <<'PY'
from pathlib import Path
import zipfile
bad=[]
for jar in [Path('upstream/build/freej2me_plus.jar')]+list(Path('build-dp-r1').glob('dp-r1-*.jar')):
    with zipfile.ZipFile(jar) as z:
        for n in z.namelist():
            if n.endswith('.class'):
                b=z.read(n); major=int.from_bytes(b[6:8],'big')
                if major>50: bad.append((str(jar),n,major))
if bad: raise SystemExit('JAVA6_GATE_FAIL '+repr(bad[:10]))
print('JAVA6_GATE=PASS')
PY

APP=out/garlicos/Roms/APPS/RG35XX-JAVA-DP-R1
cp "$PLATFORM" "$APP/rg35xx-dp-r1-platform.jar"
cp build-dp-r1/libm1_8_input.so build-dp-r1/libm1_9e_presenter.so build-dp-r1/dp-r1-*.jar "$APP/"
cp rebuild-v1/device/*.sh "$APP/"
chmod +x "$APP"/*.sh
cat >"$APP/README.txt" <<EOF
RG35XX DEVICE-PASS REBUILD v1 — FOUNDATION ACCEPTANCE
Architecture: STANDALONE SDL1/fbcon; NOT Libretro.
This package does not replace installed JamVM/glibj/runtime files.
Run: CANVAS -> GAMECANVAS -> FONT -> RMS -> RMS A -> reboot/new process -> RMS B -> PLATFORMIMAGE -> COLLECT.
Font resource is EXPERIMENTAL_NOT_GOLDEN.
DEVICE-PASS=NO
STABLE=NO
EOF

{
echo RG35XX_DEVICE_PASS_REBUILD_V1
echo ARCHITECTURE=STANDALONE_SDL1_FBCON
echo LOCKED_REPO_SNAPSHOT="$LOCK"
echo FREEJ2ME_PIN="$PIN"
echo FREEJ2ME_TREE="$TREE"
echo JAMVM_L_SHA256="$JAMVM"
echo GLIBJ_SHA256="$GLIBJ"
echo M1_7_SOURCE_SHA256="$M17"
echo PLATFORM_JAR_SHA256="$(sha256sum "$APP/rg35xx-dp-r1-platform.jar"|awk '{print $1}')"
echo INPUT_SO_SHA256="$(sha256sum "$APP/libm1_8_input.so"|awk '{print $1}')"
echo PRESENTER_SO_SHA256="$(sha256sum "$APP/libm1_9e_presenter.so"|awk '{print $1}')"
echo BUILD-PASS=YES
echo DEVICE-PASS=NO
echo DEVICE-TEST-PENDING=YES
echo STABLE=NO
} >out/garlicos/BUILD-IDENTITY.txt

cp build-dp-r1/*.elf.txt build-dp-r1/*.attr.txt docs/DEVICE-PASS-REBUILD-v1.md rebuild-v1/LOCKED-ALLOWLIST.txt out/garlicos/
(cd out/garlicos && find . -type f ! -name SHA256SUMS.txt -print0|sort -z|xargs -0 sha256sum)>out/garlicos/SHA256SUMS.txt
(cd out/garlicos && sha256sum -c SHA256SUMS.txt)
echo RG35XX_DP_R1_BUILD_GATE=PASS
cat out/garlicos/BUILD-IDENTITY.txt
