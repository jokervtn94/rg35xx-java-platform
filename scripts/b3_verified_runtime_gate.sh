#!/bin/sh
set -eu

# B3 — Verified Clean Java Runtime gate.
# POSIX /bin/sh by design: GitHub and recovery builders must not depend on bash.

: "${B3_ASSEMBLY:?set B3_ASSEMBLY to assembled FreeJ2ME tree}"

fail() { echo "B3 FAIL: $*" >&2; exit 1; }
pass() { echo "B3 PASS: $*"; }

ROOT="$B3_ASSEMBLY"
JAR="$ROOT/build/freej2me_plus-lr.jar"
CLASSES="$ROOT/build/classes"
MOBILE="$ROOT/src/org/recompile/mobile/MobilePlatform.java"
LIBRETRO="$ROOT/src/org/recompile/freej2me/Libretro.java"
TRANSPORT="$ROOT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
IMAGE="$ROOT/src/org/recompile/mobile/PlatformImage.java"

[ -f "$JAR" ] || fail "runtime JAR missing: $JAR"
[ -d "$CLASSES" ] || fail "classes directory missing"
[ -f "$MOBILE" ] || fail "MobilePlatform.java missing"
[ -f "$LIBRETRO" ] || fail "Libretro.java missing"
[ -f "$TRANSPORT" ] || fail "Golden frame transport missing"
[ -f "$IMAGE" ] || fail "PlatformImage.java missing"

# Java 6 compatibility. Avoid non-POSIX read -d.
class_count=0
bad_class=""
for c in $(find "$CLASSES" -type f -name '*.class' -print | LC_ALL=C sort); do
  class_count=$((class_count + 1))
  major=$(od -An -t u1 -j 7 -N 1 "$c" | tr -d ' ')
  if [ "$major" != "50" ]; then
    bad_class="$c:$major"
    break
  fi
done
[ "$class_count" -gt 0 ] || fail "no compiled classes found"
[ -z "$bad_class" ] || fail "class major != 50: $bad_class"

# Admitted lazy-media boot semantics.
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' "$MOBILE" || fail "lazy-media marker missing"
python3 - "$MOBILE" <<'PY'
import pathlib, sys
s = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
r = s.index('public void runJar()')
e = s.find('\n\tpublic ', r + 1)
if e < 0:
    e = len(s)
body = s[r:e]
assert 'loader.start();' in body
assert 'prepareMediaEngine();' not in body
assert 'RG35XX-MediaWarmup' not in body
PY

# Admitted Golden asynchronous frame transport.
grep -Fq 'RG35XXGoldenFrameTransport' "$LIBRETRO" || fail "Libretro transport integration missing"
grep -Fq 'rg35xxFrames.requestFrame' "$LIBRETRO" || fail "async frame request missing"
grep -Fq 'RG35XX-FrameWorker' "$TRANSPORT" || fail "FrameWorker marker missing"
grep -Fq 'setDaemon(false)' "$TRANSPORT" || fail "FrameWorker must remain non-daemon"
grep -Fq 'ipcOut.write(header, 0, FRAME_HEADER_BYTES);' "$TRANSPORT" || fail "framed header write missing"
grep -Fq 'ipcOut.write(rgb565, 0, pixels * 2);' "$TRANSPORT" || fail "RGB565 payload write missing"
grep -Fq 'ipcOut.flush();' "$TRANSPORT" || fail "IPC flush missing"
jar tf "$JAR" | grep -Fq 'org/recompile/freej2me/RG35XXGoldenFrameTransport.class' || fail "transport class absent from JAR"

for bad in \
  'RG35XX-PNG-COMPAT' \
  'rg35xxStripPngICCP' \
  'RG35XX-PNG-COMPAT-V2' \
  'RG35XX-CV:' \
  'rg35xx_cv_' \
  'RG35XX-MediaWarmup'
do
  if grep -R -Fq "$bad" "$ROOT/src"; then
    fail "unadmitted experiment present: $bad"
  fi
done

if grep -Fq 'rg35xx' "$IMAGE"; then
  fail "PlatformImage contains pre-admission RG35XX compatibility code"
fi

OUT="${B3_EVIDENCE:-$ROOT/b3-evidence}"
rm -rf "$OUT"
mkdir -p "$OUT"
cp "$JAR" "$OUT/freej2me-lr.jar"
cp "$MOBILE" "$OUT/MobilePlatform.java"
cp "$LIBRETRO" "$OUT/Libretro.java"
cp "$TRANSPORT" "$OUT/RG35XXGoldenFrameTransport.java"
printf '%s\n' \
  'RG35XX VERIFIED CLEAN B3 JAVA RUNTIME' \
  'STATUS=BUILD-GATE-PASS-DEVICE-ACCEPTANCE-PENDING' \
  'FREEJ2ME_PIN=13ec186903087156c145268f8706eecfaf9f1e50' \
  "CLASS_COUNT=$class_count" \
  'JAVA_CLASS_MAJOR=50' \
  'LAZY_MEDIA=ADMITTED' \
  'GOLDEN_ASYNC_FRAME_TRANSPORT=ADMITTED' \
  'PNG_ICC_COMPAT=NOT_ADMITTED' \
  'CV_CW_RESOLUTION=NOT_ADMITTED' \
  'FONT_REWORK=NOT_ADMITTED' \
  'AUDIO_REWORK=NOT_ADMITTED' > "$OUT/STATUS.txt"
( cd "$OUT" && find . -type f ! -name SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum ) > "$OUT/SHA256SUMS.txt"

pass "verified clean Java runtime gate; classes=$class_count evidence=$OUT"
