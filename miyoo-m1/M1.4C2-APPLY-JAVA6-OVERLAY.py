#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else "upstream-miyoo")
if not (root / "src").is_dir():
    raise SystemExit("source tree missing")

changed = []

def rep(rel, old, new, count=1):
    p = root / rel
    s = p.read_text(encoding="utf-8")
    n = s.count(old)
    if n != count:
        raise SystemExit("FAIL_CLOSED replacement count %s expected=%d actual=%d" % (rel, count, n))
    p.write_text(s.replace(old, new), encoding="utf-8")
    if rel not in changed:
        changed.append(rel)

# Java 7 diamond -> explicit Java 6 generic types.
rep("src/javax/microedition/lcdui/event/CommandActionEvent.java", "new ArrayStack<>()", "new ArrayStack<CommandActionEvent>()")
rep("src/javax/microedition/lcdui/event/EventQueue.java", "new LinkedList<>()", "new LinkedList<Event>()")
rep("src/javax/microedition/rms/impl/AndroidRecordStoreManager.java", "new ConcurrentHashMap<>()", "new ConcurrentHashMap<String, Object>()")
rep("src/javax/microedition/rms/impl/RecordEnumerationImpl.java", "new Vector<>()", "new Vector<EnumerationRecord>()")
rep("src/javax/microedition/rms/impl/RecordStoreImpl.java", "new HashMap<>()", "new HashMap<Integer, byte[]>()")
rep("src/javax/microedition/util/LinkedList.java", "new ArrayStack<>()", "new ArrayStack<LinkedEntry<E>>()")
rep("src/org/microemu/cldc/file/FileSystemFileConnection.java", "new Vector<>()", "new Vector<String>()", count=2)
rep("src/org/recompile/mobile/MyMethodVisitor.java", "new ArrayList<>()", "new ArrayList<Label>()")

# RecordEnumeration lambda -> Java 6 anonymous Comparator.
rep("src/javax/microedition/rms/impl/RecordEnumerationImpl.java",
    "import java.util.Collections;\n",
    "import java.util.Collections;\nimport java.util.Comparator;\n")
rep("src/javax/microedition/rms/impl/RecordEnumerationImpl.java",
    "Collections.sort(enumerationRecords, (lhs, rhs) -> comparator.compare(lhs.value, rhs.value));",
    "Collections.sort(enumerationRecords, new Comparator<EnumerationRecord>() {\n\t\t\t\tpublic int compare(EnumerationRecord lhs, EnumerationRecord rhs) {\n\t\t\t\t\treturn comparator.compare(lhs.value, rhs.value);\n\t\t\t\t}\n\t\t\t});")

# FileSystemFileConnection lambda/TWR -> Java 6 equivalents.
rep("src/org/microemu/cldc/file/FileSystemFileConnection.java",
    "import java.util.Arrays;\n",
    "import java.util.Arrays;\nimport java.util.Comparator;\n")
rep("src/org/microemu/cldc/file/FileSystemFileConnection.java",
    "Arrays.sort(files, (f1, f2) -> f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase()));",
    "Arrays.sort(files, new Comparator<File>() {\n\t\t\tpublic int compare(File f1, File f2) {\n\t\t\t\treturn f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase());\n\t\t\t}\n\t\t});")
rep("src/org/microemu/cldc/file/FileSystemFileConnection.java",
    "\t\ttry (RandomAccessFile raf = new RandomAccessFile(file, \"rw\")) {\n\t\t\traf.setLength(byteOffset);\n\t\t}\n",
    "\t\tRandomAccessFile raf = new RandomAccessFile(file, \"rw\");\n\t\ttry {\n\t\t\traf.setLength(byteOffset);\n\t\t} finally {\n\t\t\traf.close();\n\t\t}\n")

# GNU-Classpath-safe directory creation: remove java.nio.file from core2D.
for rel in ["src/org/recompile/freej2me/SDLConfig.java", "src/org/recompile/mobile/PlatformPlayer.java"]:
    rep(rel, "import java.nio.file.Files;\n", "")
    rep(rel, "import java.nio.file.Paths;\n", "")
rep("src/org/recompile/freej2me/SDLConfig.java",
    "Files.createDirectories(Paths.get(configPath));",
    "File configDir = new File(configPath);\n\t\t\tif (!configDir.isDirectory() && !configDir.mkdirs()) { throw new java.io.IOException(\"mkdirs failed: \" + configPath); }")
