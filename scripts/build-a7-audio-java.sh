#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A7_AUDIO_JAVA_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"

BASE="$ROOT/out/a6-corpus3-cliptranslate-fix"
BASE_JAR="$BASE/freej2me-rg35xx.jar"
BUILD="$ROOT/build/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
DST="$ROOT/out/a7-audio-sdl1"
CLASSES="$BUILD/a7-audio-classes"
[ -f "$BASE_JAR" ] || fail "accepted A6 candidate missing"

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

BASE_SEMANTIC="$(semantic_digest "$BASE_JAR")"
BASE_SHA="$(sha256sum "$BASE_JAR" | awk '{print $1}')"
INPUT_SHA="$(sha256sum "$BASE/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$BASE/librg35xx_video.so" | awk '{print $1}')"
[ "$BASE_SEMANTIC" = "53f229dbf14621a2a27a7249cb1355b1a2367bebc51a761959d3bd54985565d6" ] || fail "A6 semantic mismatch $BASE_SEMANTIC"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input changed $INPUT_SHA"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video changed $VIDEO_SHA"

echo A7_A6_PARENT_IDENTITY_GATE=PASS
python3 "$ROOT/scripts/stage-a7-rg35xx-audio-loader.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical worktree dirty"

rm -rf "$CLASSES" "$DST"
mkdir -p "$CLASSES" "$DST"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/a7-audio-sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" @"$BUILD/a7-audio-sources.list"

CANDIDATE_JAR="$DST/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$CANDIDATE_JAR" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$CLASSES" .
if [ -d "$UPSTREAM/META-INF" ]; then
  "$JAVA8/bin/jar" uf "$CANDIDATE_JAR" -C "$UPSTREAM" META-INF
fi

# The only edited Java source is adapter-owned RG35XXLauncher.java. Recompiling
# that source deterministically regenerates its outer class plus four nested
# classes. Lock the exact five-entry class family; no canonical/MMAPI class may
# differ from the accepted A6 parent.
python3 - "$BASE_JAR" "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('A7_AUDIO_JAVA_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
expected=[
    'org/recompile/rg35xx/RG35XXLauncher$1.class',
    'org/recompile/rg35xx/RG35XXLauncher$2.class',
    'org/recompile/rg35xx/RG35XXLauncher$FramePresenter.class',
    'org/recompile/rg35xx/RG35XXLauncher$InputPump.class',
    'org/recompile/rg35xx/RG35XXLauncher.class',
]
if diff != expected:
    raise SystemExit('A7_AUDIO_JAVA_SCOPE_FAIL changed='+repr(diff))
print('A7_AUDIO_CHANGED_JAR_ENTRIES='+','.join(diff))
print('A7_AUDIO_CANONICAL_MMAPI_BYTE_IDENTITY=PASS')
print('A7_AUDIO_JAVA_SCOPE_GATE=PASS')
PY

python3 - "$CANDIDATE_JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=int.from_bytes(b[6:8],'big')
            if major>50: bad.append((n,major))
        if n == 'org/recompile/rg35xx/RG35XXLauncher.class':
            data=z.read(n)
            for marker in [b'libaudio.so', b'RG35XX_A7_AUDIO_BRIDGE=LOADED', b'DEVICE_INIT=LAZY']:
                if marker not in data:
                    raise SystemExit('A7_AUDIO_LOADER_GATE_FAIL marker='+repr(marker))
if bad: raise SystemExit('A7_AUDIO_JAVA6_FAIL '+repr(bad[:20]))
print('A7_AUDIO_JAVA6_GATE=PASS')
print('A7_AUDIO_LOADER_GATE=PASS')
PY

cp "$BASE/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$BASE/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$BASE/CANONICAL-DIFF-MANIFEST.txt" "$DST/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A7_AUDIO_MEDIA=ENABLED_CANDIDATE
A7_AUDIO_CANONICAL_MMAPI=UNCHANGED
A7_AUDIO_CANONICAL_PLATFORMPLAYER=UNCHANGED
A7_AUDIO_CANONICAL_SDLMIXERMANAGER=UNCHANGED
A7_AUDIO_ADAPTER=RG35XX_SDL1_MIXER_JNI
A7_AUDIO_DEVICE_INIT=LAZY
A7_AUDIO_FRAME_COUPLING=NO
A7_AUDIO_JAVASOUND_FALLBACK=NO
A7_AUDIO_VIDEO_OWNER=UNCHANGED
A7_AUDIO_INPUT_OWNER=UNCHANGED
CANONICAL_GITLINK_MUTATED=NO
EOF

CANDIDATE_SHA="$(sha256sum "$CANDIDATE_JAR" | awk '{print $1}')"
CANDIDATE_SEMANTIC="$(semantic_digest "$CANDIDATE_JAR")"
cat > "$DST/A7-AUDIO-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A7-AUDIO-MEDIA-SDL1-A1
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_ACCEPTED_PARENT_PLATFORM_SHA256=$BASE_SHA
A6_ACCEPTED_PARENT_SEMANTIC_SHA256=$BASE_SEMANTIC
A7_PLATFORM_JAR_SHA256=$CANDIDATE_SHA
A7_PLATFORM_SEMANTIC_SHA256=$CANDIDATE_SEMANTIC
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
A7_AUDIO_JAVA_CHANGED_SCOPE=RG35XXLauncher_CLASS_FAMILY_ONLY
A7_AUDIO_CANONICAL_MMAPI=UNCHANGED
A7_AUDIO_BACKEND=SDL1_MIXER_DYNAMIC
A7_AUDIO_DEVICE_INIT=LAZY
A7_AUDIO_FRAME_COUPLING=NO
A7_AUDIO_JAVASOUND_FALLBACK=NO
A7_AUDIO_NATIVE_SHA256=PENDING_NATIVE_BUILD
CANONICAL_GITLINK_MUTATED=NO
BUILD-PASS=NO_PENDING_NATIVE
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

echo A7_AUDIO_JAVA_BUILD=PASS
cat "$DST/A7-AUDIO-IDENTITY.txt"
