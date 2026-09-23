#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A5_CORE2D_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -d "$BUILD/stage-src" ] || fail "A4 staged source missing"
[ -f "$BUILD/JAVA6-COMPAT-AUDIT.tsv" ] || fail "A4 audit missing"
grep -q 'A4_RAW2D_OVERLAY=YES' "$BUILD/JAVA6-COMPAT-AUDIT.tsv" || fail "A4 raw2d stage not present"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty before A5"

python3 "$ROOT/scripts/stage-a5-rg35xx-core2d-v2.py" "$BUILD/stage-src" "$BUILD/JAVA6-COMPAT-AUDIT.tsv"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty after A5 staging"

rm -rf "$BUILD/classes"
mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$BUILD/classes" @"$BUILD/sources.list"

rm -f "$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF; fi

python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys,zipfile
jar=sys.argv[1]; bad=[]; majors=set()
required={
 'org/recompile/rg35xx/RG35XXCore2D.class',
 'org/recompile/rg35xx/RG35XXCore2D$RawImage.class',
 'org/recompile/mobile/PlatformImage.class',
 'org/recompile/mobile/PlatformGraphics.class',
 'javax/microedition/lcdui/Font.class'
}
seen=set()
with zipfile.ZipFile(jar) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
      if n in required: seen.add(n)
if bad: raise SystemExit('A5_CORE2D_JAVA6_GATE_FAIL '+repr(bad[:20]))
missing=required-seen
if missing: raise SystemExit('A5_CORE2D_CLASS_GATE_FAIL missing='+repr(sorted(missing)))
print('A5_CORE2D_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A5_CORE2D_JAVA6_GATE=PASS')
PY

rm -rf "$BUILD/host-gate"
mkdir -p "$BUILD/host-gate"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/host-gate" "$ROOT/tests/a5/RG35XXCore2DHostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/host-gate" \
  org.recompile.rg35xx.a5.RG35XXCore2DHostGate

cp "$BUILD/JAVA6-COMPAT-AUDIT.tsv" "$OUT/JAVA6-COMPAT-AUDIT.tsv"
cat >> "$OUT/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A5_CORE2D_OVERLAY=YES
A5_CORE2D_PROPERTY=rg35xx.raw2d
A5_CORE2D_SCOPE=HEADLESS_IMAGE_RGB+PNG+COPY+8_TRANSFORMS+DRAWIMAGE+DRAWREGION+ALPHA+FONT_METRICS+BITMAP_TEXT
A5_CORE2D_OWNER=RG35XX_ADAPTER_STAGED_BACKING_ONLY
A5_CORE2D_ALPHA_MODEL=STRAIGHT_ARGB_SOURCE_OVER
A5_CORE2D_ALPHA_HOST_GATE=PASS
A5_CORE2D_EXCLUDED=audio,media,3d,m3g,mascot,lwjgl
CANONICAL_GITLINK_MUTATED=NO
EOF

echo A5_CORE2D_JAVA_BUILD=PASS
