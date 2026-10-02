#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
matrix = root / 'docs' / 'RG35XX-PLATFORM-SOURCE-COVERAGE-MATRIX-v1.tsv'
if not matrix.is_file():
    raise SystemExit('P1A_COVERAGE_GATE_FAIL=matrix_missing')

with matrix.open('r', encoding='utf-8', newline='') as f:
    rows = list(csv.DictReader(f, delimiter='\t'))

by_key = {(r['AREA'], r['CLASS_OR_METHOD']): r for r in rows}

accepted = [
    ('Graphics', 'clearRect'),
    ('Graphics', 'copyArea'),
    ('Graphics', 'drawArc'),
    ('Graphics', 'drawRoundRect'),
    ('Graphics', 'fillArc'),
    ('Graphics', 'fillRoundRect'),
    ('Graphics', 'fillTriangle(6arg MIDP)'),
    ('DirectGraphics', 'drawImage(...,manipulation)'),
    ('DirectGraphics', 'drawPixels(byte[])'),
    ('DirectGraphics', 'drawPixels(int[])'),
    ('DirectGraphics', 'drawPixels(short[])'),
    ('DirectGraphics', 'drawPolygon'),
    ('DirectGraphics', 'drawTriangle(7arg)'),
    ('DirectGraphics', 'fillPolygon'),
    ('DirectGraphics', 'fillTriangle(7arg color)'),
    ('DirectGraphics', 'getPixels(int[])'),
    ('DirectGraphics', 'getPixels(short[])'),
]

for key in accepted:
    r = by_key.get(key)
    if r is None:
        raise SystemExit('P1A_COVERAGE_GATE_FAIL=missing_row:' + repr(key))
    if r['CLASSIFICATION'] != 'RG35XX_RAW_BACKING_HOST_ACCEPTED':
        raise SystemExit('P1A_COVERAGE_GATE_FAIL=not_host_accepted:%s:%s' % (key[0], key[1]))
    if 'MODULE DEVICE PENDING' not in r['PHYSICAL_EVIDENCE']:
        raise SystemExit('P1A_COVERAGE_GATE_FAIL=device_state_not_pending:%s:%s' % (key[0], key[1]))

stub = by_key.get(('DirectGraphics', 'getPixels(byte[])'))
if stub is None or stub['CLASSIFICATION'] != 'CANONICAL_LIMITATION':
    raise SystemExit('P1A_COVERAGE_GATE_FAIL=byte_getpixels_not_canonical_stub')
if 'STUB CASE PASS' not in stub['PHYSICAL_EVIDENCE']:
    raise SystemExit('P1A_COVERAGE_GATE_FAIL=byte_getpixels_stub_evidence_missing')

internal_expected = {
    ('Graphics', 'drawImage2(BufferedImage,...)'): 'CANONICAL_AWT_INTERNAL_NOT_RAW_API',
    ('Graphics', 'drawImage2Test(BufferedImage,...)'): 'UNUSED_CANONICAL_AWT_DIAGNOSTIC_HELPER',
    ('Graphics', 'setAlphaRGB'): 'CANONICAL_AWT_INTERNAL_DEFERRED_3D_CALLER',
}
for key, cls in internal_expected.items():
    r = by_key.get(key)
    if r is None or r['CLASSIFICATION'] != cls:
        raise SystemExit('P1A_COVERAGE_GATE_FAIL=internal_classification:%s:%s' % (key[0], key[1]))

# P1A is not allowed to hide a remaining graphics gap behind a prose note.
for r in rows:
    if r['AREA'] in ('Graphics', 'DirectGraphics') and r['CLASSIFICATION'].startswith('MISSING'):
        raise SystemExit('P1A_COVERAGE_GATE_FAIL=unclassified_graphics_gap:' + r['CLASS_OR_METHOD'])

# Keep adjacent modules explicitly separate from P1A promotion.
font = by_key.get(('Font', 'metrics/glyph rendering'))
image_decode = by_key.get(('Image', 'resource/InputStream/byte[] decode'))
if font is None or font['NEXT_ACTION'] != 'P1C_FONT_TEXT_MODULE':
    raise SystemExit('P1A_COVERAGE_GATE_FAIL=p1c_scope_not_preserved')
if image_decode is None or image_decode['NEXT_ACTION'] != 'P1B_IMAGE_FORMAT_MODULE':
    raise SystemExit('P1A_COVERAGE_GATE_FAIL=p1b_scope_not_preserved')

print('P1A_COVERAGE_HOST_ACCEPTED_COUNT=%d' % len(accepted))
print('P1A_COVERAGE_BYTE_GETPIXELS_STUB=CANONICAL_LIMITATION')
print('P1A_COVERAGE_G6_INTERNAL_CLASSIFIED=PASS')
print('P1A_COVERAGE_P1B_P1C_SCOPE_PRESERVED=PASS')
print('P1A_GRAPHICS_COVERAGE_MATRIX_GATE=PASS')
