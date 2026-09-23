#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"

fail() { echo "A4_RAW2D_BUILD_FAIL=$*" >&2; exit 1; }

# First prove the unchanged A3 Java baseline on the same commit.
bash "$ROOT/scripts/build-a3.sh" java

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
JAVAC="$JAVA8/bin/javac"
JAR="$JAVA8/bin/jar"
[ -x "$JAVAC" ] || fail "javac missing: $JAVAC"
[ -x "$JAR" ] || fail "jar missing: $JAR"
[ -d "$BUILD/stage-src" ] || fail "A3 staged source missing"
[ -f "$BUILD/JAVA6-COMPAT-AUDIT.tsv" ] || fail "A3 audit missing"

# Canonical MobilePlatform.getLCD() is a four-line method at the pinned tree.
# The raw-overlay transformer intentionally uses exact anchors. Normalize only
# this formatting in the disposable staged source so the semantic rewrite stays
# exact and fail-closed; record the normalization in the audit.
python3 - "$BUILD/stage-src/org/recompile/mobile/MobilePlatform.java" "$BUILD/JAVA6-COMPAT-AUDIT.tsv" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1])
a=Path(sys.argv[2])
text=p.read_text(encoding='utf-8')
old='\tpublic BufferedImage getLCD()\n\t{\n\t\treturn lcd.getCanvas();\n\t}\n'
new='\tpublic BufferedImage getLCD() { return lcd.getCanvas(); }\n'
count=text.count(old)
if count != 1:
    raise SystemExit('A4_RAW2D_FAIL getLCD-normalize expected=1 found=%d' % count)
p.write_text(text.replace(old,new,1), encoding='utf-8')
with a.open('a', encoding='utf-8') as f:
    f.write('A4_RAW2D\torg/recompile/mobile/MobilePlatform.java\tnormalize-getLCD-format-only count=1\n')
print('A4_RAW2D_GETLCD_NORMALIZE=PASS')
PY

# Apply the A4-only RG35XX raw framebuffer overlay to the disposable staged
# source tree. The pinned Aweigit gitlink is never modified.
python3 "$ROOT/scripts/stage-a4-rg35xx-raw2d.py" \
    "$BUILD/stage-src" \
    "$BUILD/JAVA6-COMPAT-AUDIT.tsv"

[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical worktree became dirty"

rm -rf "$BUILD/classes"
mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
[ -s "$BUILD/sources.list" ] || fail "empty Java source list"

"$JAVAC" \
    -encoding UTF-8 \
    -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" \
    -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
    -d "$BUILD/classes" \
    @"$BUILD/sources.list"

rm -f "$OUT/freej2me-rg35xx.jar"
"$JAR" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then
    "$JAR" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF
fi

python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys, zipfile
jar=sys.argv[1]
bad=[]
majors=set()
required={
    'org/recompile/mobile/PlatformImage.class',
    'org/recompile/mobile/PlatformGraphics.class',
    'org/recompile/mobile/MobilePlatform.class',
    'javax/microedition/lcdui/Font.class',
    'org/recompile/rg35xx/RG35XXLauncher.class',
}
seen=set()
with zipfile.ZipFile(jar) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n)
            major=int.from_bytes(b[6:8], 'big')
            majors.add(major)
            if major > 50:
                bad.append((n, major))
            if n in required:
                seen.add(n)
if bad:
    raise SystemExit('A4_RAW2D_JAVA6_GATE_FAIL ' + repr(bad[:20]))
missing=required-seen
if missing:
    raise SystemExit('A4_RAW2D_CLASS_GATE_FAIL missing=' + repr(sorted(missing)))
print('A4_RAW2D_CLASS_MAJORS=' + ','.join(map(str, sorted(majors))))
print('A4_RAW2D_JAVA6_GATE=PASS')
PY

cp "$BUILD/JAVA6-COMPAT-AUDIT.tsv" "$OUT/JAVA6-COMPAT-AUDIT.tsv"
cat >> "$OUT/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A4_RAW2D_OVERLAY=YES
A4_RAW2D_PROPERTY=rg35xx.raw2d
A4_RAW2D_SCOPE=BLANK_PLATFORMIMAGE+CANVAS_FILL_CLIP_TRANSLATE+GAMECANVAS_FLUSH+FONT_INIT_BYPASS
A4_RAW2D_EXCLUDED=image_decode,text_render,rms,sprite,tiledlayer,audio,media
CANONICAL_GITLINK_MUTATED=NO
EOF

echo "A4_RAW2D_JAVA_BUILD=PASS"
