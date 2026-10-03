#!/usr/bin/env python3
import collections
import csv
import math
import sys

if len(sys.argv) != 3:
    raise SystemExit('usage: <jdk-table.tsv> <hb-table.tsv>')


def jround26(v):
    # Java Math.round(v / 64.0) for an integer 26.6 value.
    if v >= 0:
        return (v + 32) // 64
    return -(((-v) + 31) // 64)


def load_tsv(path):
    with open(path, encoding='utf-8', errors='strict', newline='') as f:
        return list(csv.DictReader(f, delimiter='\t'))


jrows = load_tsv(sys.argv[1])
hrows = load_tsv(sys.argv[2])

j = {}
for r in jrows:
    key = (int(r['CP'], 16), int(r['SIZE']))
    j[key] = {
        'display': int(r['DISPLAY']),
        'char_width': int(r['CHAR_WIDTH']),
        'sum': int(r['SUM_CHAR_WIDTH']),
        'sw': int(r['STRING_WIDTH']),
        'cw': int(r['CHARS_WIDTH']),
        'direct_glyphs': int(r['DIRECT_GLYPHS']),
        'layout_glyphs': int(r['LAYOUT_GLYPHS']),
        'direct_adv64': int(r['DIRECT_ADV64']),
        'layout_adv64': int(r['LAYOUT_ADV64']),
    }

h = {}
for r in hrows:
    key = (int(r['CP'], 16), int(r['SIZE']))
    add26 = int(r['ADDITIVE_ADV26'])
    h[key] = {
        'full_adv26': int(r['FULL_ADV26']),
        'full_width': int(r['FULL_WIDTH_ROUND']),
        'add_adv26': add26,
        'add_width': jround26(add26),
        'delta26': int(r['DELTA26']),
        'delta_round': int(r['DELTA_ROUND']),
        'glyphs': int(r['FULL_GLYPHS']),
        'notdef': int(r['FULL_NOTDEF']),
        'offsets': int(r['FULL_OFFSETS']),
        'dir': r['DIR'],
    }

keys = sorted(set(j) | set(h))
missing_j = [k for k in keys if k not in j]
missing_h = [k for k in keys if k not in h]

print('P2B_HB_COMPLEX_DIFF_PARSE=PASS')
print('P2B_HB_COMPLEX_JDK_CASES=%d' % len(j))
print('P2B_HB_COMPLEX_ARM_CASES=%d' % len(h))
print('P2B_HB_COMPLEX_KEY_UNION=%d' % len(keys))
print('P2B_HB_COMPLEX_MISSING_JDK=%d' % len(missing_j))
print('P2B_HB_COMPLEX_MISSING_ARM=%d' % len(missing_h))

string_exact = chars_exact = sum_exact = layout_adv_exact = layout_glyph_exact = 0
all_width_exact = all_semantic_exact = 0
string_err_total = chars_err_total = sum_err_total = adv_err_total = 0
string_err_max = chars_err_max = sum_err_max = adv_err_max = 0
jdk_width_diff = hb_nonadditive = 0
mismatch = []
by_size = collections.Counter()
by_class = collections.Counter()

for key in sorted(set(j) & set(h)):
    cp, size = key
    a = j[key]
    b = h[key]
    se = abs(a['sw'] - b['full_width'])
    ce = abs(a['cw'] - b['full_width'])
    ae = abs(a['sum'] - b['add_width'])
    le = abs(a['layout_adv64'] - b['full_adv26'])
    sg = (a['layout_glyphs'] == b['glyphs'])

    string_err_total += se; string_err_max = max(string_err_max, se)
    chars_err_total += ce; chars_err_max = max(chars_err_max, ce)
    sum_err_total += ae; sum_err_max = max(sum_err_max, ae)
    adv_err_total += le; adv_err_max = max(adv_err_max, le)

    if se == 0: string_exact += 1
    if ce == 0: chars_exact += 1
    if ae == 0: sum_exact += 1
    if le == 0: layout_adv_exact += 1
    if sg: layout_glyph_exact += 1
    if a['sw'] != a['sum'] or a['cw'] != a['sum']: jdk_width_diff += 1
    if b['full_adv26'] != b['add_adv26']: hb_nonadditive += 1

    width_ok = (se == 0 and ce == 0 and ae == 0)
    semantic_ok = (width_ok and le == 0 and sg)
    if width_ok: all_width_exact += 1
    if semantic_ok: all_semantic_exact += 1
    else:
        if not width_ok:
            klass = 'WIDTH_MISMATCH'
        elif le != 0 and not sg:
            klass = 'LAYOUT_ADV_AND_GLYPHCOUNT_MISMATCH'
        elif le != 0:
            klass = 'LAYOUT_ADV_MISMATCH'
        else:
            klass = 'LAYOUT_GLYPHCOUNT_MISMATCH'
        by_class[klass] += 1
        by_size[size] += 1
        mismatch.append((cp, size, klass, a, b, se, ce, ae, le))

print('P2B_HB_COMPLEX_STRING_WIDTH_EXACT=%d' % string_exact)
print('P2B_HB_COMPLEX_CHARS_WIDTH_EXACT=%d' % chars_exact)
print('P2B_HB_COMPLEX_ADDITIVE_WIDTH_EXACT=%d' % sum_exact)
print('P2B_HB_COMPLEX_LAYOUT_ADV64_EXACT=%d' % layout_adv_exact)
print('P2B_HB_COMPLEX_LAYOUT_GLYPHCOUNT_EXACT=%d' % layout_glyph_exact)
print('P2B_HB_COMPLEX_ALL_WIDTH_FIELDS_EXACT=%d' % all_width_exact)
print('P2B_HB_COMPLEX_ALL_SEMANTIC_FIELDS_EXACT=%d' % all_semantic_exact)
print('P2B_HB_COMPLEX_STRING_WIDTH_ERROR_TOTAL=%d' % string_err_total)
print('P2B_HB_COMPLEX_STRING_WIDTH_ERROR_MAX=%d' % string_err_max)
print('P2B_HB_COMPLEX_CHARS_WIDTH_ERROR_TOTAL=%d' % chars_err_total)
print('P2B_HB_COMPLEX_CHARS_WIDTH_ERROR_MAX=%d' % chars_err_max)
print('P2B_HB_COMPLEX_ADDITIVE_WIDTH_ERROR_TOTAL=%d' % sum_err_total)
print('P2B_HB_COMPLEX_ADDITIVE_WIDTH_ERROR_MAX=%d' % sum_err_max)
print('P2B_HB_COMPLEX_LAYOUT_ADV64_ERROR_TOTAL=%d' % adv_err_total)
print('P2B_HB_COMPLEX_LAYOUT_ADV64_ERROR_MAX=%d' % adv_err_max)
print('P2B_JDK_COMPLEX_NONADDITIVE_WIDTH_CASES=%d' % jdk_width_diff)
print('P2B_HB_COMPLEX_NONADDITIVE_ADVANCE_CASES=%d' % hb_nonadditive)
print('P2B_HB_COMPLEX_MISMATCH_COUNT=%d' % len(mismatch))
for k in sorted(by_class):
    print('P2B_HB_COMPLEX_MISMATCH_BY_CLASS CLASS=%s COUNT=%d' % (k, by_class[k]))
for k in sorted(by_size):
    print('P2B_HB_COMPLEX_MISMATCH_BY_SIZE SIZE=%d COUNT=%d' % (k, by_size[k]))

# Keep per-case output bounded to mismatches; this is audit evidence, not runtime trace.
for cp, size, klass, a, b, se, ce, ae, le in mismatch:
    print('P2B_HB_COMPLEX_MISMATCH CP=U+%04X SIZE=%d CLASS=%s DISPLAY=%d JDK_CHAR=%d JDK_SUM=%d HB_ADD=%d JDK_STRING=%d JDK_CHARS=%d HB_FULL=%d STRING_ERR=%d CHARS_ERR=%d ADD_ERR=%d JDK_LAYOUT_GLYPHS=%d HB_GLYPHS=%d JDK_LAYOUT_ADV64=%d HB_ADV26=%d ADV64_ERR=%d HB_NOTDEF=%d HB_OFFSETS=%d HB_DIR=%s' % (
        cp, size, klass, a['display'], a['char_width'], a['sum'], b['add_width'],
        a['sw'], a['cw'], b['full_width'], se, ce, ae,
        a['layout_glyphs'], b['glyphs'], a['layout_adv64'], b['full_adv26'], le,
        b['notdef'], b['offsets'], b['dir']))

complete = (len(j) == len(h) and len(j) > 0 and not missing_j and not missing_h)
if complete and all_semantic_exact == len(j):
    print('P2B_HARFBUZZ_COMPLEX_CLASSIFICATION=EXACT_FOR_EXHAUSTIVE_JDK8_TRIGGER_TABLE')
elif complete and all_width_exact == len(j):
    print('P2B_HARFBUZZ_COMPLEX_CLASSIFICATION=WIDTH_EXACT_LAYOUT_NOT_EXACT')
else:
    print('P2B_HARFBUZZ_COMPLEX_CLASSIFICATION=NOT_EXACT_FOR_EXHAUSTIVE_JDK8_TRIGGER_TABLE')
print('P2B_HB_COMPLEX_DIFF_RESULT=PASS')
print('P2B_RUNTIME_PATCH=FORBIDDEN')
