#!/usr/bin/env bash
set -euo pipefail
PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
UPSTREAM=https://github.com/aweigit/freej2me-miyoomini.git
OUT=${1:-m1_4a_audit}
rm -rf "$OUT" upstream-m1.4a
mkdir -p "$OUT"
exec > >(tee "$OUT/M1.4A-AUDIT.txt") 2>&1

echo M1_4A_JAVA5_BOOT_SLICE_AUDIT
echo SOURCE_PIN=$PIN
echo PRIMARY_VARIABLE=JAVA5_SOURCE_COMPATIBILITY_OF_MINIMAL_2D_BOOT_SLICE_ONLY

git clone -q "$UPSTREAM" upstream-m1.4a
git -C upstream-m1.4a checkout -q "$PIN"
test "$(git -C upstream-m1.4a rev-parse HEAD)" = "$PIN"

cd upstream-m1.4a
printf '%s\n' '== MODERN API INVENTORY: CORE RECOMPILE ==' 
grep -R -n -E 'java\.nio\.file|java\.util\.function|java\.util\.stream' src/org/recompile src/javax src/com 2>/dev/null || true
printf '%s\n' '== MODERN API INVENTORY: LWJGL OPTIONAL ==' 
grep -R -l -E 'java\.nio\.file|java\.util\.function|java\.util\.stream' src/org/lwjgl 2>/dev/null | sort || true

# Bounded backport: only known boot/core-adjacent java.nio.file uses. Keep originals in git diff.
python3 - <<'PY'
from pathlib import Path
p=Path('src/org/recompile/freej2me/SDLConfig.java')
s=p.read_text()
s=s.replace('import java.nio.file.Files;\n','').replace('import java.nio.file.Paths;\n','')
s=s.replace('Files.createDirectories(Paths.get(configPath));','new File(configPath).mkdirs();')
p.write_text(s)

p=Path('src/org/recompile/mobile/MIDletLoader.java')
s=p.read_text()
for imp in ['import java.nio.file.Path;\n','import java.nio.file.Paths;\n','import java.nio.file.Files;\n','import java.nio.file.FileSystem;\n']:
    s=s.replace(imp,'')
# Do not invent replacements for uses not proven equivalent; compile gate must expose them.
p.write_text(s)
PY

git diff -- src/org/recompile/freej2me/SDLConfig.java src/org/recompile/mobile/MIDletLoader.java > ../"$OUT"/BOOT-SLICE.patch

# Explicit exclusions for first 2D boot feasibility gate.
find src -name '*.java' \
  ! -path 'src/org/lwjgl/*' \
  ! -path 'src/javax/microedition/m3g/*' \
  ! -path 'src/com/mascotcapsule/*' \
  ! -name 'PlatformPlayer.java' \
  -print | sort > ../"$OUT"/BOOT-SLICE-SOURCES.txt
cat > ../"$OUT"/EXCLUSIONS.txt <<'EOF'
src/org/lwjgl/** = OPTIONAL_3D/LWJGL; broad Java8+ dependency surface
src/javax/microedition/m3g/** = OPTIONAL_3D
src/com/mascotcapsule/** = OPTIONAL_3D
src/org/recompile/mobile/PlatformPlayer.java = AUDIO/MEDIA; deferred
EOF

mkdir -p ../"$OUT"/classes
set +e
javac -source 5 -target 5 -encoding UTF-8 -d ../"$OUT"/classes @../"$OUT"/BOOT-SLICE-SOURCES.txt 2>../"$OUT"/JAVAC-ERRORS.txt
RC=$?
set -e
echo JAVAC_RC=$RC
if [ "$RC" -eq 0 ]; then
  python3 - <<'PY'
from pathlib import Path
bad=[]; count=0
for p in Path('../m1_4a_audit/classes').rglob('*.class'):
    b=p.read_bytes(); major=int.from_bytes(b[6:8],'big'); count+=1
    if major != 49: bad.append((str(p),major))
print('CLASS_COUNT=%d'%count)
print('CLASS_MAJOR_49_ONLY=%s'%('YES' if not bad else 'NO'))
for x in bad[:50]: print('BAD_CLASS_MAJOR',*x)
raise SystemExit(1 if bad else 0)
PY
  echo M1_4A_RESULT=PASS
else
  echo M1_4A_RESULT=FAIL_CLOSED
  sed -n '1,240p' ../"$OUT"/JAVAC-ERRORS.txt
fi
exit "$RC"
