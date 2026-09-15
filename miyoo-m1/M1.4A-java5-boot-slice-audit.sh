#!/usr/bin/env bash
set -euo pipefail
PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
UPSTREAM=https://github.com/aweigit/freej2me-miyoomini.git
OUT=${1:-m1_4a_audit}
rm -rf "$OUT" upstream-m1.4a
mkdir -p "$OUT"
exec > >(tee "$OUT/M1.4A-AUDIT.txt") 2>&1

echo M1_4A_1_JAVA5_BOOT_SLICE_AUDIT
echo SOURCE_PIN=$PIN
echo PRIMARY_VARIABLE=JAVA5_SYNTAX_COMPATIBILITY_OF_THE_SAME_MINIMAL_2D_BOOT_SLICE

git clone -q "$UPSTREAM" upstream-m1.4a
git -C upstream-m1.4a checkout -q "$PIN"
test "$(git -C upstream-m1.4a rev-parse HEAD)" = "$PIN"

cd upstream-m1.4a
printf '%s\n' '== MODERN API INVENTORY: CORE RECOMPILE =='
grep -R -n -E 'java\.nio\.file|java\.util\.function|java\.util\.stream' src/org/recompile src/javax src/com 2>/dev/null || true
printf '%s\n' '== MODERN API INVENTORY: LWJGL OPTIONAL =='
grep -R -l -E 'java\.nio\.file|java\.util\.function|java\.util\.stream' src/org/lwjgl 2>/dev/null | sort || true

# M1.4A.1 bounded backport. Only exact syntax families exposed by parent run 34914899837.
python3 - <<'PY'
from pathlib import Path

def edit(path, replacements, inserts=()):
    p=Path(path); s=p.read_text()
    for old,new in replacements:
        if old not in s:
            raise SystemExit('EXPECTED_TEXT_MISSING: %s: %r' % (path, old[:100]))
        s=s.replace(old,new)
    for anchor,text in inserts:
        if anchor not in s:
            raise SystemExit('EXPECTED_ANCHOR_MISSING: %s' % path)
        s=s.replace(anchor,anchor+text,1)
    p.write_text(s)

# Existing M1.4A java.nio.file bounded edits.
edit('src/org/recompile/freej2me/SDLConfig.java',[
 ('import java.nio.file.Files;\n',''),('import java.nio.file.Paths;\n',''),
 ('Files.createDirectories(Paths.get(configPath));','new File(configPath).mkdirs();')])
p=Path('src/org/recompile/mobile/MIDletLoader.java'); s=p.read_text()
for imp in ['import java.nio.file.Path;\n','import java.nio.file.Paths;\n','import java.nio.file.Files;\n','import java.nio.file.FileSystem;\n']:
    s=s.replace(imp,'')
s=s.replace('HashMap<String, String> env = new HashMap<>();','HashMap<String, String> env = new HashMap<String, String>();')
p.write_text(s)

# Exact diamond operators reported by M1.4A in the retained 2D/core set.
exact={
 'src/javax/microedition/lcdui/event/CommandActionEvent.java': [('new ArrayStack<>()','new ArrayStack<CommandActionEvent>()')],
 'src/javax/microedition/lcdui/event/EventQueue.java': [('new LinkedList<>()','new LinkedList<Event>()')],
 'src/javax/microedition/rms/impl/RecordStoreImpl.java': [('new HashMap<>()','new HashMap<Integer, byte[]>()')],
 'src/javax/microedition/util/LinkedList.java': [('new ArrayStack<>()','new ArrayStack<LinkedEntry<E>>()')],
 'src/org/recompile/mobile/MyMethodVisitor.java': [('new ArrayList<>()','new ArrayList<Label>()')],
}
for path,repls in exact.items(): edit(path,repls)

# RMS enumeration: diamond + lambda -> Java-5 anonymous Comparator.
edit('src/javax/microedition/rms/impl/RecordEnumerationImpl.java',[
 ('import java.util.Collections;\n','import java.util.Collections;\nimport java.util.Comparator;\n'),
 ('new Vector<>()','new Vector<EnumerationRecord>()'),
 ('Collections.sort(enumerationRecords, (lhs, rhs) -> comparator.compare(lhs.value, rhs.value));',
  'Collections.sort(enumerationRecords, new Comparator<EnumerationRecord>() {\n\t\t\t\tpublic int compare(EnumerationRecord lhs, EnumerationRecord rhs) {\n\t\t\t\t\treturn comparator.compare(lhs.value, rhs.value);\n\t\t\t\t}\n\t\t\t});')])