rep("src/org/recompile/mobile/PlatformPlayer.java",
    "Files.createDirectories(Paths.get(rmsPath));",
    "File rmsDir = new File(rmsPath);\n\t\t\t\t\tif (!rmsDir.isDirectory() && !rmsDir.mkdirs()) { throw new java.io.IOException(\"mkdirs failed: \" + rmsPath); }",
    count=2)

# AndroidRecordStoreManager: preserve close semantics without try-with-resources.
rel = "src/javax/microedition/rms/impl/AndroidRecordStoreManager.java"
rep(rel,
    "\t\ttry (DataInputStream dis = new DataInputStream(new FileInputStream(headerFile))) {\n\t\t\trecordStoreImpl = new RecordStoreImpl(this);\n\t\t\trecordStoreImpl.readHeader(dis);\n\t\t\trecordStoreImpl.setOpen();\n\t\t} catch (FileNotFoundException e) {",
    "\t\tDataInputStream headerDis = null;\n\t\ttry {\n\t\t\theaderDis = new DataInputStream(new FileInputStream(headerFile));\n\t\t\trecordStoreImpl = new RecordStoreImpl(this);\n\t\t\trecordStoreImpl.readHeader(headerDis);\n\t\t\trecordStoreImpl.setOpen();\n\t\t} catch (FileNotFoundException e) {")
rep(rel,
    "\t\t} catch (IOException e) {\n\t\t\tLog.e(TAG, \"openRecordStore: broken header \" + headerFile, e);\n\t\t\trecordStoreImpl = new RecordStoreImpl(this, recordStoreName);\n\t\t\trecordStoreImpl.setOpen();\n\t\t\tsaveToDisk(recordStoreImpl, -1);\n\t\t}\n\n\t\trecordStores.put(recordStoreName, recordStoreImpl);",
    "\t\t} catch (IOException e) {\n\t\t\tLog.e(TAG, \"openRecordStore: broken header \" + headerFile, e);\n\t\t\trecordStoreImpl = new RecordStoreImpl(this, recordStoreName);\n\t\t\trecordStoreImpl.setOpen();\n\t\t\tsaveToDisk(recordStoreImpl, -1);\n\t\t} finally {\n\t\t\tif (headerDis != null) try { headerDis.close(); } catch (IOException ignored) {}\n\t\t}\n\n\t\trecordStores.put(recordStoreName, recordStoreImpl);")
rep(rel,
    "\t\t\t\t\t\ttry (DataInputStream dis = new DataInputStream(new FileInputStream(file))) {\n\t\t\t\t\t\t\trecordStoreImpl.readRecord(dis);\n\t\t\t\t\t\t} catch (IOException e) {",
    "\t\t\t\t\t\tDataInputStream recordDis = null;\n\t\t\t\t\t\ttry {\n\t\t\t\t\t\t\trecordDis = new DataInputStream(new FileInputStream(file));\n\t\t\t\t\t\t\trecordStoreImpl.readRecord(recordDis);\n\t\t\t\t\t\t} catch (IOException e) {")
rep(rel,
    "\t\t\t\t\t\t\t}\n\t\t\t\t\t\t}\n\t\t\t\t\t}\n",
    "\t\t\t\t\t\t\t} finally {\n\t\t\t\t\t\t\t\tif (recordDis != null) try { recordDis.close(); } catch (IOException ignored) {}\n\t\t\t\t\t\t\t}\n\t\t\t\t\t\t}\n\t\t\t\t\t}\n",
    count=1)
rep(rel,
    "\t\ttry (DataInputStream dis = new DataInputStream(openFileInput(recordName))) {\n\t\t\trecordStoreImpl.readRecord(dis);\n\t\t} catch (FileNotFoundException e) {",
    "\t\tDataInputStream dis = null;\n\t\ttry {\n\t\t\tdis = new DataInputStream(openFileInput(recordName));\n\t\t\trecordStoreImpl.readRecord(dis);\n\t\t} catch (FileNotFoundException e) {")
rep(rel,
    "\t\t} catch (IOException e) {\n\t\t\tLog.e(TAG, \"RecordStore.loadFromDisk: ERROR reading \" + recordName, e);\n\t\t}\n\t}\n",
    "\t\t} catch (IOException e) {\n\t\t\tLog.e(TAG, \"RecordStore.loadFromDisk: ERROR reading \" + recordName, e);\n\t\t} finally {\n\t\t\tif (dis != null) try { dis.close(); } catch (IOException ignored) {}\n\t\t}\n\t}\n")
