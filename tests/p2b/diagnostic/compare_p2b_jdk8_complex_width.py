#!/usr/bin/env python3
import csv
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_p2b_jdk8_complex_width.py jdk-whole-raster.tsv arm-width.tsv")


def read_rows(path):
    with open(path, "r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))

ref_all = read_rows(sys.argv[1])
arm_all = read_rows(sys.argv[2])
ref = {r["CASE"]: r for r in ref_all if r["DRAW_COMPLEX"] == "1"}
arm = {r["CASE"]: r for r in arm_all}

if set(ref) != set(arm):
    print("P2B_COMPLEX_WIDTH_PARSE=FAIL")
    print("P2B_COMPLEX_WIDTH_CASE_SET_MISMATCH=1")
    raise SystemExit(1)

meta_fields = ["STYLE", "NORMALIZED", "SIZE", "SAMPLE"]
meta_exact = 0
width_exact = 0
mismatches = []
rtl_cases = 0
for key in sorted(ref, key=lambda x: int(x)):
    r = ref[key]
    a = arm[key]
    meta_ok = all(r[f] == a[f] for f in meta_fields)
    width_ok = r["WIDTH"] == a["WIDTH_DERIVED"]
    if meta_ok:
        meta_exact += 1
    if width_ok:
        width_exact += 1
    if int(r["LAYOUT_FLAGS"]) & 1:
        rtl_cases += 1
    if not (meta_ok and width_ok):
        diffs = []
        if not meta_ok:
            diffs.append("META")
        if not width_ok:
            diffs.append("WIDTH:%s!=%s" % (r["WIDTH"], a["WIDTH_DERIVED"]))
        mismatches.append("CASE=%s %s" % (key, " ".join(diffs)))

print("P2B_COMPLEX_WIDTH_PARSE=PASS")
print("P2B_COMPLEX_WIDTH_CASES=%d" % len(ref))
print("P2B_COMPLEX_WIDTH_RTL_CASES=%d" % rtl_cases)
print("P2B_COMPLEX_WIDTH_META_EXACT=%d" % meta_exact)
print("P2B_COMPLEX_WIDTH_WIDTH_EXACT=%d" % width_exact)
print("P2B_COMPLEX_WIDTH_MISMATCH_COUNT=%d" % len(mismatches))
for line in mismatches[:40]:
    print("P2B_COMPLEX_WIDTH_MISMATCH " + line)

ok = len(ref) == 192 and rtl_cases == 72 and meta_exact == 192 and width_exact == 192 and not mismatches
if ok:
    print("P2B_COMPLEX_WIDTH_CLASSIFICATION=EXACT_FOR_EXISTING_192_COMPLEX_STRINGWIDTH_CORPUS")
    print("P2B_COMPLEX_WIDTH_DIFF_RESULT=PASS")
else:
    print("P2B_COMPLEX_WIDTH_CLASSIFICATION=PARTIAL")
    print("P2B_COMPLEX_WIDTH_DIFF_RESULT=FAIL")
print("P2B_RUNTIME_PATCH=FORBIDDEN")
raise SystemExit(0 if ok else 1)
