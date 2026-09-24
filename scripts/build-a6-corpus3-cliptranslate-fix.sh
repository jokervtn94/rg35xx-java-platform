#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail(){ echo "A6_CORPUS3_CLIPTRANSLATE_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# Materialize the exact accepted PERF-A1 runtime parent. This also reconstructs
# all accepted A6 Java overlays in build/a3/stage-src and adapter/java.
bash "$ROOT/scripts/build-a6-perf-a1.sh"

PARENT="$ROOT/out/a6-perf-a1"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
BUILD="$ROOT/build/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
DST="$ROOT/out/a6-corpus3-cliptranslate-fix"
CLASSES="$BUILD/corpus3-cliptranslate-classes"
[ -f "$PARENT_JAR" ] || fail "PERF-A1 parent jar missing"

PARENT_SHA="$(sha256sum "$PARENT_JAR" | awk '{print $1}')"
PARENT_SEMANTIC="$(python3 - "$PARENT_JAR" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in sorted(z.namelist()):
        b=z.read(n); nb=n.encode('utf-8')
        h.update(struct.pack('>I',len(nb))); h.update(nb)
        h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
)"
INPUT_SHA="$(sha256sum "$PARENT/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$PARENT/librg35xx_video.so" | awk '{print $1}')"

# JAR container SHA is recorded but not used as the semantic lock because fresh
# jar creation can change ZIP metadata. The decompressed-entry semantic digest
# below is the exact Java content lock already used by PERF-A1 itself.
[ "$PARENT_SEMANTIC" = "b79cafa98c467436cf0e782b069839e993a7dc7bdb31b9a423b47c0ff293950e" ] || fail "parent semantic changed $PARENT_SEMANTIC"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native changed $INPUT_SHA"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "PERF-A1 video changed $VIDEO_SHA"
echo A6_CORPUS3_CLIPTRANSLATE_PARENT_IDENTITY_GATE=PASS

# Evidence-owned adapter delta: only raw PlatformGraphics.translate clip state.
python3 "$ROOT/scripts/stage-a6-corpus3-cliptranslate-fix.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical worktree dirty"

rm -rf "$CLASSES" "$DST"
mkdir -p "$CLASSES" "$DST"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/corpus3-cliptranslate-sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" @"$BUILD/corpus3-cliptranslate-sources.list"

CANDIDATE_JAR="$DST/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$CANDIDATE_JAR" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$CLASSES" .
if [ -d "$UPSTREAM/META-INF" ]; then
  "$JAVA8/bin/jar" uf "$CANDIDATE_JAR" -C "$UPSTREAM" META-INF
fi

