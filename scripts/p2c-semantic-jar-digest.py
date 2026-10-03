#!/usr/bin/env python3
import hashlib
import struct
import sys
import zipfile

if len(sys.argv) != 2:
    raise SystemExit("usage: p2c-semantic-jar-digest.py <jar>")

h = hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for name in sorted(z.namelist()):
        data = z.read(name)
        encoded = name.encode("utf-8")
        h.update(struct.pack(">I", len(encoded)))
        h.update(encoded)
        h.update(struct.pack(">Q", len(data)))
        h.update(data)
print(h.hexdigest())
