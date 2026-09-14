#!/usr/bin/env python3
from pathlib import Path
import sys

p = Path(sys.argv[1] if len(sys.argv) > 1 else "miyoo-m1/M1.4C2-APPLY-JAVA6-OVERLAY.py")
s = p.read_text(encoding="utf-8")

def one(old, new):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("FAIL_CLOSED harness patch expected=1 actual=%d fragment=%r" % (n, old[:120]))
    s = s.replace(old, new)

# M1.4C.2C: preserve original upstream CRLF/LF bytes inside transformed Java files.
one('s = p.read_text(encoding="utf-8")', 's = p.read_bytes().decode("utf-8")')
one('p.write_text(s.replace(old, new), encoding="utf-8")', 'p.write_bytes(s.replace(old, new).encode("utf-8"))')
one('comment_start = s = (root/rel).read_text(encoding="utf-8")', 'comment_start = s = (root/rel).read_bytes().decode("utf-8")')
one('(root/rel).write_text(s, encoding="utf-8")', '(root/rel).write_bytes(s.encode("utf-8"))')

# Counts proven by M1.4C.2A on exact pinned MIDletLoader source.
one('rep(rel, "\\t\\tPath url = findJarResource(resource);", "\\t\\tJarEntry url = findJarResource(resource);")',
    'rep(rel, "\\t\\tPath url = findJarResource(resource);", "\\t\\tJarEntry url = findJarResource(resource);", count=4)')
one('rep(rel, "InputStream stream = Files.newInputStream(url,StandardOpenOption.READ);", "InputStream stream = jarFile.getInputStream(url);")',
    'rep(rel, "InputStream stream = Files.newInputStream(url,StandardOpenOption.READ);", "InputStream stream = jarFile.getInputStream(url);", count=4)')

# The same ByteArrayInputStream-return copy block occurs in two active methods.
one('return new ByteArrayInputStream(buffer.toByteArray());")',
    'return new ByteArrayInputStream(buffer.toByteArray());", count=2)')

# Two other active resource paths return byte[] / SiemensInputStream and need explicit close.
marker = '\nprint("M1_4C2_OVERLAY=PASS")'
extra = r'''

# Remaining active MIDlet byte-array and Siemens resource branches.
rep(rel,
    "\t\t\treturn buffer.toByteArray();",
    "\t\t\tstream.close();\n\t\t\treturn buffer.toByteArray();")
rep(rel,
    "\t\t\treturn new SiemensInputStream(buffer.toByteArray());",
    "\t\t\tstream.close();\n\t\t\treturn new SiemensInputStream(buffer.toByteArray());")
'''
one(marker, extra + marker)

p.write_text(s, encoding="utf-8")
print("M1_4C2B_HARNESS_PATCH=PASS")
print("M1_4C2C_LINE_ENDING_PRESERVATION=PASS")
print("TARGET=" + str(p))
