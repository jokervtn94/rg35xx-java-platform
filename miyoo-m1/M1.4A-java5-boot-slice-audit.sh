#!/usr/bin/env bash
set -euo pipefail
PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
UPSTREAM=https://github.com/aweigit/freej2me-miyoomini.git
OUT=${1:-m1_4a_audit}
rm -rf "$OUT" upstream-m1.4a
mkdir -p "$OUT"
exec > >(tee "$OUT/M1.4A-AUDIT.txt") 2>&1

echo M1_4A_5_SDLMIXER_BOOT_DECOUPLE_AUDIT
echo SOURCE_PIN=$PIN
echo PRIMARY_VARIABLE=REMOVE_SDLMIXER_BOOT_LIFECYCLE_COUPLING_FROM_NO_AUDIO_M1_SLICE

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

# M1.4A.4 retained: Java5 JarFile resource access in MIDletLoader.
p=Path('src/org/recompile/mobile/MIDletLoader.java'); s=p.read_text()
for imp in ['import java.nio.file.Path;\n','import java.nio.file.Paths;\n','import java.nio.file.Files;\n','import java.nio.file.FileSystem;\n','import java.nio.file.FileSystems;\n','import java.nio.file.StandardOpenOption;\n','import java.nio.file.DirectoryStream;\n','import java.nio.file.StandardCopyOption;\n']:
    s=s.replace(imp,'')
s=s.replace('import java.io.IOException;\n','import java.io.IOException;\nimport java.io.File;\nimport java.util.jar.JarFile;\nimport java.util.jar.JarEntry;\n')
s=s.replace('HashMap<String, String> env = new HashMap<>();','HashMap<String, String> env = new HashMap<String, String>();')
s=s.replace('FileSystem zipfs;','JarFile jarFile;')
s=s.replace('\t\tsuper(urls);\n','\t\tsuper(urls);\n\t\tinitJarFile(urls);\n')
start=s.find('\t\tString url="";'); end=s.find('\n\t\ttry\n\t\t{\n\t\t\tSystem.setProperty("microedition.platform"', start)
if start < 0 or end < 0: raise SystemExit('MIDLETLOADER_ZIPFS_BLOCK_NOT_FOUND')
s=s[:start]+s[end:]
s=s.replace('Path url = findJarResource(resource);','JarEntry url = findJarResource(resource);')
s=s.replace('\t\tPath url;','\t\tJarEntry url;')
s=s.replace('InputStream is = Files.newInputStream(url,StandardOpenOption.READ);','InputStream is = jarFile.getInputStream(url);')
s=s.replace('InputStream stream = Files.newInputStream(url,StandardOpenOption.READ);','InputStream stream = jarFile.getInputStream(url);')
old='''\tpublic Path findJarResource(String resource)\n\t{\n\t\tString ju="";\n\t\tif(!resource.startsWith("/"))\n\t\t{\n\t\t\tresource="/"+resource;\n\t\t}\n\t\t\n\t\tPath pathInZipfile = zipfs.getPath(resource);\n\t\t//Path pathInZipfile=Paths.get("./unzip/"+suitename+resource);\n\t\t\n\t\tif(!Files.exists(pathInZipfile))\n\t\t{\n\t\t\treturn null;\n\t\t}\n\t\t\n\t\treturn pathInZipfile;\n\t}\n'''
new='''\tprivate void initJarFile(URL[] urls)\n\t{\n\t\tif(urls == null || urls.length == 0 || urls[0] == null) { return; }\n\t\ttry { jarFile = new JarFile(new File(urls[0].toURI())); }\n\t\tcatch(Exception e) { System.out.println("Can't Open Jar Resource File: " + e.getMessage()); }\n\t}\n\n\tpublic JarEntry findJarResource(String resource)\n\t{\n\t\tif(jarFile == null || resource == null) { return null; }\n\t\twhile(resource.startsWith("/")) { resource = resource.substring(1); }\n\t\treturn jarFile.getJarEntry(resource);\n\t}\n'''
if old not in s: raise SystemExit('MIDLETLOADER_FIND_RESOURCE_BLOCK_NOT_FOUND')
s=s.replace(old,new); p.write_text(s)