# FileConnection: diamond + lambda + try-with-resources -> Java-5 forms.
edit('src/org/microemu/cldc/file/FileSystemFileConnection.java',[
 ('Vector<String> list = new Vector<>();','Vector<String> list = new Vector<String>();'),
 ('Arrays.sort(files, (f1, f2) -> f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase()));',
  'Arrays.sort(files, new java.util.Comparator<File>() {\n\t\t\tpublic int compare(File f1, File f2) {\n\t\t\t\treturn f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase());\n\t\t\t}\n\t\t});'),
 ('try (RandomAccessFile raf = new RandomAccessFile(file, "rw")) {\n\t\t\traf.setLength(byteOffset);\n\t\t}',
  'RandomAccessFile raf = new RandomAccessFile(file, "rw");\n\t\ttry {\n\t\t\traf.setLength(byteOffset);\n\t\t} finally {\n\t\t\traf.close();\n\t\t}')])

# ASM: preserve close semantics while removing Java-7 try-with-resources syntax.
edit('src/org/objectweb/asm/ClassReader.java',[
 ('try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {',
  'ByteArrayOutputStream outputStream = new ByteArrayOutputStream();\n    try {')])
edit('src/org/objectweb/asm/Constants.java',[
 ('try (DataInputStream callerClassStream = new DataInputStream(classInputStream); ) {\n      callerClassStream.readInt();\n      minorVersion = callerClassStream.readUnsignedShort();\n    } catch (IOException ioe) {',
  'DataInputStream callerClassStream = new DataInputStream(classInputStream);\n    try {\n      callerClassStream.readInt();\n      minorVersion = callerClassStream.readUnsignedShort();\n      callerClassStream.close();\n    } catch (IOException ioe) {')])
PY

git diff -- src > ../"$OUT"/BOOT-SLICE.patch

# Explicit exclusions for first 2D boot feasibility gate.
find src -name '*.java' \
  ! -path 'src/org/lwjgl/*' \
  ! -path 'src/javax/microedition/m3g/*' \
  ! -path 'src/com/mascotcapsule/*' \
  ! -path 'src/ru/woesss/j2me/micro3d/*' \
  ! -name 'PlatformPlayer.java' \
  ! -name 'AndroidRecordStoreManager.java' \
  -print | sort > ../"$OUT"/BOOT-SLICE-SOURCES.txt
cat > ../"$OUT"/EXCLUSIONS.txt <<'EOF'
src/org/lwjgl/** = OPTIONAL_3D/LWJGL; broad Java8+ dependency surface
src/javax/microedition/m3g/** = OPTIONAL_3D
src/com/mascotcapsule/** = OPTIONAL_3D
src/ru/woesss/j2me/micro3d/** = OPTIONAL_3D/MICRO3D
src/org/recompile/mobile/PlatformPlayer.java = AUDIO/MEDIA; deferred
src/javax/microedition/rms/impl/AndroidRecordStoreManager.java = ANDROID-SPECIFIC RMS backend; not RG35XX boot path
EOF

mkdir -p ../"$OUT"/classes
set +e
javac -version 2>&1 | tee ../"$OUT"/JAVAC-VERSION.txt
javac -source 5 -target 5 -encoding UTF-8 -d ../"$OUT"/classes @../"$OUT"/BOOT-SLICE-SOURCES.txt 2>../"$OUT"/JAVAC-ERRORS.txt
RC=$?
set -e
echo JAVAC_RC=$RC
if [ "$RC" -eq 0 ]; then
  OUT_DIR="$OUT" python3 - <<'PY'
import os
from pathlib import Path
root=Path('..')/os.environ['OUT_DIR']/ 'classes'
bad=[]; count=0
for p in root.rglob('*.class'):
    b=p.read_bytes(); major=int.from_bytes(b[6:8],'big'); count+=1
    if major != 49: bad.append((str(p),major))
print('CLASS_COUNT=%d'%count)
print('CLASS_MAJOR_49_ONLY=%s'%('YES' if not bad else 'NO'))
for x in bad[:50]: print('BAD_CLASS_MAJOR',*x)
raise SystemExit(1 if bad else 0)
PY
  echo M1_4A_1_RESULT=PASS
else
  echo M1_4A_1_RESULT=FAIL_CLOSED
  sed -n '1,280p' ../"$OUT"/JAVAC-ERRORS.txt
fi
exit "$RC"