# Output-stream blocks: explicit close in finally.
rep(rel,
    "\t\ttry (DataOutputStream dos = new DataOutputStream(openFileOutput(headerName))) {\n\t\t\trecordStore.writeHeader(dos);\n\t\t} catch (IOException e) {",
    "\t\tDataOutputStream dos = null;\n\t\ttry {\n\t\t\tdos = new DataOutputStream(openFileOutput(headerName));\n\t\t\trecordStore.writeHeader(dos);\n\t\t} catch (IOException e) {",
    count=2)
# Insert finally after the two identical header catch bodies.
old = "\t\t\tthrow new RecordStoreException(e.getMessage());\n\t\t}\n"
new = "\t\t\tthrow new RecordStoreException(e.getMessage());\n\t\t} finally {\n\t\t\tif (dos != null) try { dos.close(); } catch (IOException ignored) {}\n\t\t}\n"
rep(rel, old, new, count=2)
rep(rel,
    "\t\t\ttry (DataOutputStream dos = new DataOutputStream(openFileOutput(recordName))) {\n\t\t\t\trecordStore.writeRecord(dos, recordId);\n\t\t\t} catch (IOException e) {\n\t\t\t\tLog.e(TAG, \"RecordStore.saveToDisk: ERROR writing object to \" + recordName, e);\n\t\t\t\tthrow new RecordStoreException(e.getMessage());\n\t\t\t}\n",
    "\t\t\tDataOutputStream recordDos = null;\n\t\t\ttry {\n\t\t\t\trecordDos = new DataOutputStream(openFileOutput(recordName));\n\t\t\t\trecordStore.writeRecord(recordDos, recordId);\n\t\t\t} catch (IOException e) {\n\t\t\t\tLog.e(TAG, \"RecordStore.saveToDisk: ERROR writing object to \" + recordName, e);\n\t\t\t\tthrow new RecordStoreException(e.getMessage());\n\t\t\t} finally {\n\t\t\t\tif (recordDos != null) try { recordDos.close(); } catch (IOException ignored) {}\n\t\t\t}\n")

# ASM bundled source: remove Java7 TWR without changing bytecode logic.
rep("src/org/objectweb/asm/ClassReader.java",
    "    try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {",
    "    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();\n    try {")
# ByteArrayOutputStream close is a no-op; explicit close preserves TWR lifecycle.
rep("src/org/objectweb/asm/ClassReader.java",
    "      return outputStream.toByteArray();\n    } finally {\n      if (close) {\n        inputStream.close();\n      }\n    }",
    "      return outputStream.toByteArray();\n    } finally {\n      try { outputStream.close(); } catch (IOException ignored) {}\n      if (close) {\n        inputStream.close();\n      }\n    }")
rep("src/org/objectweb/asm/Constants.java",
    "    try (DataInputStream callerClassStream = new DataInputStream(classInputStream); ) {\n      callerClassStream.readInt();\n      minorVersion = callerClassStream.readUnsignedShort();\n    } catch (IOException ioe) {",
    "    DataInputStream callerClassStream = new DataInputStream(classInputStream);\n    try {\n      callerClassStream.readInt();\n      minorVersion = callerClassStream.readUnsignedShort();\n    } catch (IOException ioe) {")
rep("src/org/objectweb/asm/Constants.java",
    "      throw new IllegalStateException(\"I/O error, can't check class version\", ioe);\n    }\n    if (minorVersion != 0xFFFF) {",
    "      throw new IllegalStateException(\"I/O error, can't check class version\", ioe);\n    } finally {\n      try { callerClassStream.close(); } catch (IOException ignored) {}\n    }\n    if (minorVersion != 0xFFFF) {")

# MIDletLoader: replace NIO zip filesystem with Java6 JarFile/JarEntry.
rel = "src/org/recompile/mobile/MIDletLoader.java"
for imp in [
    "import java.nio.file.Path;\n", "import java.nio.file.Paths;\n", "import java.nio.file.Files;\n",
    "import java.nio.file.FileSystem;\n", "import java.nio.file.FileSystems;\n",
    "import java.nio.file.StandardOpenOption;\n", "import java.nio.file.DirectoryStream;\n",
    "import java.nio.file.StandardCopyOption;\n"
]:
    rep(rel, imp, "")
