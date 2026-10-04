#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P3_AUDIO_PLATFORM_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail JAVA8_NOT_SET
[ -x "$JAVA8/bin/javac" ] || fail javac_missing
[ -x "$JAVA8/bin/jar" ] || fail jar_missing

BASE_PAYLOAD="${P3_BASE_PAYLOAD:-}"
[ -n "$BASE_PAYLOAD" ] || fail P3_BASE_PAYLOAD_NOT_SET
BASE_JAR="$BASE_PAYLOAD/freej2me-rg35xx.jar"
[ -f "$BASE_JAR" ] || fail P2C_PLATFORM_MISSING

OUT="$ROOT/out/p3-audio-platform"
BUILD="$ROOT/build/p3-audio-platform"
CLASSES="$BUILD/classes"
SOURCE="$BUILD/RG35XXLauncher.java"
EMPTY_SOURCEPATH="$BUILD/empty-sourcepath"
JAR="$OUT/freej2me-rg35xx.jar"

rm -rf "$OUT" "$BUILD"
mkdir -p "$OUT" "$CLASSES" "$EMPTY_SOURCEPATH"

python3 - "$ROOT/adapter/java/org/recompile/rg35xx/RG35XXLauncher.java" "$SOURCE" <<'PY'
from pathlib import Path
import sys

source, destination = map(Path, sys.argv[1:])
text = source.read_text(encoding="utf-8")
anchor = "        final FramePresenter presenter = new FramePresenter(platform, raw2d, frontend);\n"
insert = """        try {
            String nativeDir = System.getProperty(\"rg35xx.native.dir\");
            if (nativeDir != null && nativeDir.length() > 0) {
                System.load(new File(nativeDir, \"libaudio.so\").getAbsolutePath());
            } else {
                System.loadLibrary(\"audio\");
            }
            System.out.println(\"RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER\");
        } catch (UnsatisfiedLinkError e) {
            RG35XXVideo.shutdownDisplay();
            System.err.println(\"RG35XX_A7_AUDIO_BRIDGE_LOAD_FAIL=\" + e.toString());
            System.exit(7);
        }

        final FramePresenter presenter = new FramePresenter(platform, raw2d, frontend);
"""
if text.count(anchor) != 1:
    raise SystemExit("P3_AUDIO_PLATFORM_SOURCE_ANCHOR_FAIL")
if "RG35XX_A7_AUDIO_BRIDGE=" in text or "libaudio.so" in text:
    raise SystemExit("P3_AUDIO_PLATFORM_SOURCE_ALREADY_PATCHED")
destination.write_text(text.replace(anchor, insert, 1), encoding="utf-8")
PY

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$BASE_JAR" \
  -sourcepath "$EMPTY_SOURCEPATH" \
  -d "$CLASSES" "$SOURCE"

mapfile -t LAUNCHER_CLASSES < <(find "$CLASSES/org/recompile/rg35xx" -type f -name 'RG35XXLauncher*.class' -print | LC_ALL=C sort)
[ "${#LAUNCHER_CLASSES[@]}" -eq 5 ] || fail "launcher_class_family=${#LAUNCHER_CLASSES[@]}"

cp "$BASE_JAR" "$JAR"
for class_file in "${LAUNCHER_CLASSES[@]}"; do
  rel="${class_file#"$CLASSES/"}"
  "$JAVA8/bin/jar" uf "$JAR" -C "$CLASSES" "$rel"
done

python3 - "$BASE_JAR" "$JAR" <<'PY'
import hashlib
import sys
import zipfile

base, patched = sys.argv[1:]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(patched) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit("P3_AUDIO_PLATFORM_ENTRY_SET_FAIL")
    diff = [n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest() != hashlib.sha256(b.read(n)).digest()]
expected = [
    "org/recompile/rg35xx/RG35XXLauncher$1.class",
    "org/recompile/rg35xx/RG35XXLauncher$2.class",
    "org/recompile/rg35xx/RG35XXLauncher$FramePresenter.class",
    "org/recompile/rg35xx/RG35XXLauncher$InputPump.class",
    "org/recompile/rg35xx/RG35XXLauncher.class",
]
if diff != expected:
    raise SystemExit("P3_AUDIO_PLATFORM_SCOPE_FAIL=" + repr(diff))
data = b.read("org/recompile/rg35xx/RG35XXLauncher.class")
for marker in (b"libaudio.so", b"RG35XX_A7_AUDIO_BRIDGE=LOADED", b"DEVICE_INIT=LAZY"):
    if marker not in data:
        raise SystemExit("P3_AUDIO_PLATFORM_LOADER_MARKER_FAIL=" + repr(marker))
print("P3_AUDIO_PLATFORM_SCOPE=RG35XXLauncher_CLASS_FAMILY_ONLY")
print("P3_AUDIO_PLATFORM_LOADER_GATE=PASS")
print("P3_AUDIO_PLATFORM_PARENT_MMAPI=UNCHANGED")
PY

SHA="$(sha256sum "$JAR" | awk '{print $1}')"
cp "$BASE_PAYLOAD"/librg35xx_input.so "$OUT/"
cp "$BASE_PAYLOAD"/librg35xx_video.so "$OUT/"
cp "$BASE_PAYLOAD"/librg35xx_font.so "$OUT/"
cp "$BASE_PAYLOAD"/libaudio.so "$OUT/"
cp "$BASE_PAYLOAD"/font.ttf "$OUT/"
cat > "$OUT/P3-AUDIO-PLATFORM-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P3_RUNTIME_SERVICE_MODULES
SOURCE_PARENT=P2C_INPUT_FRONTEND_PHYSICAL_R11
SOURCE_OVERLAY=RG35XXLauncher_AUDIO_BRIDGE_ONLY
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
PLATFORM_JAR_SHA256=$SHA
AUDIO_BRIDGE=libaudio.so
AUDIO_BACKEND=SDL1_MIXER_DYNAMIC
AUDIO_DEVICE_INIT=LAZY
CANONICAL_MMAPI=UNCHANGED
CANONICAL_PLATFORMPLAYER=UNCHANGED
CANONICAL_SDLMIXERMANAGER=UNCHANGED
BUILD-PASS=YES
DEVICE-PASS=NO
EOF_ID

echo P3_AUDIO_PLATFORM_BUILD=PASS
echo P3_AUDIO_PLATFORM_SHA256=$SHA
