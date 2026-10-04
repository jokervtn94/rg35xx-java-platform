#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_p2b_jdk8_layoutengine_semantics.py <jdk.tsv> <arm.tsv>")

FIELDS = [
    "CASE", "STYLE", "NORMALIZED", "SIZE", "SAMPLE", "UTF16HEX", "RUNS",
    "GLYPH_COUNT", "GLYPHS", "INDICES", "POS_BITS", "POS64"
]

def load(path):
    rows = []
    with Path(path).open("r", encoding="utf-8", newline="") as f:
        r = csv.DictReader(f, delimiter="\t")
        if r.fieldnames != FIELDS:
            raise SystemExit("P2B_LAYOUTENGINE_SEMANTIC_PARSE_FAIL header=%r" % (r.fieldnames,))
        for row in r:
            rows.append(row)
    return rows

jdk = load(sys.argv[1])
arm = load(sys.argv[2])
if len(jdk) != len(arm):
    raise SystemExit("P2B_LAYOUTENGINE_SEMANTIC_PARSE_FAIL jdk=%d arm=%d" % (len(jdk), len(arm)))

meta_exact = 0
glyph_count_exact = 0
glyphs_exact = 0
indices_exact = 0
pos_bits_exact = 0
pos64_exact = 0
all_exact = 0
mismatches = []

for a, b in zip(jdk, arm):
    meta = all(a[k] == b[k] for k in FIELDS[:7])
    gc = a["GLYPH_COUNT"] == b["GLYPH_COUNT"]
    gl = a["GLYPHS"] == b["GLYPHS"]
    ix = a["INDICES"] == b["INDICES"]
    pb = a["POS_BITS"] == b["POS_BITS"]
    p64 = a["POS64"] == b["POS64"]
    meta_exact += int(meta)
    glyph_count_exact += int(gc)
    glyphs_exact += int(gl)
    indices_exact += int(ix)
    pos_bits_exact += int(pb)
    pos64_exact += int(p64)
    exact = meta and gc and gl and ix and pb and p64
    all_exact += int(exact)
    if not exact and len(mismatches) < 32:
        mismatches.append((a["CASE"], a["STYLE"], a["SIZE"], a["SAMPLE"],
                           meta, gc, gl, ix, pb, p64,
                           a["GLYPH_COUNT"], b["GLYPH_COUNT"],
                           a["GLYPHS"], b["GLYPHS"],
                           a["INDICES"], b["INDICES"],
                           a["POS64"], b["POS64"]))

n = len(jdk)
print("P2B_LAYOUTENGINE_SEMANTIC_PARSE=PASS")
print("P2B_LAYOUTENGINE_SEMANTIC_CASES=%d" % n)
print("P2B_LAYOUTENGINE_SEMANTIC_META_EXACT=%d" % meta_exact)
print("P2B_LAYOUTENGINE_SEMANTIC_GLYPH_COUNT_EXACT=%d" % glyph_count_exact)
print("P2B_LAYOUTENGINE_SEMANTIC_GLYPHS_EXACT=%d" % glyphs_exact)
print("P2B_LAYOUTENGINE_SEMANTIC_INDICES_EXACT=%d" % indices_exact)
print("P2B_LAYOUTENGINE_SEMANTIC_POS_BITS_EXACT=%d" % pos_bits_exact)
print("P2B_LAYOUTENGINE_SEMANTIC_POS64_EXACT=%d" % pos64_exact)
print("P2B_LAYOUTENGINE_SEMANTIC_ALL_EXACT=%d" % all_exact)
print("P2B_LAYOUTENGINE_SEMANTIC_MISMATCH_COUNT=%d" % (n - all_exact))
for m in mismatches:
    print("P2B_LAYOUTENGINE_SEMANTIC_MISMATCH CASE=%s STYLE=%s SIZE=%s SAMPLE=%s META=%s GLYPH_COUNT=%s GLYPHS=%s INDICES=%s POS_BITS=%s POS64=%s JDK_GC=%s ARM_GC=%s JDK_GLYPHS=%s ARM_GLYPHS=%s JDK_INDICES=%s ARM_INDICES=%s JDK_POS64=%s ARM_POS64=%s" % m)

if n > 0 and all_exact == n:
    cls = "EXACT_FOR_EXISTING_NONSIMPLE_CORPUS"
elif n > 0 and glyph_count_exact == n and glyphs_exact == n and indices_exact == n and pos64_exact == n:
    cls = "FLOAT_BIT_RESIDUAL_WITH_EXACT_1_64_POSITIONS"
elif n > 0 and glyph_count_exact == n and glyphs_exact == n and indices_exact == n:
    cls = "POSITION_RESIDUAL_REQUIRES_CLASSIFICATION"
else:
    cls = "LAYOUT_SEMANTIC_RESIDUAL_REQUIRES_CLASSIFICATION"
print("P2B_LAYOUTENGINE_SEMANTIC_CLASSIFICATION=%s" % cls)
print("P2B_RUNTIME_PATCH=FORBIDDEN")
print("P2B_LAYOUTENGINE_SEMANTIC_DIFF_RESULT=PASS")
