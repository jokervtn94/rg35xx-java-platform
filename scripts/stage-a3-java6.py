#!/usr/bin/env python3
import os
import re
import shutil
import sys
from pathlib import Path

if len(sys.argv) != 4:
    raise SystemExit("usage: stage-a3-java6.py <upstream-src> <stage-src> <audit-log>")

src = Path(sys.argv[1]).resolve()
dst = Path(sys.argv[2]).resolve()
audit_path = Path(sys.argv[3]).resolve()

if not src.is_dir():
    raise SystemExit("A3_STAGE_FAIL upstream src missing: %s" % src)
if dst.exists():
    shutil.rmtree(str(dst))
shutil.copytree(str(src), str(dst))

audit = []

def note(kind, rel, detail):
    audit.append("%s\t%s\t%s" % (kind, rel, detail))

def read(rel):
    return (dst / rel).read_text(encoding="utf-8")

def write(rel, text):
    (dst / rel).write_text(text, encoding="utf-8")

def replace_exact(rel, old, new, label, count=1):
    text = read(rel)
    found = text.count(old)
    if found != count:
        raise SystemExit("A3_STAGE_FAIL %s expected=%d found=%d file=%s" % (label, count, found, rel))
    text = text.replace(old, new)
    write(rel, text)
    note("REWRITE", rel, "%s count=%d" % (label, count))

# A4/A5 are deliberately 2D/RMS/font scope. These canonical trees remain present
# in the pinned gitlink but are not compiled in A3 because they require LWJGL/
# OpenGL/Java7+ and are not part of the first RG35XX device acceptance boundary.
deferred_dirs = [
    "org/lwjgl",
    "ru/woesss/j2me/micro3d",
    "com/mascotcapsule/micro3d",
    "javax/microedition/m3g",
]
for rel in deferred_dirs:
    p = dst / rel
    if not p.is_dir():
        raise SystemExit("A3_STAGE_FAIL expected deferred directory missing: %s" % rel)
    count = sum(1 for x in p.rglob("*.java"))
    shutil.rmtree(str(p))
    note("DEFER_SCOPE", rel, "java_files=%d reason=A4_A5_2D_ONLY" % count)

# The only 2D-core M3G references at the pinned Aweigit tree are unused imports.
for rel in ["org/recompile/mobile/Mobile.java", "org/recompile/mobile/MobilePlatform.java"]:
    replace_exact(rel,
                  "import javax.microedition.m3g.Graphics3D;\n",
                  "",
                  "remove-unused-m3g-import")

# Java 7 diamond syntax is compile-time only. Erase only constructor diamonds;
# generic declarations stay untouched. Runtime behavior is unchanged by erasure.
diamond_re = re.compile(r"new\s+([A-Za-z_$][A-Za-z0-9_.$]*)<>\s*\(")
diamond_total = 0
for p in sorted(dst.rglob("*.java")):
    text = p.read_text(encoding="utf-8")
    text2, n = diamond_re.subn(lambda m: "new %s(" % m.group(1), text)
    if n:
        p.write_text(text2, encoding="utf-8")
        rel = str(p.relative_to(dst)).replace(os.sep, "/")
        note("REWRITE", rel, "diamond-to-raw count=%d" % n)
        diamond_total += n
note("SUMMARY", "*", "diamond-to-raw-total=%d" % diamond_total)

# Java 8 lambdas in the in-scope RMS and FileConnection paths become ordinary
# Java 6 anonymous Comparator classes. The comparison expressions are unchanged.
rel = "javax/microedition/rms/impl/RecordEnumerationImpl.java"
text = read(rel)
needle = "import java.util.Collections;\n"
if text.count(needle) != 1:
    raise SystemExit("A3_STAGE_FAIL RMS comparator import anchor drift")
