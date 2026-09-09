#!/bin/sh
set -eu

# B3 — Verified Clean Java Runtime gate.
# This gate deliberately checks only admitted Java-runtime behavior.
# It does not admit PNG ICC, CV/CW resolution, font rework, audio rework,
# lifecycle helpers, or any other compatibility experiment.

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

# Java 6 compatibility: every emitted class must remain major 50.
find "$CLASSES" -name '*.class' -print0 | while IFS= read -r -d '' c; do
  major=$(od -An -t u1 -j 7 -N 1 "$c" | tr -d ' ')
  [ "$major" = "50" ] || fail "class major != 50: $c (major=$major)"
done

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
grep -Fq 'writeShort' "$TRANSPORT" || fail "RGB565 framed transport writer missing"
jar tf "$JAR" | grep -Fq 'org/recompile/freej2me/RG35XXGoldenFrameTransport.class' || fail "transport class absent from JAR"

# Foundation exclusions: fail closed if any unadmitted experiment returns.
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

# PlatformImage must be pristine with respect to RG35XX compatibility work.
if grep -Fq 'rg35xx' "$IMAGE"; then
  fail "PlatformImage contains pre-admission RG35XX compatibility code"
fi

# Build evidence, intentionally excluding the manifest itself.
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
  'LAZY_MEDIA=ADMITTED' \
  'GOLDEN_ASYNC_FRAME_TRANSPORT=ADMITTED' \
  'PNG_ICC_COMPAT=NOT_ADMITTED' \
  'CV_CW_RESOLUTION=NOT_ADMITTED' \
  'FONT_REWORK=NOT_ADMITTED' \
  'AUDIO_REWORK=NOT_ADMITTED' > "$OUT/STATUS.txt"
( cd "$OUT" && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum ) > "$OUT/SHA256SUMS.txt"

pass "verified clean Java runtime gate; evidence=$OUT"