rep(rel, "import java.net.URI;\n", "import java.net.URI;\nimport java.util.jar.JarFile;\nimport java.util.jar.JarEntry;\n")
rep(rel, "\tFileSystem zipfs;", "\tprivate JarFile jarFile;")
start = "\t\ttry{\n\t\t\tHashMap<String, String> env = new HashMap<>(); \n\t\t\tenv.put(\"create\", \"true\");\n\t\t\t// locate file system by using the syntax \n\t\t\t// defined in java.net.JarURLConnection\n\t\t\tURI uri = URI.create(url);\n\t\t\tzipfs = FileSystems.newFileSystem(uri, env);\n\t\t\t\n\t\t\t/* Path pathInZipfile = zipfs.getPath(\"/\");      \n\t\t\t\n\t\t\tPath targetDirectoryPath = Paths.get(\"./unzip/\"+jarname); // 替换为具体的目标目录路径\n\n\t\t\tcopyDirectory(pathInZipfile, targetDirectoryPath); */\n\t\t}\n"
replacement = "\t\ttry{\n\t\t\tString jarPath = u;\n\t\t\tif (jarPath.startsWith(\"file:\")) { jarPath = new URI(jarPath).getPath(); }\n\t\t\tjarFile = new JarFile(jarPath);\n\t\t}\n"
rep(rel, start, replacement)
# Remove the fully commented NIO helper block to ensure forbidden API scan is unambiguous.
comment_start = s = (root/rel).read_text(encoding="utf-8")
a = s.find("\t/* public static void copyDirectory(Path sourceDir, Path targetDir)")
b = s.find("\n\n\n\tpublic void start()", a)
if a < 0 or b < 0:
    raise SystemExit("FAIL_CLOSED MIDletLoader commented NIO helper not found")
s = s[:a] + s[b:]
(root/rel).write_text(s, encoding="utf-8")
if rel not in changed: changed.append(rel)
rep(rel, "\t\tPath url = findJarResource(resource);", "\t\tJarEntry url = findJarResource(resource);")
rep(rel, "InputStream is = Files.newInputStream(url,StandardOpenOption.READ);", "InputStream is = jarFile.getInputStream(url);")
rep(rel,
    "\tpublic Path findJarResource(String resource)\n\t{\n\t\tString ju=\"\";\n\t\tif(!resource.startsWith(\"/\"))\n\t\t{\n\t\t\tresource=\"/\"+resource;\n\t\t}\n\t\t\n\t\tPath pathInZipfile = zipfs.getPath(resource);\n\t\t//Path pathInZipfile=Paths.get(\"./unzip/\"+suitename+resource);\n\t\t\n\t\tif(!Files.exists(pathInZipfile))\n\t\t{\n\t\t\treturn null;\n\t\t}\n\t\t\n\t\treturn pathInZipfile;\n\t}\n",
    "\tpublic JarEntry findJarResource(String resource)\n\t{\n\t\tif (jarFile == null) return null;\n\t\tif (resource.startsWith(\"/\")) resource = resource.substring(1);\n\t\treturn jarFile.getJarEntry(resource);\n\t}\n")
rep(rel, "\t\tPath url;", "\t\tJarEntry url;")
rep(rel, "InputStream stream = Files.newInputStream(url,StandardOpenOption.READ);", "InputStream stream = jarFile.getInputStream(url);")

# Close streams introduced above without changing returned data.
rep(rel,
    "\t\t\twhile (count!=-1)\n\t\t\t{\n\t\t\t\tcount = stream.read(data);\n\t\t\t\tif(count!=-1) { buffer.write(data, 0, count); }\n\t\t\t}\n\t\t\treturn new ByteArrayInputStream(buffer.toByteArray());",
    "\t\t\twhile (count!=-1)\n\t\t\t{\n\t\t\t\tcount = stream.read(data);\n\t\t\t\tif(count!=-1) { buffer.write(data, 0, count); }\n\t\t\t}\n\t\t\tstream.close();\n\t\t\treturn new ByteArrayInputStream(buffer.toByteArray());")

print("M1_4C2_OVERLAY=PASS")
for rel in changed:
    print("CHANGED=" + rel)
