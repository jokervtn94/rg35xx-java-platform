#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A6_CORPUS3_RENDERDIAG_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# Build the exact PERF-A1 parent first. Native input/video and all existing
# Java semantics are then frozen; the diagnostic rebuild changes Core2D only.
bash "$ROOT/scripts/build-a6-perf-a1.sh"
PARENT="$ROOT/out/a6-perf-a1"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
[ -f "$PARENT_JAR" ] || fail "PERF-A1 parent jar missing"
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
[ "$PARENT_SEMANTIC" = "b79cafa98c467436cf0e782b069839e993a7dc7bdb31b9a423b47c0ff293950e" ] || fail "PERF-A1 parent semantic changed $PARENT_SEMANTIC"
[ "$(sha256sum "$PARENT/librg35xx_input.so" | awk '{print $1}')" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input hash changed"
[ "$(sha256sum "$PARENT/librg35xx_video.so" | awk '{print $1}')" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "PERF-A1 video hash changed"

BUILD="$ROOT/build/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
DIAG_ADAPTER="$BUILD/corpus3-renderdiag-adapter"
DIAG_CLASSES="$BUILD/corpus3-renderdiag-classes"
DST="$ROOT/out/a6-corpus3-renderdiag"
rm -rf "$DIAG_ADAPTER" "$DIAG_CLASSES" "$DST"
mkdir -p "$DIAG_ADAPTER" "$DIAG_CLASSES" "$DST"

# IMPORTANT: build-a6-perf-a1.sh has already materialized all accepted staged
# Java overlays, including the inline Adam7 Core2D change, into adapter/java.
# Copy that exact staged adapter view and add telemetry to it. Never start from
# a pristine pre-R4 Core2D source here.
cp -a "$ROOT/adapter/java/." "$DIAG_ADAPTER/"
CORE="$DIAG_ADAPTER/org/recompile/rg35xx/RG35XXCore2D.java"
[ -f "$CORE" ] || fail "Core2D source missing"
grep -q 'decodeAdam7' "$CORE" || fail "accepted Adam7 Core2D parent source missing"

python3 - "$CORE" <<'PY'
import sys
p=sys.argv[1]
s=open(p,encoding='utf-8').read()
old='''public final class RG35XXCore2D {\n    private RG35XXCore2D() { }\n'''
new='''public final class RG35XXCore2D {\n    private RG35XXCore2D() { }\n\n    // A6 Corpus #3 trace-only diagnostic. This does not alter blit output.\n    private static final java.util.Hashtable rg35xxBlitDiagSeen = new java.util.Hashtable();\n    private static long rg35xxBlitDiagCalls = 0L;\n'''
if old not in s: raise SystemExit('A6_CORPUS3_RENDERDIAG_STAGE_FAIL class anchor')
s=s.replace(old,new,1)
old='''        RawImage r = transform == 0\n                ? subRaw(src, srcWidth, srcHeight, srcX, srcY, width, height)\n                : transform(src, srcWidth, srcHeight, srcX, srcY, width, height, transform);\n        int left = Math.max(dstX, Math.max(clipX, 0));\n'''
new='''        RawImage r = transform == 0\n                ? subRaw(src, srcWidth, srcHeight, srcX, srcY, width, height)\n                : transform(src, srcWidth, srcHeight, srcX, srcY, width, height, transform);\n        long diagCall = ++rg35xxBlitDiagCalls;\n        String diagKey = srcWidth + "x" + srcHeight + ":" + width + "x" + height + ":t" + transform;\n        boolean diagTrace = false;\n        synchronized (rg35xxBlitDiagSeen) {\n            if (rg35xxBlitDiagSeen.size() < 160 && !rg35xxBlitDiagSeen.containsKey(diagKey)) {\n                rg35xxBlitDiagSeen.put(diagKey, Boolean.TRUE);\n                diagTrace = true;\n            }\n        }\n        int left = Math.max(dstX, Math.max(clipX, 0));\n'''
if old not in s: raise SystemExit('A6_CORPUS3_RENDERDIAG_STAGE_FAIL blit start anchor')
s=s.replace(old,new,1)
old='''        int bottom = Math.min(dstY + r.height, Math.min(clipY + clipHeight, dstHeight));\n        if (right <= left || bottom <= top) return;\n        for (int y = top; y < bottom; y++) {\n            int sy = y - dstY;\n            int di = y * dstWidth + left;\n            int si = sy * r.width + (left - dstX);\n            for (int x = left; x < right; x++, di++, si++) {\n                dst[di] = sourceOver(r.pixels[si], dst[di]);\n            }\n        }\n'''
new='''        int bottom = Math.min(dstY + r.height, Math.min(clipY + clipHeight, dstHeight));\n        if (right <= left || bottom <= top) {\n            if (diagTrace) {\n                System.out.println("RG35XX_GOW_BLIT_DIAG CALL=" + diagCall +\n                        " KEY=" + diagKey + " SRCXY=" + srcX + "," + srcY +\n                        " DST=" + dstWidth + "x" + dstHeight + " DSTXY=" + dstX + "," + dstY +\n                        " CLIP=" + clipX + "," + clipY + "," + clipWidth + "x" + clipHeight +\n                        " RESULT=CLIPPED_OUT");\n                System.out.flush();\n            }\n            return;\n        }\n        int diagAlphaNZ = 0;\n        int diagWrites = 0;\n        int diagChanged = 0;\n        for (int y = top; y < bottom; y++) {\n            int sy = y - dstY;\n            int di = y * dstWidth + left;\n            int si = sy * r.width + (left - dstX);\n            for (int x = left; x < right; x++, di++, si++) {\n                int sp = r.pixels[si];\n                int oldp = dst[di];\n                int newp = sourceOver(sp, oldp);\n                if (diagTrace) {\n                    if (((sp >>> 24) & 0xFF) != 0) diagAlphaNZ++;\n                    diagWrites++;\n                    if (newp != oldp) diagChanged++;\n                }\n                dst[di] = newp;\n            }\n        }\n        if (diagTrace) {\n            System.out.println("RG35XX_GOW_BLIT_DIAG CALL=" + diagCall +\n                    " KEY=" + diagKey + " SRCXY=" + srcX + "," + srcY +\n                    " DST=" + dstWidth + "x" + dstHeight + " DSTXY=" + dstX + "," + dstY +\n                    " CLIP=" + clipX + "," + clipY + "," + clipWidth + "x" + clipHeight +\n                    " VIS=" + (right-left) + "x" + (bottom-top) +\n                    " ALPHA_NZ=" + diagAlphaNZ + " WRITES=" + diagWrites + " CHANGED=" + diagChanged);\n            System.out.flush();\n        }\n        if ((diagCall % 10000L) == 0L) {\n            System.out.println("RG35XX_GOW_BLIT_DIAG_SUMMARY CALLS=" + diagCall + " KEYS=" + rg35xxBlitDiagSeen.size());\n            System.out.flush();\n        }\n'''
if old not in s: raise SystemExit('A6_CORPUS3_RENDERDIAG_STAGE_FAIL blit body anchor')
s=s.replace(old,new,1)
open(p,'w',encoding='utf-8').write(s)
print('A6_CORPUS3_RENDERDIAG_STAGE=PASS')
PY

grep -q 'RG35XX_GOW_BLIT_DIAG' "$CORE" || fail "diagnostic marker missing"
grep -q 'ALPHA_NZ=' "$CORE" || fail "alpha diagnostic missing"
grep -q 'CHANGED=' "$CORE" || fail "changed diagnostic missing"
grep -q 'decodeAdam7' "$CORE" || fail "Adam7 lost while staging diagnostic"

find "$BUILD/stage-src" "$DIAG_ADAPTER" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/corpus3-renderdiag-sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$DIAG_CLASSES" @"$BUILD/corpus3-renderdiag-sources.list"

DIAG_JAR="$DST/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$DIAG_JAR" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$DIAG_CLASSES" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$DIAG_JAR" -C "$UPSTREAM" META-INF; fi

# javac can rewrite the nested RawImage class' classfile metadata when the
# enclosing Core2D is recompiled. Allow that binary delta ONLY when the
# executable javap instructions are identical to the exact PERF-A1 parent.
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c 'org.recompile.rg35xx.RG35XXCore2D$RawImage' > "$BUILD/corpus3-parent-rawimage.javap"
"$JAVA8/bin/javap" -classpath "$DIAG_JAR" -p -c 'org.recompile.rg35xx.RG35XXCore2D$RawImage' > "$BUILD/corpus3-diag-rawimage.javap"
cmp -s "$BUILD/corpus3-parent-rawimage.javap" "$BUILD/corpus3-diag-rawimage.javap" || fail "RawImage executable bytecode changed"
echo A6_CORPUS3_RENDERDIAG_RAWIMAGE_BYTECODE_GATE=PASS

python3 - "$PARENT_JAR" "$DIAG_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()): raise SystemExit('A6_CORPUS3_RENDERDIAG_SCOPE_FAIL entry set')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
allowed=[
 'org/recompile/rg35xx/RG35XXCore2D$RawImage.class',
 'org/recompile/rg35xx/RG35XXCore2D.class'
]
if diff != allowed: raise SystemExit('A6_CORPUS3_RENDERDIAG_SCOPE_FAIL changed='+repr(diff))
print('A6_CORPUS3_RENDERDIAG_CHANGED_ENTRIES='+','.join(diff))
print('A6_CORPUS3_RENDERDIAG_SCOPE_GATE=PASS')
PY

python3 - "$DIAG_JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big')
      if m>50: bad.append((n,m))
if bad: raise SystemExit('A6_CORPUS3_RENDERDIAG_JAVA6_FAIL '+repr(bad[:20]))
print('A6_CORPUS3_RENDERDIAG_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$DIAG_JAR" -p -c org.recompile.rg35xx.RG35XXCore2D > "$DST/A6-CORPUS3-RENDERDIAG-CORE2D-JAVAP.txt"
grep -q 'RG35XX_GOW_BLIT_DIAG' "$DST/A6-CORPUS3-RENDERDIAG-CORE2D-JAVAP.txt" || fail "diagnostic bytecode marker missing"
grep -q 'decodeAdam7' "$DST/A6-CORPUS3-RENDERDIAG-CORE2D-JAVAP.txt" || fail "accepted Adam7 bytecode lost"
cp "$BUILD/corpus3-parent-rawimage.javap" "$DST/A6-CORPUS3-PARENT-RAWIMAGE-JAVAP.txt"
cp "$BUILD/corpus3-diag-rawimage.javap" "$DST/A6-CORPUS3-DIAG-RAWIMAGE-JAVAP.txt"

cp "$PARENT/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$PARENT/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$CORE" "$DST/A6-CORPUS3-RENDERDIAG-CORE2D-SOURCE.java.txt"
cp "$PARENT/A6-PERF-A1-IDENTITY.txt" "$DST/A6-PERF-A1-IDENTITY.txt"
cp "$PARENT/CANONICAL-DIFF-MANIFEST.txt" "$DST/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_CORPUS3_PARENT_RESULT=FAIL_VISUAL_MISSING_CHARACTER_AND_MONSTER_SPRITES
A6_CORPUS3_RENDERDIAG_SCOPE=RG35XXCore2D_BLIT_TELEMETRY_ONLY
A6_CORPUS3_RENDERDIAG_RAWIMAGE_BINARY_DELTA=JAVAC_METADATA_ONLY_BYTECODE_IDENTICAL
A6_CORPUS3_RENDERDIAG_SEMANTIC_CHANGE=NO
A6_CORPUS3_RUNTIME_NATIVE=EXACT_PERF_A1
CANONICAL_GITLINK_MUTATED=NO
EOF
DIAG_SEMANTIC="$(python3 - "$DIAG_JAR" <<'PY'
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
cat > "$DST/A6-CORPUS3-RENDERDIAG-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-CORPUS3-GOW-RENDERDIAG-BLIT
GAME_SHA256=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
PARENT_RUNTIME=PERF-A1_DEVICE_PASS
PARENT_PLATFORM_SEMANTIC_SHA256=$PARENT_SEMANTIC
DIAGNOSTIC_PLATFORM_SEMANTIC_SHA256=$DIAG_SEMANTIC
INPUT_NATIVE_SHA256=$(sha256sum "$DST/librg35xx_input.so" | awk '{print $1}')
VIDEO_NATIVE_SHA256=$(sha256sum "$DST/librg35xx_video.so" | awk '{print $1}')
PARENT_VISUAL_RESULT=FAIL_MISSING_CHARACTER_AND_MONSTER_SPRITES
DIAGNOSTIC_SCOPE=RG35XXCore2D_BLIT_TELEMETRY_ONLY
DIAGNOSTIC_RAWIMAGE_GATE=BYTECODE_IDENTICAL
DIAGNOSTIC_ADAM7=PRESERVED
DIAGNOSTIC_KEYS_LIMIT=160
DIAGNOSTIC_FIELDS=SRC_DIM,REGION_DIM,TRANSFORM,SRCXY,DST_DIM,DSTXY,CLIP,VIS,ALPHA_NZ,WRITES,CHANGED
SEMANTIC_CHANGE=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DIAGNOSTIC-DEVICE-TEST=PENDING
STABLE=NO
EOF
(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_CORPUS3_RENDERDIAG_BUILD=PASS
cat "$DST/A6-CORPUS3-RENDERDIAG-IDENTITY.txt"
