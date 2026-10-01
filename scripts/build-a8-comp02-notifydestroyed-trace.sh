#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A8_COMP02_TRACE_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"

BASE="$ROOT/out/a7-audio-sdl1"
BASE_JAR="$BASE/freej2me-rg35xx.jar"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
SRC="$UPSTREAM/src/javax/microedition/midlet/MIDlet.java"
BUILD="$ROOT/build/a8-comp02-notifydestroyed-trace"
PATCHED_SRC="$BUILD/src/javax/microedition/midlet/MIDlet.java"
CLASSES="$BUILD/classes"
OUT="$ROOT/out/a8-comp02-notifydestroyed-trace"
PAYLOAD="$OUT/RG35XX-A8-COMP02-TRACE-R1"
LAUNCHER="$OUT/RG35XX-A8-COMP02-TRACE-R1.sh"

[ -f "$BASE_JAR" ] || fail "accepted A7 parent missing"
[ -f "$SRC" ] || fail "canonical MIDlet source missing"
for f in librg35xx_input.so librg35xx_video.so libaudio.so; do
  [ -f "$BASE/$f" ] || fail "accepted A7 artifact missing: $f"
done

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
[ "$BASE_SEMANTIC" = "7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf" ] || fail "accepted A8/A7 semantic mismatch $BASE_SEMANTIC"
[ "$(sha256sum "$BASE/librg35xx_input.so" | awk '{print $1}')" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail INPUT_IDENTITY
[ "$(sha256sum "$BASE/librg35xx_video.so" | awk '{print $1}')" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail VIDEO_IDENTITY
[ "$(sha256sum "$BASE/libaudio.so" | awk '{print $1}')" = "4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644" ] || fail AUDIO_IDENTITY

echo A8_COMP02_TRACE_PARENT_IDENTITY_GATE=PASS

rm -rf "$BUILD" "$OUT"
mkdir -p "$(dirname "$PATCHED_SRC")" "$CLASSES" "$PAYLOAD"
cp "$SRC" "$PATCHED_SRC"

python3 - "$PATCHED_SRC" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
old='''\tpublic final void notifyDestroyed()\n\t{ \n\t\tSdlMixerManager.shutdown();\n\n\t\tSystem.out.println("MIDlet sent Destroyed Notification");\n\t\tSystem.exit(0);\n\t}\n'''
new='''\tpublic final void notifyDestroyed()\n\t{ \n\t\tThread currentThread = Thread.currentThread();\n\t\tRuntime runtime = Runtime.getRuntime();\n\t\tSystem.out.println("RG35XX_A8_COMP02_NOTIFYDESTROYED_TRACE=BEGIN");\n\t\tSystem.out.println("RG35XX_A8_COMP02_NOTIFYDESTROYED_THREAD=" + currentThread.getName());\n\t\tSystem.out.println("RG35XX_A8_COMP02_MEMORY_FREE=" + runtime.freeMemory());\n\t\tSystem.out.println("RG35XX_A8_COMP02_MEMORY_TOTAL=" + runtime.totalMemory());\n\t\tSystem.out.println("RG35XX_A8_COMP02_MEMORY_MAX=" + runtime.maxMemory());\n\t\tException caller = new Exception("RG35XX_A8_COMP02_NOTIFYDESTROYED_CALLER");\n\t\tcaller.printStackTrace(System.out);\n\t\tSystem.out.println("RG35XX_A8_COMP02_NOTIFYDESTROYED_TRACE=END");\n\n\t\tSdlMixerManager.shutdown();\n\n\t\tSystem.out.println("MIDlet sent Destroyed Notification");\n\t\tSystem.exit(0);\n\t}\n'''
if s.count(old) != 1:
    raise SystemExit('A8_COMP02_TRACE_PATCH_ANCHOR_FAIL count=%d' % s.count(old))
p.write_text(s.replace(old,new), encoding='utf-8')
print('A8_COMP02_TRACE_PATCH_SCOPE=NOTIFYDESTROYED_ONLY')
PY

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$BASE_JAR:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" "$PATCHED_SRC"

CANDIDATE_JAR="$PAYLOAD/freej2me-rg35xx.jar"
cp "$BASE_JAR" "$CANDIDATE_JAR"
"$JAVA8/bin/jar" uf "$CANDIDATE_JAR" -C "$CLASSES" javax/microedition/midlet/MIDlet.class

python3 - "$BASE_JAR" "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('A8_COMP02_TRACE_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
    expected=['javax/microedition/midlet/MIDlet.class']
    if diff != expected:
        raise SystemExit('A8_COMP02_TRACE_SCOPE_FAIL changed='+repr(diff))
    data=b.read(expected[0])
    required=[
      b'RG35XX_A8_COMP02_NOTIFYDESTROYED_TRACE=BEGIN',
      b'RG35XX_A8_COMP02_NOTIFYDESTROYED_CALLER',
      b'RG35XX_A8_COMP02_MEMORY_FREE=',
      b'RG35XX_A8_COMP02_MEMORY_TOTAL=',
      b'RG35XX_A8_COMP02_MEMORY_MAX=',
      b'MIDlet sent Destroyed Notification'
    ]
    for marker in required:
        if marker not in data:
            raise SystemExit('A8_COMP02_TRACE_MARKER_FAIL '+repr(marker))
    major=int.from_bytes(data[6:8],'big')
    if major > 50:
        raise SystemExit('A8_COMP02_TRACE_JAVA6_FAIL major=%d' % major)
print('A8_COMP02_TRACE_CHANGED_JAR_ENTRY=javax/microedition/midlet/MIDlet.class')
print('A8_COMP02_TRACE_SCOPE_GATE=PASS')
print('A8_COMP02_TRACE_JAVA6_GATE=PASS')
PY

cp "$BASE/librg35xx_input.so" "$PAYLOAD/"
cp "$BASE/librg35xx_video.so" "$PAYLOAD/"
cp "$BASE/libaudio.so" "$PAYLOAD/"
head -c 123480 /dev/zero > "$PAYLOAD/a7-a1p5-rw-silence-prime.s32le"
[ "$(sha256sum "$PAYLOAD/a7-a1p5-rw-silence-prime.s32le" | awk '{print $1}')" = "8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e" ] || fail PRIME_IDENTITY

TRACE_SHA="$(sha256sum "$CANDIDATE_JAR" | awk '{print $1}')"
TRACE_SEMANTIC="$(semantic_digest "$CANDIDATE_JAR")"
BASE_RAW="$(sha256sum "$BASE_JAR" | awk '{print $1}')"

cat > "$LAUNCHER" <<EOF
#!/bin/sh
APP="\$(CDPATH= cd -- "\$(dirname -- "\$0")" 2>/dev/null && pwd)"
PKG="\$APP/RG35XX-A8-COMP02-TRACE-R1"
OUT=/mnt/mmc/A8-COMP02-NOTIFYDESTROYED-TRACE.txt
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=$TRACE_SHA
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
PRIME="\$PKG/a7-a1p5-rw-silence-prime.s32le"
: >"\$OUT"
fail(){ echo "TRACE_PRECONDITION=FAIL:\$1" >>"\$OUT"; sync; exit 20; }
GAME="\$1"
[ -n "\$GAME" ] || fail GAME_ARGUMENT_MISSING
[ -f "\$GAME" ] || fail GAME_FILE_MISSING
[ -x "\$JAMVM" ] || fail JAMVM_MISSING
[ -f "\$GLIBJ" ] || fail GLIBJ_MISSING
for F in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so a7-a1p5-rw-silence-prime.s32le; do [ -f "\$PKG/\$F" ] || fail "MISSING:\$F"; done
APLAY="\$(command -v aplay 2>/dev/null || true)"
[ -n "\$APLAY" ] && [ -x "\$APLAY" ] || fail APLAY_MISSING
JB="\$(sha256sum "\$JAMVM"|awk '{print \$1}')"; GB="\$(sha256sum "\$GLIBJ"|awk '{print \$1}')"
PH="\$(sha256sum "\$PKG/freej2me-rg35xx.jar"|awk '{print \$1}')"; IH="\$(sha256sum "\$PKG/librg35xx_input.so"|awk '{print \$1}')"
VH="\$(sha256sum "\$PKG/librg35xx_video.so"|awk '{print \$1}')"; AH="\$(sha256sum "\$PKG/libaudio.so"|awk '{print \$1}')"; PRH="\$(sha256sum "\$PRIME"|awk '{print \$1}')"
[ "\$JB" = "\$EXPECTED_JAMVM" ] || fail JAMVM_HASH; [ "\$GB" = "\$EXPECTED_GLIBJ" ] || fail GLIBJ_HASH; [ "\$PH" = "\$EXPECTED_PLATFORM" ] || fail PLATFORM_HASH
[ "\$IH" = "\$EXPECTED_INPUT" ] || fail INPUT_HASH; [ "\$VH" = "\$EXPECTED_VIDEO" ] || fail VIDEO_HASH; [ "\$AH" = "\$EXPECTED_AUDIO" ] || fail AUDIO_HASH; [ "\$PRH" = "\$EXPECTED_PRIME" ] || fail PRIME_HASH
echo 'TRACE_IDENTITY_GATE=PASS' >>"\$OUT"
echo "TRACE_GAME=\$GAME" >>"\$OUT"; echo "TRACE_GAME_SHA256=\$(sha256sum "\$GAME"|awk '{print \$1}')" >>"\$OUT"
export SDL_AUDIODRIVER=alsa
"\$APLAY" -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 "\$PRIME" >>"\$OUT" 2>&1 || fail APLAY_PRIME
DATA="\$PKG/data"; mkdir -p "\$DATA" || fail DATA_DIR
LD_LIBRARY_PATH="\$PKG\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}" "\$JAMVM" -Xmx64m -Drg35xx.raw2d=true -Drg35xx.native.dir="\$PKG" -cp "\$GLIBJ:\$PKG/freej2me-rg35xx.jar" org.recompile.rg35xx.RG35XXLauncher "\$GAME" 240 320 "\$DATA" "\$DATA" >>"\$OUT" 2>&1
RC=\$?
echo "TRACE_RUNTIME_EXIT_CODE=\$RC" >>"\$OUT"; sync; exit "\$RC"
EOF
chmod +x "$LAUNCHER"

cat > "$OUT/A8-COMP02-TRACE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
BASELINE=A8
CANDIDATE=A8-COMP02-NOTIFYDESTROYED-TRACE-R1
PURPOSE=TRACE_GAMEPLAY_TRANSITION_EXIT_CALLER_ONLY
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
BASE_PLATFORM_RAW_SHA256=$BASE_RAW
BASE_PLATFORM_SEMANTIC_SHA256=$BASE_SEMANTIC
TRACE_PLATFORM_RAW_SHA256=$TRACE_SHA
TRACE_PLATFORM_SEMANTIC_SHA256=$TRACE_SEMANTIC
CHANGED_JAR_ENTRIES=javax/microedition/midlet/MIDlet.class
TRACE_DELTA=NOTIFYDESTROYED_THREAD_MEMORY_CALLER_STACK_ONLY
NOTIFYDESTROYED_SHUTDOWN_ORDER=UNCHANGED
SYSTEM_EXIT_BEHAVIOR=UNCHANGED
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
PRIME_PCM_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
CANONICAL_GITLINK_MUTATED=NO
RUNTIME_SEMANTIC_CHANGE=TRACE_ONLY
PRODUCTION_BASELINE_CHANGED=NO
DEVICE_PASS=NO
STABLE=NO
EOF

(
 cd "$OUT"
 find . -type f ! -name SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt
 sha256sum -c SHA256SUMS.txt
)

echo A8_COMP02_NOTIFYDESTROYED_TRACE_BUILD=PASS
cat "$OUT/A8-COMP02-TRACE-IDENTITY.txt"
