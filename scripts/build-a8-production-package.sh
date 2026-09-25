#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/out/a7-audio-sdl1"
OUT="$ROOT/out/a8-production"
PAYLOAD="$OUT/RG35XX-AWEIGIT-R1"
LAUNCHER="$ROOT/packaging/a8/RG35XX-AWEIGIT-R1.sh"
fail(){ echo "A8_PACKAGE_FAIL=$*" >&2; exit 1; }

semantic_digest() {
python3 - "$1" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in sorted(z.namelist()):
        b=z.read(n); nb=n.encode('utf-8')
        h.update(struct.pack('>I',len(nb))); h.update(nb)
        h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
}

for f in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so; do
  [ -f "$SRC/$f" ] || fail "A7 artifact missing: $f"
done
[ -f "$LAUNCHER" ] || fail "A8 launcher missing"

# A8 is packaging only. Java JAR raw bytes are not reproducible because ZIP/JAR
# metadata may change on rebuild, so gate Java by exact entry/content semantic
# identity. Native binaries remain exact raw-SHA gates.
PLATFORM_SHA="$(sha256sum "$SRC/freej2me-rg35xx.jar"|awk '{print $1}')"
PLATFORM_SEMANTIC="$(semantic_digest "$SRC/freej2me-rg35xx.jar")"
test "$PLATFORM_SEMANTIC" = 7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf || fail PLATFORM_SEMANTIC_IDENTITY
test "$(sha256sum "$SRC/librg35xx_input.so"|awk '{print $1}')" = 69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d || fail INPUT_IDENTITY
test "$(sha256sum "$SRC/librg35xx_video.so"|awk '{print $1}')" = c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d || fail VIDEO_IDENTITY
test "$(sha256sum "$SRC/libaudio.so"|awk '{print $1}')" = 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644 || fail AUDIO_IDENTITY

rm -rf "$OUT"
mkdir -p "$PAYLOAD"
cp "$SRC/freej2me-rg35xx.jar" "$SRC/librg35xx_input.so" "$SRC/librg35xx_video.so" "$SRC/libaudio.so" "$PAYLOAD/"
cp "$LAUNCHER" "$OUT/RG35XX-AWEIGIT-R1.sh"
chmod +x "$OUT/RG35XX-AWEIGIT-R1.sh"

# Exact A1P5 all-zero PCM: 44100 frames/s * 2 channels * 4 bytes * 0.350 s.
head -c 123480 /dev/zero > "$PAYLOAD/a7-a1p5-rw-silence-prime.s32le"
test "$(sha256sum "$PAYLOAD/a7-a1p5-rw-silence-prime.s32le"|awk '{print $1}')" = 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e || fail PRIME_IDENTITY

cat > "$PAYLOAD/RUNTIME-SHA256SUMS.txt" <<EOF
$PLATFORM_SHA  freej2me-rg35xx.jar
69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d  librg35xx_input.so
c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d  librg35xx_video.so
4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644  libaudio.so
8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e  a7-a1p5-rw-silence-prime.s32le
EOF
(cd "$PAYLOAD" && sha256sum -c RUNTIME-SHA256SUMS.txt)

cat > "$OUT/A8-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A8-PRODUCTION-PACKAGE
BASE=A7+A1P5_DEVICE_PASS
RUNTIME_SEMANTIC_DELTA=NONE
LAUNCHER_DELTA=GENERIC_GAME_ARGUMENT+LOGGING_ORDER_FIX
A1P5_DELTA=PREJAVA_APLAY_RW_INTERLEAVED_ZERO_PCM_350MS
PLATFORM_JAR_SHA256=$PLATFORM_SHA
PLATFORM_JAR_SEMANTIC_SHA256=$PLATFORM_SEMANTIC
PLATFORM_JAR_DEVICE_PASS_SEMANTIC_SHA256=7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
PRIME_PCM_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
JAVA_IDENTITY_GATE=SEMANTIC_ENTRY_CONTENT_SHA256
NATIVE_IDENTITY_GATE=RAW_SHA256
COMMERCIAL_GAME_JARS_BUNDLED=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
FULL_PLATFORM_STABLE=NO
EOF

(cd "$OUT" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > A8-PACKAGE-SHA256SUMS.txt)
echo A8_PRODUCTION_PACKAGE_BUILD=PASS
cat "$OUT/A8-IDENTITY.txt"
