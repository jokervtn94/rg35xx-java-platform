#!/usr/bin/env python3
import re
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_p2b_jdk8_font_metrics.py <jdk.log> <arm.log>")

jdk_re = re.compile(
    r'^P2B_JDK8_FONT_METRIC STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) '
    r'HEIGHT=(-?\d+) ASCENT=(-?\d+) DESCENT=(-?\d+) LEADING=(-?\d+)$')
arm_re = re.compile(
    r'^P2B_FT_JDK8_FONT_METRIC STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) '
    r'HEIGHT=(-?\d+) ASCENT=(-?\d+) DESCENT=(-?\d+) LEADING=(-?\d+)$')


def parse(path, rx):
    out = {}
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for raw in f:
            m = rx.match(raw.strip())
            if not m:
                continue
            vals = tuple(int(x) for x in m.groups())
            key = (vals[0], vals[2])
            if key in out:
                raise SystemExit('duplicate case %r in %s' % (key, path))
            out[key] = vals
    return out

jdk = parse(sys.argv[1], jdk_re)
arm = parse(sys.argv[2], arm_re)
keys = sorted(set(jdk) | set(arm))
expected = 24
if len(jdk) != expected or len(arm) != expected or len(keys) != expected:
    raise SystemExit('P2B_FONT_METRICS_PARSE_FAIL jdk=%d arm=%d union=%d' %
                     (len(jdk), len(arm), len(keys)))

fields = ['NORMALIZED', 'HEIGHT', 'ASCENT', 'DESCENT', 'LEADING']
# Tuple indices: style=0 normalized=1 size=2 height=3 ascent=4 descent=5 leading=6
indices = [1, 3, 4, 5, 6]
exact = dict((name, 0) for name in fields)
mismatches = 0

for key in keys:
    a = jdk.get(key)
    b = arm.get(key)
    if a is None or b is None:
        mismatches += 1
        print('P2B_FONT_METRICS_MISMATCH KEY=%r REASON=MISSING' % (key,))
        continue
    case_bad = False
    for name, idx in zip(fields, indices):
        if a[idx] == b[idx]:
            exact[name] += 1
        else:
            case_bad = True
            print('P2B_FONT_METRICS_FIELD_MISMATCH STYLE=%d SIZE=%d FIELD=%s JDK=%d ARM=%d' %
                  (key[0], key[1], name, a[idx], b[idx]))
    if case_bad:
        mismatches += 1

print('P2B_FONT_METRICS_DIFF_PARSE=PASS')
print('P2B_FONT_METRICS_CASES=%d' % expected)
for name in fields:
    print('P2B_FONT_METRICS_%s_EXACT=%d' % (name, exact[name]))
print('P2B_FONT_METRICS_MISMATCH_COUNT=%d' % mismatches)
if mismatches == 0:
    print('P2B_FONT_METRICS_CLASSIFICATION=EXACT_FOR_ALL_P2B_STYLE_SIZE_CASES')
    print('P2B_FONT_METRICS_DIFF_RESULT=PASS')
else:
    print('P2B_FONT_METRICS_CLASSIFICATION=RESIDUAL_REQUIRES_CLASSIFICATION')
    print('P2B_FONT_METRICS_DIFF_RESULT=FAIL')
    raise SystemExit(1)
print('P2B_RUNTIME_PATCH=FORBIDDEN')
