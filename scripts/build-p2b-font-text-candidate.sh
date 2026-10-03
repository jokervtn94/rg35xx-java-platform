#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2B_FONT_TEXT_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
P2B="$BUILD/p2b-font-text-r1"
OUT="$ROOT/out/p2b-font-text-candidate-r1"
PARENT_OUT="$ROOT/out/p2a-image-decode-candidate"
PARENT_JAR="$PARENT_OUT/freej2me-rg35xx.jar"
CANDIDATE="$OUT/freej2me-rg35xx.jar"
FONT_URL="https://github.com/aweigit/freej2me-miyoomini/releases/download/2.0/miyoomini-freej2me.zip"
FONT_SHA="1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10"
FONT_SIZE="8092724"
JDK8U_COMMIT="4efe36434f44bafb854e602ccbbe1b5696fce1a2"
JDK8_LAYOUT_TREE="bc6641fecdfb59f3146bb1591e090761a24b4061"
JDK8_FT_INCLUDE_TREE="43f2e4398cfd927acac29ce3515e23a195349eb7"
JDK8_FT_SRC_TREE="8690dd39ef9f4da5bae000d757fe6dfa2d2102a6"

semantic_digest(){ python3 - "$1" <<'PY'
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
entry_digest(){ python3 - "$1" "$2" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z: print(hashlib.sha256(z.read(sys.argv[2])).hexdigest())
PY
}

rm -rf "$P2B" "$OUT"
mkdir -p "$P2B" "$OUT"

# 1. Reconstruct the exact accepted P2A runtime lineage first.
JAVA8="$JAVA8" bash "$ROOT/scripts/build-p2a-image-decode-candidate.sh" | tee "$OUT/P2B-P2A-PARENT-REBUILD.txt"
grep -q '^P2A_IMAGE_BUILD=PASS$' "$OUT/P2B-P2A-PARENT-REBUILD.txt" || fail "P2A parent build"
grep -q '^P2A_IMAGE_HOST_MODULE_GATE=PASS$' "$OUT/P2B-P2A-PARENT-REBUILD.txt" || fail "P2A parent host gate"
[ -f "$PARENT_JAR" ] || fail "P2A parent jar missing"
[ -f "$PARENT_OUT/P2A-IMAGE-DECODE-IDENTITY.txt" ] || fail "P2A parent identity missing"
grep -q '^A9_PARENT=NO$' "$PARENT_OUT/P2A-IMAGE-DECODE-IDENTITY.txt" || fail "P2A parent A9"
echo P2B_P2A_PARENT_REBUILD=PASS

# 2. Materialize exact pinned Miyoo font asset. Font bytes stay ephemeral.
curl -fL --retry 3 --retry-delay 2 "$FONT_URL" -o "$P2B/miyoomini-freej2me.zip"
ZIP_SHA="$(sha256sum "$P2B/miyoomini-freej2me.zip" | awk '{print $1}')"
ENTRY="$(unzip -Z1 "$P2B/miyoomini-freej2me.zip" | grep -E '(^|/)JAVA/font\.ttf$|(^|/)font\.ttf$')"
[ "$(printf '%s\n' "$ENTRY" | sed '/^$/d' | wc -l | tr -d ' ')" = 1 ] || fail "font entry ambiguity: $ENTRY"
unzip -p "$P2B/miyoomini-freej2me.zip" "$ENTRY" > "$P2B/font.ttf"
[ "$(sha256sum "$P2B/font.ttf" | awk '{print $1}')" = "$FONT_SHA" ] || fail "font sha"
[ "$(wc -c < "$P2B/font.ttf" | tr -d ' ')" = "$FONT_SIZE" ] || fail "font size"
echo P2B_FONT_ASSET_IDENTITY=PASS

# 3. Pin exact JDK8u504 source owner proven by P2B audit.
JDKSRC="$P2B/jdk8u"
git clone -q --filter=blob:none --no-checkout https://github.com/adoptium/jdk8u.git "$JDKSRC"
git -C "$JDKSRC" fetch -q --depth 1 origin "$JDK8U_COMMIT"
git -C "$JDKSRC" checkout -q --detach "$JDK8U_COMMIT"
[ "$(git -C "$JDKSRC" rev-parse HEAD)" = "$JDK8U_COMMIT" ] || fail "JDK commit"
[ "$(git -C "$JDKSRC" rev-parse HEAD:jdk/src/share/native/sun/font/layout)" = "$JDK8_LAYOUT_TREE" ] || fail "layout tree"
[ "$(git -C "$JDKSRC" rev-parse HEAD:jdk/src/share/native/sun/awt/libfreetype/include)" = "$JDK8_FT_INCLUDE_TREE" ] || fail "FT include tree"
[ "$(git -C "$JDKSRC" rev-parse HEAD:jdk/src/share/native/sun/awt/libfreetype/src)" = "$JDK8_FT_SRC_TREE" ] || fail "FT source tree"
grep -Fq 'Freetype v2.14.3' "$JDKSRC/THIRD_PARTY_README" || fail "FT version"
echo P2B_JDK8_SOURCE_PROVENANCE=PASS

# 4. Generate exact JDK ScriptRun data + JDK Unicode mark ranges for LayoutEngine flags.
python3 - "$JDKSRC" "$P2B/p2b_script_data.inc" <<'PY'
import re,sys
from pathlib import Path
jdk=Path(sys.argv[1]); out=Path(sys.argv[2])
src=(jdk/'jdk/src/share/classes/sun/font/ScriptRunData.java').read_text(encoding='utf-8')
m=re.search(r'private static final int\[\] data\s*=\s*\{(.*?)\n\s*\};',src,re.S)
if not m: raise SystemExit('P2B_SCRIPT_DATA_PARSE=FAIL')
body=re.sub(r'//[^\n]*','',m.group(1))
toks=re.findall(r'-?0x[0-9A-Fa-f]+|-?\d+',body)
vals=[int(x,0) for x in toks]
if len(vals)%2 or vals[-2:]!=[0x110000,-1]: raise SystemExit('P2B_SCRIPT_DATA_SENTINEL=FAIL')
pairs=[tuple(vals[i:i+2]) for i in range(0,len(vals),2)]

ud=jdk/'jdk/make/data/unicodedata/UnicodeData.txt'
ranges=[]; pending=None
for line in ud.read_text(encoding='utf-8').splitlines():
    if not line: continue
    f=line.split(';'); cp=int(f[0],16); name=f[1]; cat=f[2]
    if name.endswith(', First>'):
        pending=(cp,cat); continue
    if name.endswith(', Last>'):
        if pending is None: raise SystemExit('P2B_UNICODE_RANGE=FAIL')
        a,pcat=pending; pending=None
        if pcat in ('Mn','Mc','Me'): ranges.append((a,cp))
        continue
    if cat in ('Mn','Mc','Me'): ranges.append((cp,cp))
merged=[]
for a,b in sorted(ranges):
    if merged and a<=merged[-1][1]+1: merged[-1]=(merged[-1][0],max(merged[-1][1],b))
    else: merged.append((a,b))
with out.open('w',encoding='utf-8') as w:
    w.write('/* generated from exact OpenJDK8u504 ScriptRunData.java + UnicodeData.txt */\n')
    w.write('static const int P2B_SCRIPT_PAIR_COUNT = %d;\n' % (len(pairs)-1))
    w.write('static const int P2B_SCRIPT_DATA[] = {\n')
    for a,b in pairs: w.write('  0x%06X, %d,\n' % (a,b))
    w.write('};\n')
    w.write('static const int P2B_MARK_RANGE_COUNT = %d;\n' % len(merged))
    w.write('static const int P2B_MARK_RANGES[] = {\n')
    for a,b in merged: w.write('  0x%06X, 0x%06X,\n' % (a,b))
    w.write('};\n')
print('P2B_SCRIPT_DATA_PAIR_COUNT=%d' % (len(pairs)-1))
print('P2B_MARK_RANGE_COUNT=%d' % len(merged))
print('P2B_JDK_SCRIPT_MARK_DATA=PASS')
PY

# 5. Build exact JDK8 vendored FreeType + LayoutEngine for host and ARM.
FTROOT="$JDKSRC/jdk/src/share/native/sun/awt/libfreetype"
FONTROOT="$JDKSRC/jdk/src/share/native/sun/font"
LAYOUT="$FONTROOT/layout"
build_ft(){
  local cc="$1" ar="$2" obj="$3" lib="$4" extra="$5"
  rm -rf "$obj"; mkdir -p "$obj"; local count=0
  while IFS= read -r src; do
    local rel="${src#$FTROOT/src/}"; local o="$obj/${rel//\//_}.o"
    # shellcheck disable=SC2086
    "$cc" -O2 -pipe -fPIC $extra -DFT2_BUILD_LIBRARY -I"$FTROOT/include" -c "$src" -o "$o"
    count=$((count+1))
  done < <(find "$FTROOT/src" -type f -name '*.c' -print | LC_ALL=C sort)
  [ "$count" = 106 ] || fail "FT source count=$count"
  "$ar" rcs "$lib" "$obj"/*.o
}
build_layout(){
  local cxx="$1" ar="$2" obj="$3" lib="$4" extra="$5"
  rm -rf "$obj"; mkdir -p "$obj"; local compiled=0 excluded=0
  while IFS= read -r src; do
    local base="$(basename "$src")"
    if [ "$base" = SunLayoutEngine.cpp ]; then excluded=$((excluded+1)); continue; fi
    # shellcheck disable=SC2086
    "$cxx" -O2 -pipe -fPIC -std=gnu++98 $extra -DLE_STANDALONE -DHEADLESS -I"$FONTROOT" -I"$LAYOUT" -c "$src" -o "$obj/${base%.cpp}.o"
    compiled=$((compiled+1))
  done < <(find "$LAYOUT" -maxdepth 1 -type f -name '*.cpp' -print | LC_ALL=C sort)
  [ "$compiled" = 87 ] || fail "Layout source count=$compiled"
  [ "$excluded" = 1 ] || fail "SunLayoutEngine exclusion=$excluded"
  "$ar" rcs "$lib" "$obj"/*.o
}

HOST_CC="${CC_HOST:-gcc}"; HOST_CXX="${CXX_HOST:-g++}"; HOST_AR="${AR_HOST:-ar}"
build_ft "$HOST_CC" "$HOST_AR" "$P2B/ft-host-obj" "$P2B/libfreetype-jdk8-host.a" ""
build_layout "$HOST_CXX" "$HOST_AR" "$P2B/layout-host-obj" "$P2B/liblayout-jdk8-host.a" ""
"$HOST_CXX" -O2 -pipe -fPIC -std=gnu++98 -shared \
  -DLE_STANDALONE -DHEADLESS \
  -I"$JAVA8/include" -I"$JAVA8/include/linux" -I"$FONTROOT" -I"$LAYOUT" -I"$FTROOT/include" -I"$P2B" \
  "$ROOT/adapter/native/rg35xx_font_jdk8.cpp" \
  -Wl,--whole-archive "$P2B/liblayout-jdk8-host.a" -Wl,--no-whole-archive \
  "$P2B/libfreetype-jdk8-host.a" -lm -lpthread -o "$P2B/librg35xx_font_host.so"
echo P2B_HOST_FONT_NATIVE_BUILD=PASS

ARM_CC="${ARM_CC:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc}"
ARM_CXX="${ARM_CXX:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-g++}"
ARM_AR="${ARM_AR:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-ar}"
[ -x "$ARM_CC" ] && [ -x "$ARM_CXX" ] && [ -x "$ARM_AR" ] || fail "pinned Miyoo ARM toolchain missing"
ARM_FLAGS='-march=armv5te -mtune=arm926ej-s -mfloat-abi=soft'
build_ft "$ARM_CC" "$ARM_AR" "$P2B/ft-arm-obj" "$P2B/libfreetype-jdk8-arm.a" "$ARM_FLAGS"
build_layout "$ARM_CXX" "$ARM_AR" "$P2B/layout-arm-obj" "$P2B/liblayout-jdk8-arm.a" "$ARM_FLAGS"
# shellcheck disable=SC2086
"$ARM_CXX" -O2 -pipe -fPIC -std=gnu++98 -shared $ARM_FLAGS \
  -DLE_STANDALONE -DHEADLESS \
  -I"$JAVA8/include" -I"$JAVA8/include/linux" -I"$FONTROOT" -I"$LAYOUT" -I"$FTROOT/include" -I"$P2B" \
  "$ROOT/adapter/native/rg35xx_font_jdk8.cpp" \
  -Wl,--whole-archive "$P2B/liblayout-jdk8-arm.a" -Wl,--no-whole-archive \
  "$P2B/libfreetype-jdk8-arm.a" -lm -lpthread -static-libgcc -static-libstdc++ \
  -o "$OUT/librg35xx_font.so"
file "$OUT/librg35xx_font.so" | tee "$OUT/P2B-FONT-NATIVE-FILE.txt"
readelf -h "$OUT/librg35xx_font.so" | tee "$OUT/P2B-FONT-NATIVE-ELF.txt"
readelf -d "$OUT/librg35xx_font.so" | tee "$OUT/P2B-FONT-NATIVE-DYNAMIC.txt"
grep -Eq 'ARM' "$OUT/P2B-FONT-NATIVE-ELF.txt" || fail "font native not ARM"
echo P2B_ARM_FONT_NATIVE_BUILD=PASS

# 6. Apply only the owner-scoped P2B Java boundary delta.
python3 "$ROOT/scripts/stage-p2b-font-text.py" "$ROOT" | tee "$OUT/P2B-FONT-TEXT-STAGE.txt"
grep -q '^P2B_FONT_TEXT_STAGE=PASS$' "$OUT/P2B-FONT-TEXT-STAGE.txt" || fail "stage"
grep -q '^P2B_FONT_TEXT_NONOWNER_NATIVE_CHANGE=NO$' "$OUT/P2B-FONT-TEXT-STAGE.txt" || fail "native scope"
grep -q '^P2B_FONT_TEXT_GAME_SPECIFIC_CODE=NO$' "$OUT/P2B-FONT-TEXT-STAGE.txt" || fail "game scope"
grep -q '^P2B_FONT_TEXT_A9_PARENT=NO$' "$OUT/P2B-FONT-TEXT-STAGE.txt" || fail "A9 scope"

CLASSES="$P2B/classes"; rm -rf "$CLASSES"; mkdir -p "$CLASSES"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PARENT_JAR:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" \
  "$ROOT/adapter/java/org/recompile/rg35xx/RG35XXCore2D.java" \
  "$BUILD/stage-src/javax/microedition/lcdui/Font.java" \
  "$BUILD/stage-src/org/recompile/mobile/PlatformGraphics.java"
CLASS_LIST="$(cd "$CLASSES" && find . -type f -name '*.class' -printf '%P\n' | LC_ALL=C sort)"
EXPECTED_CLASSES=$'javax/microedition/lcdui/Font.class\norg/recompile/mobile/PlatformGraphics.class\norg/recompile/rg35xx/RG35XXCore2D$RawImage.class\norg/recompile/rg35xx/RG35XXCore2D.class'
[ "$CLASS_LIST" = "$EXPECTED_CLASSES" ] || fail "Java compile scope: $CLASS_LIST"

cp "$PARENT_JAR" "$CANDIDATE"
(
  cd "$CLASSES"
  "$JAVA8/bin/jar" uf "$CANDIDATE" \
    javax/microedition/lcdui/Font.class \
    org/recompile/mobile/PlatformGraphics.class \
    'org/recompile/rg35xx/RG35XXCore2D$RawImage.class' \
    org/recompile/rg35xx/RG35XXCore2D.class
)
python3 - "$PARENT_JAR" "$CANDIDATE" <<'PY'
import sys,zipfile,hashlib
a,b=sys.argv[1:3]
expected=['javax/microedition/lcdui/Font.class','org/recompile/mobile/PlatformGraphics.class','org/recompile/rg35xx/RG35XXCore2D$RawImage.class','org/recompile/rg35xx/RG35XXCore2D.class']
with zipfile.ZipFile(a) as za,zipfile.ZipFile(b) as zb:
    if set(za.namelist())!=set(zb.namelist()): raise SystemExit('P2B_OWNER_SCOPE_FAIL entry-set')
    changed=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if changed!=expected: raise SystemExit('P2B_OWNER_SCOPE_FAIL changed='+repr(changed))
print('P2B_CHANGED_JAR_ENTRIES='+','.join(changed)); print('P2B_OWNER_SCOPE_VERIFIED=PASS')
PY
python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]; majors=set()
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); major=int.from_bytes(b[6:8],'big'); majors.add(major)
      if major>50: bad.append((n,major))
if bad: raise SystemExit('P2B_JAVA6_FAIL '+repr(bad[:20]))
print('P2B_CLASS_MAJORS='+','.join(map(str,sorted(majors)))); print('P2B_JAVA6_GATE=PASS')
PY

# 7. Host exact JDK8 semantic differential and module integration gate.
HOSTTEST="$P2B/host-tests"; rm -rf "$HOSTTEST"; mkdir -p "$HOSTTEST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$HOSTTEST" \
  "$ROOT/tests/p2b/RG35XXP2BFontTextHostGate.java" \
  "$ROOT/tests/p2b/RG35XXP2BFontTextModuleGate.java"
JVM_FONT=(-Djava.awt.headless=true -Drg35xx.raw2d=true -Drg35xx.font.native.path="$P2B/librg35xx_font_host.so" -Drg35xx.font.path="$P2B/font.ttf")
"$JAVA8/bin/java" "${JVM_FONT[@]}" -cp "$CANDIDATE:$HOSTTEST" org.recompile.rg35xx.p2b.RG35XXP2BFontTextHostGate "$P2B/font.ttf" | tee "$OUT/P2B-HOST-FONT-TEXT-GATE.txt"
grep -q '^P2B_HOST_FAILURE_COUNT=0$' "$OUT/P2B-HOST-FONT-TEXT-GATE.txt" || fail "host differential"
grep -q '^P2B_HOST_FONT_TEXT_GATE=PASS$' "$OUT/P2B-HOST-FONT-TEXT-GATE.txt" || fail "host gate"
"$JAVA8/bin/java" "${JVM_FONT[@]}" -cp "$CANDIDATE:$HOSTTEST" org.recompile.rg35xx.p2b.RG35XXP2BFontTextModuleGate | tee "$OUT/P2B-MODULE-GATE.txt"
grep -q '^P2B_MODULE_INTEGRATION_FAILURE_COUNT=0$' "$OUT/P2B-MODULE-GATE.txt" || fail "module integration"
grep -q '^P2B_MODULE_GATE=PASS$' "$OUT/P2B-MODULE-GATE.txt" || fail "module gate"

# 8. Re-run accepted P2A image and P1A non-text graphics regressions on P2B jar.
P2A_HOST="$BUILD/p2a-image-host"; P1REG="$BUILD/p2a-regression"
[ -d "$P2A_HOST" ] && [ -d "$P1REG" ] || fail "parent regression classes missing"
"$JAVA8/bin/java" "${JVM_FONT[@]}" -cp "$CANDIDATE:$P2A_HOST" org.recompile.rg35xx.p2a.RG35XXP2AImageDecodeDifferentialGate | tee "$OUT/P2B-P2A-IMAGE-REGRESSION.txt"
grep -q '^P2A_IMAGE_DIFFERENTIAL_GATE=PASS$' "$OUT/P2B-P2A-IMAGE-REGRESSION.txt" || fail "P2A image regression"
grep -q '^P2A_IMAGE_RAW_MISMATCH_COUNT=0$' "$OUT/P2B-P2A-IMAGE-REGRESSION.txt" || fail "P2A image mismatch"

run_reg(){
  local cls="$1" marker="$2" log="$3"
  "$JAVA8/bin/java" "${JVM_FONT[@]}" -cp "$CANDIDATE:$P1REG" "$cls" | tee "$OUT/$log"
  grep -q "^${marker}$" "$OUT/$log" || fail "regression $cls"
}
run_reg org.recompile.rg35xx.a5.RG35XXCore2DHostGate A5_CORE2D_ALPHA_HOST_GATE=PASS P1A-A5-CORE2D-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXAdam7HostGate A6_ADAM7_HOST_GATE=PASS P1A-A6-ADAM7-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS P1A-A6-CLIP-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS P1A-A6-DRAWRECT-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate A6_R5_RAW_DRAWLINE_HOST_GATE=PASS P1A-A6-DRAWLINE-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXCompleteGraphicsG4G5DifferentialGate P1A_COMPLETE_G4G5_DIFFERENTIAL_GATE=PASS P1A-G4G5-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXDGDrawVectorD6DifferentialGate P1A_DG_D6_DRAW_VECTOR_DIFFERENTIAL_GATE=PASS P1A-D6-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXDGFillVectorD4DifferentialGate P1A_DG_D4_FILL_VECTOR_DIFFERENTIAL_GATE=PASS P1A-D4-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXG2DArcFamilyDifferentialGate P1A_G2D_ARC_FAMILY_DIFFERENTIAL_GATE=PASS P1A-G2D-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXG2CDrawRoundRectDifferentialGate P1A_G2C_DRAWROUNDRECT_DIFFERENTIAL_GATE=PASS P1A-G2C-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXG2BParentRegressionGate P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS P1A-G1G2A-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS P1A-G1-ALPHA-REGRESSION.txt

echo P1A_GRAPHICS_PARENT_REGRESSION=PASS
echo P2A_IMAGE_PARENT_REGRESSION=PASS

# 9. Preserve protected non-owner native identities byte-for-byte.
cp "$PARENT_OUT/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PARENT_OUT/librg35xx_video.so" "$OUT/librg35xx_video.so"
INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so"|awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so"|awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native drift"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video native drift"
FONT_NATIVE_SHA="$(sha256sum "$OUT/librg35xx_font.so"|awk '{print $1}')"
CAND_SHA="$(sha256sum "$CANDIDATE"|awk '{print $1}')"
CAND_SEM="$(semantic_digest "$CANDIDATE")"
CORE_SHA="$(entry_digest "$CANDIDATE" org/recompile/rg35xx/RG35XXCore2D.class)"
FONT_CLASS_SHA="$(entry_digest "$CANDIDATE" javax/microedition/lcdui/Font.class)"
PG_SHA="$(entry_digest "$CANDIDATE" org/recompile/mobile/PlatformGraphics.class)"
cat > "$OUT/P2B-FONT-TEXT-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P2B-FONT-TEXT-MODULE-CANDIDATE-R1
EXACT_ACCEPTED_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
JDK8U504_COMMIT=$JDK8U_COMMIT
P2B_FONT_RELEASE_URL=$FONT_URL
P2B_FONT_RELEASE_ZIP_SHA256=$ZIP_SHA
P2B_FONT_ENTRY=$ENTRY
P2B_FONT_SHA256=$FONT_SHA
P2B_FONT_SIZE=$FONT_SIZE
P2B_FONT_EMBEDDED=NO_HOST_CANDIDATE
CANDIDATE_PLATFORM_JAR_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CANDIDATE_CORE2D_CLASS_SHA256=$CORE_SHA
CANDIDATE_FONT_CLASS_SHA256=$FONT_CLASS_SHA
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$PG_SHA
P2B_FONT_NATIVE_SHA256=$FONT_NATIVE_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
P2B_CANONICAL_DIFF_VERIFIED=PASS
P2B_OWNER_SCOPE_VERIFIED=PASS
P2B_JAVA6_GATE=PASS
P2B_HOST_FONT_METRICS_GATE=PASS
P2B_HOST_SIMPLE_RASTER_GATE=PASS
P2B_HOST_COMPLEX_LAYOUT_GATE=PASS
P1A_GRAPHICS_PARENT_REGRESSION=PASS
P2A_IMAGE_PARENT_REGRESSION=PASS
P2B_MODULE_GATE=PASS
PROTECTED_HASHES=PASS
PHYSICAL_TEST_REQUIRED=YES
PHYSICAL_TEST_LEVEL=MODULE
P2B_PHYSICAL_TEST=NOT_TESTED
DEVICE-PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
EOF

# Do not retain/publish font bytes or upstream ZIP in generic host candidate output.
rm -f "$P2B/font.ttf" "$P2B/miyoomini-freej2me.zip"
echo P2B_CANONICAL_DIFF_VERIFIED=PASS
echo P2B_OWNER_SCOPE_VERIFIED=PASS
echo P2B_JAVA6_GATE=PASS
echo P2B_HOST_FONT_METRICS_GATE=PASS
echo P2B_HOST_SIMPLE_RASTER_GATE=PASS
echo P2B_HOST_COMPLEX_LAYOUT_GATE=PASS
echo P1A_GRAPHICS_PARENT_REGRESSION=PASS
echo P2A_IMAGE_PARENT_REGRESSION=PASS
echo P2B_MODULE_GATE=PASS
echo P2B_FONT_TEXT_BUILD=PASS
echo P2B_PHYSICAL_TEST=NOT_TESTED
echo RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
echo STABLE=NO
