#!/usr/bin/env bash
set -euo pipefail
PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
UPSTREAM=https://github.com/aweigit/freej2me-miyoomini.git
OUT=${1:-m1_4a_audit}
rm -rf "$OUT" upstream-m1.4a
mkdir -p "$OUT"
exec > >(tee "$OUT/M1.4A-AUDIT.txt") 2>&1

echo M1_4A_4_MIDLETLOADER_JAVA5_RESOURCE_AUDIT
echo SOURCE_PIN=$PIN
echo PRIMARY_VARIABLE=MIDLETLOADER_RESOURCE_ACCESS_JAVA7_NIO_TO_JAVA5_JARFILE

git clone -q "$UPSTREAM" upstream-m1.4a
git -C upstream-m1.4a checkout -q "$PIN"
test "$(git -C upstream-m1.4a rev-parse HEAD)" = "$PIN"
cd upstream-m1.4a

python3 - <<'PY'
from pathlib import Path
import re

def edit(path, replacements):
    p=Path(path); s=p.read_text()
    for old,new in replacements:
        if old not in s: raise SystemExit('EXPECTED_TEXT_MISSING: %s: %r' % (path, old[:100]))
        s=s.replace(old,new)
    p.write_text(s)

edit('src/org/recompile/freej2me/SDLConfig.java',[
 ('import java.nio.file.Files;\n',''),('import java.nio.file.Paths;\n',''),
 ('Files.createDirectories(Paths.get(configPath));','new File(configPath).mkdirs();')])

# M1.4A.4 primary delta: MIDletLoader resource access only.
p=Path('src/org/recompile/mobile/MIDletLoader.java'); s=p.read_text()
for imp in ['import java.nio.file.Path;\n','import java.nio.file.Paths;\n','import java.nio.file.Files;\n','import java.nio.file.FileSystem;\n','import java.nio.file.FileSystems;\n','import java.nio.file.StandardOpenOption;\n','import java.nio.file.DirectoryStream;\n','import java.nio.file.StandardCopyOption;\n']:
    s=s.replace(imp,'')
s=s.replace('import java.io.IOException;\n','import java.io.IOException;\nimport java.io.File;\nimport java.util.jar.JarFile;\nimport java.util.jar.JarEntry;\n')
s=s.replace('HashMap<String, String> env = new HashMap<>();','HashMap<String, String> env = new HashMap<String, String>();')
s=s.replace('FileSystem zipfs;','JarFile jarFile;')
# Every constructor receives the same Java5-compatible JarFile initialization after URLClassLoader setup.
s=s.replace('\t\tsuper(urls);\n','\t\tsuper(urls);\n\t\tinitJarFile(urls);\n')
# Remove the Java7 ZIP FileSystem construction block in the (urls,u,jarname) constructor.
start=s.find('\t\tString url="";')
end=s.find('\n\t\ttry\n\t\t{\n\t\t\tSystem.setProperty("microedition.platform"', start)
if start < 0 or end < 0: raise SystemExit('MIDLETLOADER_ZIPFS_BLOCK_NOT_FOUND')
s=s[:start]+s[end:]
# Replace active Path resource model with JarEntry. Commented Java17 copyDirectory block may retain text only inside comments.
s=s.replace('Path url = findJarResource(resource);','JarEntry url = findJarResource(resource);')
s=s.replace('\t\tPath url;','\t\tJarEntry url;')
s=s.replace('InputStream is = Files.newInputStream(url,StandardOpenOption.READ);','InputStream is = jarFile.getInputStream(url);')
s=s.replace('InputStream stream = Files.newInputStream(url,StandardOpenOption.READ);','InputStream stream = jarFile.getInputStream(url);')
old='''\tpublic Path findJarResource(String resource)\n\t{\n\t\tString ju="";\n\t\tif(!resource.startsWith("/"))\n\t\t{\n\t\t\tresource="/"+resource;\n\t\t}\n\t\t\n\t\tPath pathInZipfile = zipfs.getPath(resource);\n\t\t//Path pathInZipfile=Paths.get("./unzip/"+suitename+resource);\n\t\t\n\t\tif(!Files.exists(pathInZipfile))\n\t\t{\n\t\t\treturn null;\n\t\t}\n\t\t\n\t\treturn pathInZipfile;\n\t}\n'''
new='''\tprivate void initJarFile(URL[] urls)\n\t{\n\t\tif(urls == null || urls.length == 0 || urls[0] == null) { return; }\n\t\ttry\n\t\t{\n\t\t\tjarFile = new JarFile(new File(urls[0].toURI()));\n\t\t}\n\t\tcatch(Exception e)\n\t\t{\n\t\t\tSystem.out.println("Can't Open Jar Resource File: " + e.getMessage());\n\t\t}\n\t}\n\n\tpublic JarEntry findJarResource(String resource)\n\t{\n\t\tif(jarFile == null || resource == null) { return null; }\n\t\twhile(resource.startsWith("/")) { resource = resource.substring(1); }\n\t\treturn jarFile.getJarEntry(resource);\n\t}\n'''
if old not in s: raise SystemExit('MIDLETLOADER_FIND_RESOURCE_BLOCK_NOT_FOUND')
s=s.replace(old,new)
# Active NIO must be gone. Ignore the upstream commented copyDirectory example.
active=[]
in_block=False
for line in s.splitlines():
    t=line.strip()
    if '/*' in t: in_block=True
    if not in_block and ('java.nio.file' in line or re.search(r'\b(Path|FileSystem|Files|StandardOpenOption)\b', line)):
        active.append(line)
    if '*/' in t: in_block=False
if active: raise SystemExit('ACTIVE_NIO_REMAINS: '+repr(active[:20]))
p.write_text(s)

# Prior bounded Java5 syntax conversions retained unchanged.
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

# Keep the M1.4A.3 diagnostic boundary so this checkpoint measures only MIDletLoader NIO removal.
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
src/javax/microedition/media/** = AUDIO/MEDIA deferred
PlatformPlayer/SdlMixerManager = AUDIO deferred
src/javax/microedition/rms/** = RMS deferred boundary
MyMethodVisitor = bytecode rewrite syntax boundary deferred
EOF

mkdir -p ../"$OUT"/classes
set +e
javac -version 2>&1 | tee ../"$OUT"/JAVAC-VERSION.txt
javac -source 5 -target 5 -encoding UTF-8 -d ../"$OUT"/classes @../"$OUT"/BOOT-SLICE-SOURCES.txt 2>../"$OUT"/JAVAC-ERRORS.txt
RC=$?
set -e
echo JAVAC_RC=$RC
# Specific M1.4A.4 gate: fail if compiler still reports NIO symbols from MIDletLoader.
if grep -E 'MIDletLoader.java.*(Path|FileSystem|Files|StandardOpenOption)|symbol:[[:space:]]+(class|variable)[[:space:]]+(Path|FileSystem|Files|StandardOpenOption)' ../"$OUT"/JAVAC-ERRORS.txt >/dev/null; then
  echo MIDLETLOADER_NIO_GATE=FAIL
  RC=1
else
  echo MIDLETLOADER_NIO_GATE=PASS
fi
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
  echo M1_4A_4_RESULT=PASS
else
  echo M1_4A_4_RESULT=FAIL_CLOSED
  sed -n '1,320p' ../"$OUT"/JAVAC-ERRORS.txt
fi
exit "$RC"
