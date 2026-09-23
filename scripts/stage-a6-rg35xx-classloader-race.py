#!/usr/bin/env python3
import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: stage-a6-rg35xx-classloader-race.py <stage-src> <audit-log>")

root = Path(sys.argv[1]).resolve()
audit = Path(sys.argv[2]).resolve()
rel = Path("org/recompile/mobile/MIDletLoader.java")
path = root / rel

if not root.is_dir():
    raise SystemExit("A6_CLASSLOADER_FAIL stage source missing: %s" % root)
if not path.is_file():
    raise SystemExit("A6_CLASSLOADER_FAIL MIDletLoader missing: %s" % path)

text = path.read_text(encoding="utf-8")

# Evidence-driven A6 adapter overlay:
# Aweigit's one-argument loadClass instruments and defineClass-es MIDlet game
# classes directly. On RG35XX, the game thread and Canvas/EventProcessing path
# can request the same obfuscated class concurrently. The pinned implementation
# has neither a loaded-class guard nor serialization around defineClass, which
# can produce LinkageError: duplicate class definition.
#
# Keep all delegation/game instrumentation semantics intact. Only serialize the
# loader entry and return an already-defined class before another defineClass.
old_sig = "\tpublic Class loadClass(String name) throws ClassNotFoundException\n\t{"
new_sig = "\tpublic synchronized Class loadClass(String name) throws ClassNotFoundException\n\t{"
if text.count(old_sig) != 1:
    raise SystemExit("A6_CLASSLOADER_FAIL loadClass signature expected=1 found=%d" % text.count(old_sig))
text = text.replace(old_sig, new_sig, 1)

pat = re.compile(
    r'(\t\tif\(name\.startsWith\("java\.applet\.Applet"\)\)\s*\n'
    r'\t\t\{\s*\n'
    r'\t\t\treturn null;\s*\n'
    r'\t\t\}\s*\n)',
    re.M,
)
m = pat.search(text)
if not m:
    raise SystemExit("A6_CLASSLOADER_FAIL applet guard insertion point missing")
insert = (
    m.group(1)
    + "\n\t\tClass alreadyLoaded = findLoadedClass(name);\n"
    + "\t\tif(alreadyLoaded != null) { return alreadyLoaded; }\n"
)
text = text[:m.start()] + insert + text[m.end():]

if text.count("public synchronized Class loadClass(String name)") != 1:
    raise SystemExit("A6_CLASSLOADER_FAIL synchronized marker count")
if text.count("Class alreadyLoaded = findLoadedClass(name);") != 1:
    raise SystemExit("A6_CLASSLOADER_FAIL findLoadedClass marker count")

path.write_text(text, encoding="utf-8")
with audit.open("a", encoding="utf-8") as f:
    f.write("A6_CLASSLOADER\torg/recompile/mobile/MIDletLoader.java\tsynchronized-loadClass+findLoadedClass-before-game-define\n")

print("A6_CLASSLOADER_STAGE=PASS")
print("A6_CLASSLOADER_REWRITES=2")