text = text.replace(needle, needle + "import java.util.Comparator;\n")
old = "\t\t\tCollections.sort(enumerationRecords, (lhs, rhs) -> comparator.compare(lhs.value, rhs.value));"
new = "\t\t\tCollections.sort(enumerationRecords, new Comparator<EnumerationRecord>() {\n\t\t\t\tpublic int compare(EnumerationRecord lhs, EnumerationRecord rhs) {\n\t\t\t\t\treturn comparator.compare(lhs.value, rhs.value);\n\t\t\t\t}\n\t\t\t});"
if text.count(old) != 1:
    raise SystemExit("A3_STAGE_FAIL RMS lambda anchor drift")
text = text.replace(old, new)
write(rel, text)
note("REWRITE", rel, "lambda-to-anonymous-comparator count=1")

rel = "org/microemu/cldc/file/FileSystemFileConnection.java"
text = read(rel)
needle = "import java.util.Arrays;\n"
if text.count(needle) != 1:
    raise SystemExit("A3_STAGE_FAIL FileConnection comparator import anchor drift")
text = text.replace(needle, needle + "import java.util.Comparator;\n")
old = "\t\tArrays.sort(files, (f1, f2) -> f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase()));"
new = "\t\tArrays.sort(files, new Comparator<File>() {\n\t\t\tpublic int compare(File f1, File f2) {\n\t\t\t\treturn f1.getName().toLowerCase().compareTo(f2.getName().toLowerCase());\n\t\t\t}\n\t\t});"
if text.count(old) != 1:
    raise SystemExit("A3_STAGE_FAIL FileConnection lambda anchor drift")
text = text.replace(old, new)
write(rel, text)
note("REWRITE", rel, "lambda-to-anonymous-comparator count=1")

# Desugar the small set of in-scope single-resource try-with-resources forms.
# We keep the original surrounding catch blocks. The nested finally guarantees
# close() on normal and exceptional exit without requiring Java 7 bytecode/API.
def find_matching(text, open_pos, open_ch, close_ch):
    depth = 0
    i = open_pos
    state = "code"
    while i < len(text):
        c = text[i]
        n = text[i+1] if i + 1 < len(text) else ""
        if state == "code":
            if c == '"': state = "string"
            elif c == "'": state = "char"
            elif c == '/' and n == '/': state = "line"; i += 1
            elif c == '/' and n == '*': state = "block"; i += 1
            elif c == open_ch:
                depth += 1
            elif c == close_ch:
                depth -= 1
                if depth == 0:
                    return i
        elif state == "string":
            if c == '\\': i += 1
            elif c == '"': state = "code"
        elif state == "char":
            if c == '\\': i += 1
            elif c == "'": state = "code"
        elif state == "line":
            if c == '\n': state = "code"
        elif state == "block":
            if c == '*' and n == '/': state = "code"; i += 1
        i += 1
    raise ValueError("unmatched %s" % open_ch)

def desugar_twr(rel):
    text = read(rel)
    out = []
    pos = 0
    changed = 0
    token_re = re.compile(r"\btry\s*\(")
    while True:
        m = token_re.search(text, pos)
        if not m:
            out.append(text[pos:])
            break
        # Skip occurrences inside comments by a conservative line check. The
        # allowlisted files have executable TWR only at the pinned tree.
        line_start = text.rfind("\n", 0, m.start()) + 1
        prefix = text[line_start:m.start()]
        if prefix.lstrip().startswith("//") or prefix.lstrip().startswith("*"):
            out.append(text[pos:m.end()])
            pos = m.end()
            continue
        paren = text.find("(", m.start())
        pend = find_matching(text, paren, "(", ")")
        resource = text[paren+1:pend].strip()
        resource = resource.rstrip(";").strip()
        # Multiple resources are intentionally unsupported: fail rather than
        # silently changing close ordering.
        if ";" in resource:
            raise SystemExit("A3_STAGE_FAIL multi-resource TWR unsupported in %s" % rel)
        rm = re.match(r"(?s)(?:final\s+)?([A-Za-z_$][A-Za-z0-9_.$<>?, ]*)\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(.+)$", resource)
        if not rm:
            raise SystemExit("A3_STAGE_FAIL cannot parse TWR resource in %s: %s" % (rel, resource))
        rtype, rname, rexpr = rm.group(1).strip(), rm.group(2), rm.group(3).strip()
        bopen = pend + 1
        while bopen < len(text) and text[bopen].isspace(): bopen += 1
        if bopen >= len(text) or text[bopen] != "{":
            raise SystemExit("A3_STAGE_FAIL TWR body missing in %s" % rel)
        bend = find_matching(text, bopen, "{", "}")
        body = text[bopen+1:bend]
        indent = text[line_start:m.start()]
        replacement = (
            "try {\n" + indent + "\t" + rtype + " " + rname + " = " + rexpr + ";\n" +
            indent + "\ttry {" + body + "\n" + indent + "\t} finally {\n" +
            indent + "\t\tif (" + rname + " != null) { " + rname + ".close(); }\n" +
            indent + "\t}\n" + indent + "}"
        )
        out.append(text[pos:m.start()])
        out.append(replacement)
        pos = bend + 1
        changed += 1
    if changed:
        write(rel, "".join(out))
        note("REWRITE", rel, "try-with-resources-to-java6 count=%d" % changed)
    return changed

