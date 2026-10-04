#!/usr/bin/env python3
import csv
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_p2b_jdk8_whole_raster.py reference.tsv arm.tsv")


def read(path):
    with open(path, "r", encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f, delimiter="\t"))
    by_case = {}
    for row in rows:
        key = row["CASE"]
        if key in by_case:
            raise SystemExit("duplicate CASE %s in %s" % (key, path))
        by_case[key] = row
    return by_case

ref = read(sys.argv[1])
arm = read(sys.argv[2])
if set(ref) != set(arm):
    print("P2B_WHOLE_RASTER_PARSE=FAIL")
    print("P2B_WHOLE_RASTER_CASE_SET_MISMATCH=1")
    raise SystemExit(1)

keys = sorted(ref, key=lambda x: int(x))
meta_fields = ["STYLE", "NORMALIZED", "SIZE", "SAMPLE", "DRAW_COMPLEX", "UTF16HEX", "LAYOUT_FLAGS", "RUNS"]
raster_fields = ["INK", "X0", "Y0", "X1", "Y1", "FP"]
meta_exact = 0
field_exact = {k: 0 for k in raster_fields}
raster_all_exact = 0
direct_width_exact = 0
direct_count = 0
complex_count = 0
mismatch_cases = []

for key in keys:
    r = ref[key]
    a = arm[key]
    meta_ok = all(r[f] == a[f] for f in meta_fields)
    if meta_ok:
        meta_exact += 1
    raster_ok = True
    diffs = []
    for f in raster_fields:
        if r[f].lower() == a[f].lower():
            field_exact[f] += 1
        else:
            raster_ok = False
            diffs.append("%s:%s!=%s" % (f, r[f], a[f]))
    if r["DRAW_COMPLEX"] == "0":
        direct_count += 1
        if r["WIDTH"] == a["WIDTH_DERIVED"]:
            direct_width_exact += 1
        else:
            diffs.append("WIDTH_DIRECT:%s!=%s" % (r["WIDTH"], a["WIDTH_DERIVED"]))
            raster_ok = False
    else:
        complex_count += 1
        if a["WIDTH_DERIVED"] != "-1":
            diffs.append("WIDTH_COMPLEX_SENTINEL:%s" % a["WIDTH_DERIVED"])
            raster_ok = False
    if meta_ok and raster_ok:
        raster_all_exact += 1
    else:
        if not meta_ok:
            diffs.append("META")
        mismatch_cases.append("CASE=%s %s" % (key, " ".join(diffs)))

print("P2B_WHOLE_RASTER_PARSE=PASS")
print("P2B_WHOLE_RASTER_CASES=%d" % len(keys))
print("P2B_WHOLE_RASTER_DIRECT_CASES=%d" % direct_count)
print("P2B_WHOLE_RASTER_COMPLEX_CASES=%d" % complex_count)
print("P2B_WHOLE_RASTER_META_EXACT=%d" % meta_exact)
for f in raster_fields:
    print("P2B_WHOLE_RASTER_%s_EXACT=%d" % (f, field_exact[f]))
print("P2B_WHOLE_RASTER_DIRECT_WIDTH_EXACT=%d" % direct_width_exact)
print("P2B_WHOLE_RASTER_COMPLEX_WIDTH_SCOPE=NOT_TESTED")
print("P2B_WHOLE_RASTER_ALL_EXACT=%d" % raster_all_exact)
print("P2B_WHOLE_RASTER_MISMATCH_COUNT=%d" % len(mismatch_cases))
for line in mismatch_cases[:40]:
    print("P2B_WHOLE_RASTER_MISMATCH " + line)

ok = (
    len(keys) == 336 and direct_count == 144 and complex_count == 192 and
    meta_exact == 336 and direct_width_exact == 144 and
    all(field_exact[f] == 336 for f in raster_fields) and
    raster_all_exact == 336 and not mismatch_cases
)
if ok:
    print("P2B_WHOLE_RASTER_CLASSIFICATION=EXACT_FOR_EXISTING_336_DRAWSTRING_RASTER_CORPUS")
    print("P2B_WHOLE_RASTER_DIFF_RESULT=PASS")
else:
    print("P2B_WHOLE_RASTER_CLASSIFICATION=PARTIAL")
    print("P2B_WHOLE_RASTER_DIFF_RESULT=FAIL")
print("P2B_RUNTIME_PATCH=FORBIDDEN")
raise SystemExit(0 if ok else 1)
