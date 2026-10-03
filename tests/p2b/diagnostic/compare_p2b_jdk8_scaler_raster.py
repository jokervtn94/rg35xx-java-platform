#!/usr/bin/env python3
import collections
import re
import sys

if len(sys.argv) != 3:
    raise SystemExit('usage: <jdk-raster.log> <arm-jdk8-scaler.log>')

jdk_re = re.compile(
    r'^P2B_JDK_RASTER_FP STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) SAMPLE=(\d+) '
    r'WIDTH=(\d+) INK=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+) FP=([0-9a-f]+)$')
arm_re = re.compile(
    r'^P2B_FT_RASTER_FP VARIANT=JDK8SCALER STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) SAMPLE=(\d+) '
    r'WIDTH=(\d+) INK=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+) FP=([0-9a-f]+)$')

def norm_fp(value):
    return value.lstrip('0') or '0'

def parse(path, regex):
    out = {}
    with open(path, encoding='utf-8', errors='replace') as fh:
        for raw in fh:
            m = regex.match(raw.strip())
            if not m:
                continue
            style, normalized, size, sample, width, ink, x0, y0, x1, y1, fp = m.groups()
            key = (int(style), int(size), int(sample))
            out[key] = {
                'normalized': int(normalized),
                'width': int(width),
                'ink': int(ink),
                'bounds': (int(x0), int(y0), int(x1), int(y1)),
                'fp': norm_fp(fp),
            }
    return out

jdk = parse(sys.argv[1], jdk_re)
arm = parse(sys.argv[2], arm_re)
keys = sorted(set(jdk) | set(arm))
missing_jdk = [k for k in keys if k not in jdk]
missing_arm = [k for k in keys if k not in arm]

print('P2B_JDK8_FT_SCALER_DIFF_PARSE=PASS')
print('P2B_JDK8_FT_SCALER_JDK_CASES=%d' % len(jdk))
print('P2B_JDK8_FT_SCALER_ARM_CASES=%d' % len(arm))
print('P2B_JDK8_FT_SCALER_MISSING_JDK=%d' % len(missing_jdk))
print('P2B_JDK8_FT_SCALER_MISSING_ARM=%d' % len(missing_arm))

width_exact = 0
bounds_exact = 0
ink_exact = 0
fp_exact = 0
normalized_exact = 0
ink_abs_error = 0
mismatches = []

for key in sorted(set(jdk) & set(arm)):
    j = jdk[key]
    a = arm[key]
    normalized_exact += int(j['normalized'] == a['normalized'])
    width_exact += int(j['width'] == a['width'])
    bounds_exact += int(j['bounds'] == a['bounds'])
    ink_exact += int(j['ink'] == a['ink'])
    fp_exact += int(j['fp'] == a['fp'])
    ink_abs_error += abs(j['ink'] - a['ink'])
    if j != a:
        fields = []
        if j['normalized'] != a['normalized']:
            fields.append('NORMALIZED_STYLE')
        if j['width'] != a['width']:
            fields.append('WIDTH')
        if j['bounds'] != a['bounds']:
            fields.append('BOUNDS')
        if j['ink'] != a['ink']:
            fields.append('INK')
        if j['fp'] != a['fp']:
            fields.append('PIXELS')
        mismatches.append((key, j, a, '+'.join(fields)))

cases = len(set(jdk) & set(arm))
print('P2B_JDK8_FT_SCALER_CASES=%d' % cases)
print('P2B_JDK8_FT_SCALER_NORMALIZED_STYLE_EXACT=%d' % normalized_exact)
print('P2B_JDK8_FT_SCALER_WIDTH_EXACT=%d' % width_exact)
print('P2B_JDK8_FT_SCALER_BOUNDS_EXACT=%d' % bounds_exact)
print('P2B_JDK8_FT_SCALER_INK_EXACT=%d' % ink_exact)
print('P2B_JDK8_FT_SCALER_FP_EXACT=%d' % fp_exact)
print('P2B_JDK8_FT_SCALER_INK_ABS_ERROR_TOTAL=%d' % ink_abs_error)
print('P2B_JDK8_FT_SCALER_MISMATCH_COUNT=%d' % len(mismatches))

by_style = collections.Counter()
by_normalized = collections.Counter()
by_size = collections.Counter()
by_sample = collections.Counter()
by_fields = collections.Counter()
for (style, size, sample), j, a, fields in mismatches:
    by_style[style] += 1
    by_normalized[j['normalized']] += 1
    by_size[size] += 1
    by_sample[sample] += 1
    by_fields[fields] += 1

for value in sorted(by_style):
    print('P2B_JDK8_FT_SCALER_MISMATCH_BY_STYLE STYLE=%d COUNT=%d' % (value, by_style[value]))
for value in sorted(by_normalized):
    print('P2B_JDK8_FT_SCALER_MISMATCH_BY_NORMALIZED_STYLE NORMALIZED=%d COUNT=%d' % (value, by_normalized[value]))
for value in sorted(by_size):
    print('P2B_JDK8_FT_SCALER_MISMATCH_BY_SIZE SIZE=%d COUNT=%d' % (value, by_size[value]))
for value in sorted(by_sample):
    print('P2B_JDK8_FT_SCALER_MISMATCH_BY_SAMPLE SAMPLE=%d COUNT=%d' % (value, by_sample[value]))
for value in sorted(by_fields):
    print('P2B_JDK8_FT_SCALER_MISMATCH_BY_FIELDS FIELDS=%s COUNT=%d' % (value, by_fields[value]))

print('P2B_JDK8_FT_SCALER_MISMATCH_DETAIL=BEGIN')
for (style, size, sample), j, a, fields in mismatches:
    print(
        'P2B_JDK8_FT_SCALER_MISMATCH STYLE=%d NORMALIZED=%d SIZE=%d SAMPLE=%d '
        'FIELDS=%s JDK_WIDTH=%d ARM_WIDTH=%d JDK_INK=%d ARM_INK=%d INK_DELTA=%+d '
        'JDK_BOUNDS=%d,%d,%d,%d ARM_BOUNDS=%d,%d,%d,%d JDK_FP=%s ARM_FP=%s' % (
            style, j['normalized'], size, sample, fields,
            j['width'], a['width'], j['ink'], a['ink'], a['ink'] - j['ink'],
            j['bounds'][0], j['bounds'][1], j['bounds'][2], j['bounds'][3],
            a['bounds'][0], a['bounds'][1], a['bounds'][2], a['bounds'][3],
            j['fp'], a['fp']))
print('P2B_JDK8_FT_SCALER_MISMATCH_DETAIL=PASS')

if missing_jdk or missing_arm:
    classification = 'INCOMPLETE_TABLE'
elif width_exact == cases and bounds_exact == cases and fp_exact == cases:
    classification = 'EXACT_FOR_SAMPLED_TABLE'
elif width_exact == cases and bounds_exact == cases:
    classification = 'LAYOUT_PLACEMENT_EXACT_RASTER_RESIDUAL'
else:
    classification = 'LAYOUT_OR_PLACEMENT_DIVERGENCE'

print('P2B_JDK8_FT_SCALER_CLASSIFICATION=%s' % classification)
print('P2B_JDK8_FT_SCALER_DIFF_RESULT=PASS')
print('P2B_RUNTIME_PATCH=FORBIDDEN')