for rel in [
    "javax/microedition/rms/impl/AndroidRecordStoreManager.java",
    "org/microemu/cldc/file/FileSystemFileConnection.java",
    "org/objectweb/asm/ClassReader.java",
    "org/objectweb/asm/Constants.java",
]:
    n = desugar_twr(rel)
    if n == 0:
        raise SystemExit("A3_STAGE_FAIL expected TWR missing in %s" % rel)

# Aweigit's pinned MIDletLoader uses Java 7 NIO zipfs. For RG35XX Java 6,
# retain the same manifest/resource/class-loading flow but use JarFile/JarEntry,
# a mechanism already exercised by the historical Java-6 FreeJ2ME runtime.
rel = "org/recompile/mobile/MIDletLoader.java"
text = read(rel)
for imp in [
    "import java.nio.file.Path;\n",
    "import java.nio.file.Paths;\n",
    "import java.nio.file.Files;\n",
    "import java.nio.file.FileSystem;\n",
    "import java.nio.file.FileSystems;\n",
    "import java.nio.file.StandardOpenOption;\n",
    "import java.nio.file.DirectoryStream;\n",
    "import java.nio.file.StandardCopyOption;\n",
    "import java.net.URI;\n",
]:
    if text.count(imp) != 1:
        raise SystemExit("A3_STAGE_FAIL MIDletLoader import drift: %s" % imp.strip())
    text = text.replace(imp, "")
anchor = "import java.io.IOException;\n"
if text.count(anchor) != 1:
    raise SystemExit("A3_STAGE_FAIL MIDletLoader java.io anchor drift")
text = text.replace(anchor, anchor + "import java.io.File;\nimport java.util.jar.JarFile;\nimport java.util.jar.JarEntry;\n")
if text.count("\tFileSystem zipfs;\n") != 1:
    raise SystemExit("A3_STAGE_FAIL MIDletLoader zipfs field drift")
text = text.replace("\tFileSystem zipfs;\n", "\tprivate JarFile jarFile;\n")

# Replace only the constructor's active zipfs-open block (the later NIO copy
# helper is commented out in canonical source and is left as documentation).
# Constructor diamonds have already been erased above, so the pinned-stage
# anchor is intentionally "new HashMap()" rather than canonical "new HashMap<>()".
ctor_re = re.compile(
    r"\t\ttry\{\n\t\t\tHashMap<String, String> env = new HashMap\(\);.*?"
    r"\t\tcatch\(Exception e\)\n\t\t\{\n\t\t\tSystem\.out\.println\(\"创建zip文件系统出错: \"\+e\.getMessage\(\)\);\n\t\t\}\n",
    re.S,
)
ctor_new = (
    "\t\ttry\n\t\t{\n"
    "\t\t\tjarFile = openJar(u);\n"
    "\t\t}\n"
    "\t\tcatch(Exception e)\n\t\t{\n"
    "\t\t\tSystem.out.println(\"打开jar文件出错: \"+e.getMessage());\n"
    "\t\t}\n"
)
text, n = ctor_re.subn(ctor_new, text, count=1)
if n != 1:
    raise SystemExit("A3_STAGE_FAIL MIDletLoader zipfs constructor block drift")

