#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="${1:-all}"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
AWEIGIT_TREE=36493c9bc81badeae98966e6a3bdb86812068858
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
TOOLCHAIN_IMAGE='docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e'

fail() { echo "A3_BUILD_FAIL=$*" >&2; exit 1; }

verify_canonical() {
    [ -d "$UPSTREAM/.git" ] || [ -f "$UPSTREAM/.git" ] || fail "canonical submodule not initialized"
    [ "$(git -C "$UPSTREAM" rev-parse HEAD)" = "$AWEIGIT_COMMIT" ] || fail "canonical commit mismatch"
    [ "$(git -C "$UPSTREAM" rev-parse HEAD^{tree})" = "$AWEIGIT_TREE" ] || fail "canonical tree mismatch"
    [ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical worktree dirty"
}

java_build() {
    verify_canonical
    JAVA8="${JAVA8:-${JAVA_HOME:-}}"
    [ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
    JAVAC="$JAVA8/bin/javac"
    JAR="$JAVA8/bin/jar"
    [ -x "$JAVAC" ] || fail "javac missing: $JAVAC"
    "$JAVAC" -version 2>&1 | grep -Eq 'javac 1\.8([\._]|$)' || fail "A3 requires JDK8 compiler for Java6 bytecode gate"

    rm -rf "$BUILD" "$OUT"
    mkdir -p "$BUILD/classes" "$BUILD/manifests" "$OUT"
    find "$UPSTREAM/src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
    [ -s "$BUILD/sources.list" ] || fail "empty Java source list"

    "$JAVAC" \
        -encoding UTF-8 \
        -source 1.6 -target 1.6 \
        -bootclasspath "$JAVA8/jre/lib/rt.jar" \
        -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
        -d "$BUILD/classes" \
        @"$BUILD/sources.list"

    cat > "$BUILD/manifests/rg35xx-aweigit-r1.mf" <<'EOF'
Manifest-Version: 1.0
Main-Class: org.recompile.rg35xx.RG35XXLauncher
Implementation-Title: RG35XX Aweigit Canonical Port
Implementation-Version: R1-A3
EOF

    "$JAR" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
    if [ -d "$UPSTREAM/META-INF" ]; then
        "$JAR" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF
    fi

    python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys, zipfile
jar=sys.argv[1]
bad=[]
majors=set()
with zipfile.ZipFile(jar) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n)
            major=int.from_bytes(b[6:8], 'big')
            majors.add(major)
            if major > 50:
                bad.append((n, major))
if bad:
    raise SystemExit('JAVA6_GATE_FAIL ' + repr(bad[:20]))
print('JAVA_CLASS_MAJORS=' + ','.join(map(str, sorted(majors))))
print('JAVA6_GATE=PASS')
PY

    {
        echo "AWEIGIT_REPO=aweigit/freej2me-miyoomini"
        echo "AWEIGIT_COMMIT=$AWEIGIT_COMMIT"
        echo "AWEIGIT_TREE=$AWEIGIT_TREE"
        echo "CANONICAL_WORKTREE_DIRTY=NO"
        echo "CANONICAL_CORE_PATCH_COUNT=0"
        echo "CANONICAL_SOURCE_MODE=PINNED_GITLINK_UNMODIFIED"
        echo "ADAPTER_JAVA_ROOT=adapter/java/org/recompile/rg35xx"
        echo "ADAPTER_NATIVE_ROOT=adapter/native"
    } > "$OUT/CANONICAL-DIFF-MANIFEST.txt"
    echo "A3_JAVA_BUILD=PASS"
}

native_build() {
    verify_canonical
    mkdir -p "$BUILD/native" "$OUT"
    CC="${CC:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc}"
    READELF="${READELF:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-readelf}"
    STRIP="${STRIP:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-strip}"
    [ -x "$CC" ] || fail "cross compiler missing: $CC"
    [ -x "$READELF" ] || fail "readelf missing: $READELF"
    [ -x "$STRIP" ] || fail "strip missing: $STRIP"

    JNI="$UPSTREAM/cpp/native/include"
    COMMON=(-shared -fPIC -Os -pipe -fno-strict-aliasing -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft -Wall -Wextra -I"$JNI" -I"$JNI/linux")

    "$CC" "${COMMON[@]}" "$ROOT/adapter/native/rg35xx_input.c" -o "$OUT/librg35xx_input.so"
    "$CC" "${COMMON[@]}" "$ROOT/adapter/native/rg35xx_video_sdl1.c" -Wl,--as-needed -ldl -o "$OUT/librg35xx_video.so"
    "$STRIP" "$OUT/librg35xx_input.so" "$OUT/librg35xx_video.so"

    for so in "$OUT/librg35xx_input.so" "$OUT/librg35xx_video.so"; do
        "$READELF" -h "$so" > "$so.elf.txt"
        "$READELF" -A "$so" > "$so.attr.txt" || true
        grep -q 'Class:.*ELF32' "$so.elf.txt" || fail "$so not ELF32"
        grep -q 'Machine:.*ARM' "$so.elf.txt" || fail "$so not ARM"
        grep -q 'Version5 EABI' "$so.elf.txt" || fail "$so not EABI5"
        grep -q 'soft-float ABI' "$so.elf.txt" || fail "$so not soft-float ABI"
    done
    strings "$OUT/librg35xx_input.so" | grep -q '/dev/input/js0' || fail "input js0 identity missing"
    strings "$OUT/librg35xx_video.so" | grep -q 'SDL_VIDEODRIVER' || fail "SDL1 presenter identity missing"
    if strings "$OUT/librg35xx_video.so" | grep -q 'SDL2'; then fail "SDL2 contamination detected"; fi
    echo "A3_NATIVE_BUILD=PASS"
}

finalize_build() {
    verify_canonical
    [ -f "$OUT/freej2me-rg35xx.jar" ] || fail "platform jar missing"
    [ -f "$OUT/librg35xx_input.so" ] || fail "input native missing"
    [ -f "$OUT/librg35xx_video.so" ] || fail "video native missing"
    [ -f "$OUT/CANONICAL-DIFF-MANIFEST.txt" ] || fail "canonical diff manifest missing"

    ADAPTER_COMMIT="${GITHUB_SHA:-$(git rev-parse HEAD)}"
    CANONICAL_DIFF_SHA256="$(sha256sum "$OUT/CANONICAL-DIFF-MANIFEST.txt" | awk '{print $1}')"
    {
        echo "PROJECT=RG35XX-AWEIGIT-R1"
        echo "AWEIGIT_REPO=aweigit/freej2me-miyoomini"
        echo "AWEIGIT_COMMIT=$AWEIGIT_COMMIT"
        echo "AWEIGIT_TREE=$AWEIGIT_TREE"
        echo "ADAPTER_COMMIT=$ADAPTER_COMMIT"
        echo "JAMVM_SHA256=$JAMVM_SHA256"
        echo "GLIBJ_SHA256=$GLIBJ_SHA256"
        echo "RUNTIME_HASH_VERIFICATION=PENDING_DEVICE_PACKAGE"
        echo "TOOLCHAIN_IMAGE=$TOOLCHAIN_IMAGE"
        echo "PLATFORM_JAR_SHA256=$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"
        echo "INPUT_NATIVE_SHA256=$(sha256sum "$OUT/librg35xx_input.so" | awk '{print $1}')"
        echo "VIDEO_NATIVE_SHA256=$(sha256sum "$OUT/librg35xx_video.so" | awk '{print $1}')"
        echo "INPUT_SOURCE_SHA256=$(sha256sum "$ROOT/adapter/native/rg35xx_input.c" | awk '{print $1}')"
        echo "VIDEO_SOURCE_SHA256=$(sha256sum "$ROOT/adapter/native/rg35xx_video_sdl1.c" | awk '{print $1}')"
        echo "CANONICAL_DIFF_MANIFEST_SHA256=$CANONICAL_DIFF_SHA256"
        echo "BUILD-PASS=YES"
        echo "DEVICE-PASS=NO"
        echo "DEVICE-TEST-PENDING=YES"
        echo "STABLE=NO"
    } > "$OUT/BUILD-IDENTITY.txt"

    (cd "$OUT" && find . -type f ! -name SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$OUT/SHA256SUMS.txt"
    (cd "$OUT" && sha256sum -c SHA256SUMS.txt)
    echo "A3_BUILD_GATE=PASS"
    cat "$OUT/BUILD-IDENTITY.txt"
}

case "$MODE" in
    java) java_build ;;
    native) native_build ;;
    finalize) finalize_build ;;
    all) java_build; native_build; finalize_build ;;
    *) fail "unknown mode: $MODE" ;;
esac
