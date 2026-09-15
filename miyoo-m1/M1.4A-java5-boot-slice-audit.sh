#!/usr/bin/env bash
set -euo pipefail
PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
UPSTREAM=https://github.com/aweigit/freej2me-miyoomini.git
OUT=${1:-m1_4a_audit}
rm -rf "$OUT" upstream-m1.4a
mkdir -p "$OUT"
exec > >(tee "$OUT/M1.4A-AUDIT.txt") 2>&1

echo M1_4A_3_JAVA5_BOOT_BOUNDARY_AUDIT
echo SOURCE_PIN=$PIN
echo PRIMARY_VARIABLE=CLOSE_2D_BOOT_COMPILE_BOUNDARY_WITHOUT_CORE_API_BACKPORT

git clone -q "$UPSTREAM" upstream-m1.4a
git -C upstream-m1.4a checkout -q "$PIN"
test "$(git -C upstream-m1.4a rev-parse HEAD)" = "$PIN"
cd upstream-m1.4a

python3 - <<'PY'
from pathlib import Path

def edit(path, replacements):
    p=Path(path); s=p.read_text()
    for old,new in replacements:
        if old not in s: raise SystemExit('EXPECTED_TEXT_MISSING: %s: %r' % (path, old[:100]))
        s=s.replace(old,new)
    p.write_text(s)

edit('src/org/recompile/freej2me/SDLConfig.java',[
 ('import java.nio.file.Files;\n',''),('import java.nio.file.Paths;\n',''),
 ('Files.createDirectories(Paths.get(configPath));','new File(configPath).mkdirs();')])
p=Path('src/org/recompile/mobile/MIDletLoader.java'); s=p.read_text()
for imp in ['import java.nio.file.Path;\n','import java.nio.file.Paths;\n','import java.nio.file.Files;\n','import java.nio.file.FileSystem;\n']:
    s=s.replace(imp,'')
s=s.replace('HashMap<String, String> env = new HashMap<>();','HashMap<String, String> env = new HashMap<String, String>();')
p.write_text(s)

exact={
 'src/javax/microedition/lcdui/event/CommandActionEvent.java':[('new ArrayStack<>()','new ArrayStack<CommandActionEvent>()')],
 'src/javax/microedition/lcdui/event/EventQueue.java':[('new LinkedList<>()','new LinkedList<Event>()')],
 'src/javax/microedition/rms/impl/RecordStoreImpl.java':[('new HashMap<>()','new HashMap<Integer, byte[]>()'),('new Vector<>()','new Vector<RecordListener>()')],
 'src/javax/microedition/util/LinkedList.java':[('new ArrayStack<>()','new ArrayStack<LinkedEntry<E>>()'),('new LinkedEntry<>()','new LinkedEntry<E>()')],
 'src/org/recompile/mobile/MyMethodVisitor.java':[('new ArrayList<>()','new ArrayList<Label>()')],
}
for path,repls in exact.items(): edit(path,repls)
edit('src/javax/microedition/rms/impl/RecordEnumerationImpl.java',[
 ('import java.util.Collections;\n','import java.util.Collections;\nimport java.util.Comparator;\n'),('new Vector<>()','new Vector<EnumerationRecord>()'),
 ('Collections.sort(enumerationRecords, (lhs, rhs) -> comparator.compare(lhs.value, rhs.value));','Collections.sort(enumerationRecords, new Comparator<EnumerationRecord>() { public int compare(EnumerationRecord lhs, EnumerationRecord rhs) { return comparator.compare(lhs.value, rhs.value); } });')])
edit('src/org/microemu/cldc/file/FileSystemFileConnection.java',[
 ('Vector<String> list = new Vector<>();','Vector<String> list = new Vector<String>();'),
 ('Arrays.sort(files, (f1, f2) -> f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase()));','Arrays.sort(files, new java.util.Comparator<File>() { public int compare(File f1, File f2) { return f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase()); } });'),
 ('try (RandomAccessFile raf = new RandomAccessFile(file, "rw")) {\n\t\t\traf.setLength(byteOffset);\n\t\t}','RandomAccessFile raf = new RandomAccessFile(file, "rw");\n\t\ttry { raf.setLength(byteOffset); } finally { raf.close(); }')])
edit('src/org/objectweb/asm/ClassReader.java',[('try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {','ByteArrayOutputStream outputStream = new ByteArrayOutputStream();\n    try {')])
edit('src/org/objectweb/asm/Constants.java',[('try (DataInputStream callerClassStream = new DataInputStream(classInputStream); ) {\n      callerClassStream.readInt();\n      minorVersion = callerClassStream.readUnsignedShort();\n    } catch (IOException ioe) {','DataInputStream callerClassStream = new DataInputStream(classInputStream);\n    try { callerClassStream.readInt(); minorVersion = callerClassStream.readUnsignedShort(); callerClassStream.close();\n    } catch (IOException ioe) {')])
PY

git diff -- src > ../"$OUT"/BOOT-SLICE.patch

# M1.4A.3 closes only deferred/optional dependency boundaries. MIDletLoader stays in-slice intentionally.
find src -name '*.java' \
  ! -path 'src/org/lwjgl/*' \
  ! -path 'src/javax/microedition/m3g/*' \
  ! -path 'src/com/mascotcapsule/*' \
  ! -path 'src/ru/woesss/j2me/micro3d/*' \
  ! -path 'src/android/opengl/*' \
  ! -path 'src/javax/microedition/media/*' \
  ! -name 'PlatformPlayer.java' \
  ! -name 'SdlMixerManager.java' \
  ! -path 'src/javax/microedition/rms/*' \
  ! -name 'MyMethodVisitor.java' \
  -print | sort > ../"$OUT"/BOOT-SLICE-SOURCES.txt
cat > ../"$OUT"/EXCLUSIONS.txt <<'EOF'
src/org/lwjgl/** = OPTIONAL_3D/LWJGL
src/javax/microedition/m3g/** = OPTIONAL_3D
src/com/mascotcapsule/** = OPTIONAL_3D
src/ru/woesss/j2me/micro3d/** = OPTIONAL_3D/MICRO3D
src/android/opengl/** = OPTIONAL_3D support surface
src/javax/microedition/media/** = AUDIO/MEDIA API surface deferred with PlatformPlayer
src/org/recompile/mobile/PlatformPlayer.java = AUDIO/MEDIA implementation deferred
src/org/recompile/mobile/SdlMixerManager.java = AUDIO native bridge deferred
src/javax/microedition/rms/** = RMS persistence deferred from first boot-boundary diagnostic; Android backend coupling isolated
src/org/recompile/mobile/MyMethodVisitor.java = bytecode rewrite helper with Java7 string-switch; deferred from first boot-boundary diagnostic
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
root=Path('..')/os.environ['OUT_DIR']/'classes'; bad=[]; count=0
for p in root.rglob('*.class'):
    b=p.read_bytes(); major=int.from_bytes(b[6:8],'big'); count+=1
    if major != 49: bad.append((str(p),major))
print('CLASS_COUNT=%d'%count); print('CLASS_MAJOR_49_ONLY=%s'%('YES' if not bad else 'NO'))
for x in bad[:50]: print('BAD_CLASS_MAJOR',*x)
raise SystemExit(1 if bad else 0)
PY
  echo M1_4A_3_RESULT=PASS_BOUNDARY
else
  echo M1_4A_3_RESULT=FAIL_CLOSED
  sed -n '1,320p' ../"$OUT"/JAVAC-ERRORS.txt
fi
exit "$RC"