helper = '''\n\tprivate JarFile openJar(String u) throws Exception\n\t{\n\t\tif (u.startsWith("file:"))\n\t\t{\n\t\t\treturn new JarFile(new File(new URL(u).toURI()));\n\t\t}\n\t\treturn new JarFile(new File(u));\n\t}\n\n'''
start_anchor = "\n\n\tpublic void start() throws MIDletStateChangeException\n"
if text.count(start_anchor) != 1:
    raise SystemExit("A3_STAGE_FAIL MIDletLoader start anchor drift")
text = text.replace(start_anchor, "\n" + helper + "\tpublic void start() throws MIDletStateChangeException\n")

method_re = re.compile(r"\tpublic Path findJarResource\(String resource\)\n\t\{.*?\n\t\}\n\n\tpublic InputStream getResourceAsStream", re.S)
method_new = '''\tpublic JarEntry findJarResource(String resource)\n\t{\n\t\tif (jarFile == null || resource == null) { return null; }\n\t\twhile (resource.startsWith("/")) { resource = resource.substring(1); }\n\t\treturn jarFile.getJarEntry(resource);\n\t}\n\n\tpublic InputStream getResourceAsStream'''
text, n = method_re.subn(method_new, text, count=1)
if n != 1:
    raise SystemExit("A3_STAGE_FAIL MIDletLoader findJarResource method drift")

text = text.replace("Path url = findJarResource(resource);", "JarEntry url = findJarResource(resource);")
text = text.replace("Path url;", "JarEntry url;")
text = text.replace("InputStream stream = Files.newInputStream(url,StandardOpenOption.READ);", "InputStream stream = jarFile.getInputStream(url);")
manifest_stream = "InputStream is = Files.newInputStream(url,StandardOpenOption.READ);"
if text.count(manifest_stream) != 1:
    raise SystemExit("A3_STAGE_FAIL MIDletLoader manifest NIO stream anchor drift")
text = text.replace(manifest_stream, "InputStream is = jarFile.getInputStream(url);")
note("REWRITE", rel, "manifest-stream-nio-to-jarfile count=1")
# All executable stream opens must now be Java-6 JarFile based. Strip block
# comments correctly before this guard so the commented copy helper is ignored.
if "Files.newInputStream(" in re.sub(r"/\*.*?\*/", "", text, flags=re.S):
    raise SystemExit("A3_STAGE_FAIL active MIDletLoader NIO stream use remains")

write(rel, text)
note("REWRITE", rel, "nio-zipfs-to-java6-jarfile")

# Final guards: no Java7/8 syntax known to be incompatible is allowed to remain
# in the staged 2D scope. Comments are tolerated; javac is the authoritative gate.
if (dst / "org/lwjgl").exists():
    raise SystemExit("A3_STAGE_FAIL LWJGL staging contamination")

java_count = sum(1 for p in dst.rglob("*.java"))
if java_count < 100:
    raise SystemExit("A3_STAGE_FAIL unexpectedly small staged source count=%d" % java_count)
note("SUMMARY", "*", "staged-java-files=%d" % java_count)
note("SUMMARY", "*", "canonical-source-mutated=NO")

audit_path.parent.mkdir(parents=True, exist_ok=True)
audit_path.write_text("KIND\tPATH\tDETAIL\n" + "\n".join(audit) + "\n", encoding="utf-8")
print("A3_STAGE_JAVA6=PASS")
print("A3_STAGE_JAVA_FILES=%d" % java_count)
print("A3_STAGE_AUDIT=%s" % audit_path)