# Fail closed unless exactly one canonical-owned class changed from PERF-A1.
python3 - "$PARENT_JAR" "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('A6_CORPUS3_CLIPTRANSLATE_SCOPE_FAIL entry set')
    diff=[n for n in sorted(a.namelist())
          if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
expected=['org/recompile/mobile/PlatformGraphics.class']
if diff != expected:
    raise SystemExit('A6_CORPUS3_CLIPTRANSLATE_SCOPE_FAIL changed='+repr(diff))
print('A6_CORPUS3_CLIPTRANSLATE_CHANGED_ENTRIES='+','.join(diff))
print('A6_CORPUS3_CLIPTRANSLATE_SCOPE_GATE=PASS')
PY

python3 - "$CANDIDATE_JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=int.from_bytes(b[6:8],'big')
            if major>50: bad.append((n,major))
if bad:
    raise SystemExit('A6_CORPUS3_CLIPTRANSLATE_JAVA6_FAIL '+repr(bad[:20]))
print('A6_CORPUS3_CLIPTRANSLATE_JAVA6_GATE=PASS')
PY

PG_SRC="$BUILD/stage-src/org/recompile/mobile/PlatformGraphics.java"
"$JAVA8/bin/javap" -classpath "$CANDIDATE_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$DST/A6-CORPUS3-CLIPTRANSLATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$DST/A6-CORPUS3-CLIPTRANSLATE-PLATFORMGRAPHICS-SOURCE.java.txt"

# Source-level semantic gate: raw branch preserves device-space clip, while the
# canonical/AWT fallback remains exactly gc.translate + user-space clip update.
python3 - "$PG_SRC" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.index('\tpublic void translate(int x, int y)')
end=s.index('\n\tprivate int AnchorX', start)
m=s[start:end]
raw_start=m.index('if (platformImage.isRG35XXRaw())')
raw_end=m.index('\n\t\tgc.translate(x, y);', raw_start)
raw=m[raw_start:raw_end]
for bad in ['clipX +=', 'clipY +=', 'clipX -=', 'clipY -=']:
    if bad in raw:
        raise SystemExit('A6_CORPUS3_CLIPTRANSLATE_SOURCE_GATE_FAIL raw contains '+bad)
for token in ['translateX += x;', 'translateY += y;', 'gc.translate(x, y);', 'clipX -= x;', 'clipY -= y;']:
    if token not in m:
        raise SystemExit('A6_CORPUS3_CLIPTRANSLATE_SOURCE_GATE_FAIL missing '+token)
print('A6_CORPUS3_CLIPTRANSLATE_SOURCE_GATE=PASS')
PY

# Owner-specific host gate reproduces the God of War failure geometry:
# a pre-existing full physical clip must not move when the user origin moves.
HOST="$BUILD/a6-corpus3-cliptranslate-host"
rm -rf "$HOST"; mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$HOST" "$ROOT/tests/a6/RG35XXRawClipTranslateHostGate.java"
"$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$HOST" org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate \
  | tee "$DST/A6-CORPUS3-CLIPTRANSLATE-HOST-GATE.txt"
grep -q '^A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS$' "$DST/A6-CORPUS3-CLIPTRANSLATE-HOST-GATE.txt" || fail "owner host gate missing"

# Preserve the already accepted raw graphics/PNG gates.
run_gate() {
  local src="$1" cls="$2" marker="$3" out="$4"
  local dir="$BUILD/a6-corpus3-reg-$(basename "$src" .java)"
  rm -rf "$dir"; mkdir -p "$dir"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
    -d "$dir" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$dir" "$cls" | tee "$DST/$out"
  grep -q "^${marker}$" "$DST/$out" || fail "regression gate $src"
}

run_gate RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate \
  A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-R5P3I2-DRAWRECT-REGRESSION-GATE.txt
run_gate RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate \
  A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-R5-DRAWLINE-REGRESSION-GATE.txt
run_gate RG35XXRawRectPolygonHostGate.java org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate \
  A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS A6-R5P3-POLYGON-REGRESSION-GATE.txt
run_gate RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate \
  A6_ADAM7_HOST_GATE=PASS A6-R4-ADAM7-REGRESSION-GATE.txt

# Runtime/native owners are copied bit-for-bit from PERF-A1.
cp "$PARENT/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$PARENT/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$PARENT/A6-PERF-A1-IDENTITY.txt" "$DST/A6-PERF-A1-IDENTITY.txt"
cp "$PARENT/CANONICAL-DIFF-MANIFEST.txt" "$DST/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A6_CORPUS3_OWNER=RG35XX_RAW_PLATFORMGRAPHICS_TRANSLATE_CLIP_DOUBLE_SHIFT
A6_CORPUS3_DELTA=RAW_TRANSLATE_PRESERVE_DEVICE_CLIP
A6_CORPUS3_CHANGED_SCOPE=PlatformGraphics_CLASS_ONLY
A6_CORPUS3_CANONICAL_AWT_FALLBACK=PRESERVED
A6_CORPUS3_PERF_A1_NATIVE=EXACT
A6_CORPUS3_PNG_DECODER=UNCHANGED
A6_CORPUS3_AUDIO_MEDIA=UNCHANGED_HOLD
CANONICAL_GITLINK_MUTATED=NO
EOF

CANDIDATE_SHA="$(sha256sum "$CANDIDATE_JAR" | awk '{print $1}')"
CANDIDATE_SEMANTIC="$(python3 - "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in sorted(z.namelist()):
        b=z.read(n); nb=n.encode('utf-8')
        h.update(struct.pack('>I',len(nb))); h.update(nb)
        h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
)"

cat > "$DST/A6-CORPUS3-CLIPTRANSLATE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-CORPUS3-GOW-CLIPTRANSLATE-FIX
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
GAME_SHA256=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
PARENT_PLATFORM_JAR_SHA256=$PARENT_SHA
PARENT_PLATFORM_SEMANTIC_SHA256=$PARENT_SEMANTIC
CANDIDATE_PLATFORM_JAR_SHA256=$CANDIDATE_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CANDIDATE_SEMANTIC
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
A6_CORPUS3_OWNER=RG35XX_RAW_PLATFORMGRAPHICS_TRANSLATE_CLIP_DOUBLE_SHIFT
A6_CORPUS3_DELTA=RAW_TRANSLATE_PRESERVE_DEVICE_CLIP
A6_CORPUS3_CHANGED_SCOPE=PlatformGraphics_CLASS_ONLY
A6_CORPUS3_CLIPTRANSLATE_SOURCE_GATE=PASS
A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS
A6_R5P3I2_DRAWRECT_REGRESSION_GATE=PASS
A6_R5_DRAWLINE_REGRESSION_GATE=PASS
A6_R5P3_POLYGON_REGRESSION_GATE=PASS
A6_R4_ADAM7_REGRESSION_GATE=PASS
PERF_A1_NATIVE=UNCHANGED
PNG_DECODER=UNCHANGED
AUDIO_MEDIA=UNCHANGED_HOLD
CANONICAL_GITLINK_MUTATED=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_CORPUS3_CLIPTRANSLATE_BUILD=PASS
cat "$DST/A6-CORPUS3-CLIPTRANSLATE-IDENTITY.txt"
