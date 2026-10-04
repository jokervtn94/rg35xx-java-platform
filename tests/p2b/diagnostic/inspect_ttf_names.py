#!/usr/bin/env python3
import struct
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit("usage: inspect_ttf_names.py <font.ttf>")
path = Path(sys.argv[1])
data = path.read_bytes()
if len(data) < 12:
    raise SystemExit("P2B_TTF_PARSE_FAIL=short_file")
num_tables = struct.unpack(">H", data[4:6])[0]
name_off = None
name_len = None
for i in range(num_tables):
    p = 12 + i * 16
    tag = data[p:p+4]
    off, length = struct.unpack(">II", data[p+8:p+16])
    if tag == b"name":
        name_off, name_len = off, length
        break
if name_off is None or name_off + name_len > len(data):
    raise SystemExit("P2B_TTF_PARSE_FAIL=name_table_missing")
base = name_off
fmt, count, string_off = struct.unpack(">HHH", data[base:base+6])
want = {0:"COPYRIGHT",1:"FAMILY",2:"SUBFAMILY",4:"FULL_NAME",5:"VERSION",6:"POSTSCRIPT",13:"LICENSE",14:"LICENSE_URL"}
seen = set()
print("P2B_TTF_NAME_TABLE_FORMAT=%d" % fmt)
print("P2B_TTF_NAME_RECORD_COUNT=%d" % count)
for i in range(count):
    p = base + 6 + i * 12
    platform, encoding, language, name_id, length, offset = struct.unpack(">HHHHHH", data[p:p+12])
    if name_id not in want:
        continue
    s0 = base + string_off + offset
    raw = data[s0:s0+length]
    try:
        if platform in (0, 3):
            text = raw.decode("utf-16-be", "replace")
        elif platform == 1 and encoding == 0:
            text = raw.decode("mac_roman", "replace")
        else:
            text = raw.decode("latin-1", "replace")
    except Exception:
        text = repr(raw)
    text = " ".join(text.replace("\x00", " ").split())
    key = (name_id, text)
    if not text or key in seen:
        continue
    seen.add(key)
    print("P2B_TTF_%s=%s" % (want[name_id], text))
print("P2B_TTF_PARSE_RESULT=PASS")