# M1.4A.5 primary delta: no-audio M1 must not compile-link SdlMixerManager.
# Display vibration is explicitly unsupported in this no-audio checkpoint.
p=Path('src/javax/microedition/lcdui/Display.java'); s=p.read_text()
s=s.replace('import org.recompile.mobile.SdlMixerManager;\n','')
old='''\tpublic boolean vibrate(int duration)\n\t{\n\t\tboolean ret = false;\n\t\tif(!isInitHaptic)\n\t\t{\n\t\t\tret = SdlMixerManager.initHaptic();\n\t\t\tisInitHaptic = true;\n\t\t}\n\t\t\t\n\t\tSdlMixerManager.vibrate(duration);\n\t\t//System.out.println("Vibrate:"+duration);\n\t\treturn ret;\n\t}\n'''
if old not in s: raise SystemExit('DISPLAY_VIBRATE_BLOCK_NOT_FOUND')
s=s.replace(old,'\tpublic boolean vibrate(int duration) { return false; }\n'); p.write_text(s)

# MIDlet shutdown hook is omitted because M1 initializes no audio subsystem.
p=Path('src/javax/microedition/midlet/MIDlet.java'); s=p.read_text()
s=s.replace('import org.recompile.mobile.SdlMixerManager;\n','')
s=s.replace('\t\tSdlMixerManager.shutdown();\n\n',''); p.write_text(s)

# Anbu: remove only the direct mixer import/calls and audio native load from this no-audio compile experiment.
p=Path('src/org/recompile/freej2me/Anbu.java'); s=p.read_text()
s=s.replace('import org.recompile.mobile.SdlMixerManager;\n','')
s=s.replace('\t\tSystem.loadLibrary("audio");\n','')
s=re.sub(r'^\s*SdlMixerManager\.[A-Za-z0-9_]+\([^;]*\);\s*$', '', s, flags=re.M)
p.write_text(s)

# Gate source transformation itself: active references must be zero in boot callers.
for path in ['src/javax/microedition/lcdui/Display.java','src/javax/microedition/midlet/MIDlet.java','src/org/recompile/freej2me/Anbu.java']:
    text=Path(path).read_text()
    if 'SdlMixerManager' in text: raise SystemExit('SDLMIXER_REFERENCE_REMAINS: '+path)

# Prior bounded Java5 syntax conversions retained.
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
find src -name '*.java' \
  ! -path 'src/org/lwjgl/*' ! -path 'src/javax/microedition/m3g/*' ! -path 'src/com/mascotcapsule/*' \
  ! -path 'src/ru/woesss/j2me/micro3d/*' ! -path 'src/android/opengl/*' \
  ! -path 'src/javax/microedition/media/*' ! -name 'PlatformPlayer.java' ! -name 'SdlMixerManager.java' \
  ! -path 'src/javax/microedition/rms/*' ! -name 'MyMethodVisitor.java' \
  -print | sort > ../"$OUT"/BOOT-SLICE-SOURCES.txt
cat > ../"$OUT"/EXCLUSIONS.txt <<'EOF'
3D/LWJGL/M3G/Micro3D/android-opengl = deferred
media/PlatformPlayer/SdlMixerManager = deferred; M1 no-audio boot callers decoupled
RMS = deferred boundary
MyMethodVisitor = deferred bytecode-rewrite boundary
EOF

mkdir -p ../"$OUT"/classes
set +e
javac -version 2>&1 | tee ../"$OUT"/JAVAC-VERSION.txt
javac -source 5 -target 5 -encoding UTF-8 -d ../"$OUT"/classes @../"$OUT"/BOOT-SLICE-SOURCES.txt 2>../"$OUT"/JAVAC-ERRORS.txt
RC=$?
set -e
echo JAVAC_RC=$RC
if grep -E 'MIDletLoader.java.*(Path|FileSystem|Files|StandardOpenOption)|symbol:[[:space:]]+(class|variable)[[:space:]]+(Path|FileSystem|Files|StandardOpenOption)' ../"$OUT"/JAVAC-ERRORS.txt >/dev/null; then echo MIDLETLOADER_NIO_GATE=FAIL; RC=1; else echo MIDLETLOADER_NIO_GATE=PASS; fi
if grep -E '(Display|MIDlet|Anbu)\.java.*SdlMixerManager|symbol:[[:space:]]+(class|variable)[[:space:]]+SdlMixerManager' ../"$OUT"/JAVAC-ERRORS.txt >/dev/null; then echo SDLMIXER_BOOT_GATE=FAIL; RC=1; else echo SDLMIXER_BOOT_GATE=PASS; fi
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
  echo M1_4A_5_RESULT=PASS
else
  echo M1_4A_5_RESULT=FAIL_CLOSED
  sed -n '1,320p' ../"$OUT"/JAVAC-ERRORS.txt
fi
exit "$RC"
