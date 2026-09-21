#!/usr/bin/env python3
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: b4_apply_hotpath_r2_cleanup.py <RG35XXGoldenFrameTransport.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

hot_markers = [
    'RG35XX-JAVA-DIAG: requestFrame ENTER',
    'RG35XX-JAVA-DIAG: requestFrame REJECTED',
    'RG35XX-JAVA-DIAG: requestFrame SIGNALED',
    'RG35XX-JAVA-DIAG: sendControlFrame ENTER',
    'RG35XX-JAVA-DIAG: sendControlFrame REJECTED',
    'RG35XX-JAVA-DIAG: FrameWorker WAKE',
    'RG35XX-JAVA-DIAG: sendFrame START pixels=',
    'RG35XX-JAVA-DIAG: snapshot LOCK waiting',
    'RG35XX-JAVA-DIAG: snapshot COPIED',
    'RG35XX-JAVA-DIAG: RGB565 ENCODED bytes=',
    'RG35XX-JAVA-DIAG: IPC WRITE header',
    'RG35XX-JAVA-DIAG: IPC WRITE payload',
    'RG35XX-JAVA-DIAG: IPC FLUSH PASS error='
]

bounded_markers = [
    'RG35XX-JAVA-DIAG: FrameTransport constructor ENTER',
    'RG35XX-JAVA-DIAG: FrameTransport LUT READY',
    'RG35XX-JAVA-DIAG: FrameWorker STARTED daemon=',
    'RG35XX-JAVA-DIAG: FrameTransport shutdown',
    'RG35XX-JAVA-DIAG: FrameWorker ENTER',
    'RG35XX-JAVA-DIAG: FrameWorker STOP running=false',
    'RG35XX-JAVA-DIAG: FrameWorker EXIT'
]

required_errors = [
    'RG35XX-VIDEO JAVA control-frame error:',
    'RG35XX-VIDEO JAVA worker error:',
    'RG35XX-VIDEO JAVA invalid snapshot pixels='
]

# Fail closed: this checkpoint is written against the exact B4 transport shape.
for marker in hot_markers + bounded_markers + required_errors:
    n = s.count(marker)
    if n != 1:
        raise SystemExit('B4 HOTPATH R2 FAIL marker count=%d: %s' % (n, marker))

lines = s.splitlines(True)
out = []
removed = {m: 0 for m in hot_markers}
i = 0

while i < len(lines):
    line = lines[i]
    if 'System.err.println(' not in line:
        out.append(line)
        i += 1
        continue

    stmt = line
    j = i
    while ');' not in stmt:
        j += 1
        if j >= len(lines):
            raise SystemExit('B4 HOTPATH R2 FAIL unterminated println at line %d' % (i + 1))
        stmt += lines[j]

    matched = None
    for marker in hot_markers:
        if marker in stmt:
            if matched is not None:
                raise SystemExit('B4 HOTPATH R2 FAIL multiple markers in one println')
            matched = marker

    if matched is not None:
        removed[matched] += 1
        i = j + 1
        continue

    out.extend(lines[i:j + 1])
    i = j + 1

s = ''.join(out)

for marker, count in removed.items():
    if count != 1:
        raise SystemExit('B4 HOTPATH R2 FAIL removed count=%d: %s' % (count, marker))
    if marker in s:
        raise SystemExit('B4 HOTPATH R2 FAIL hot marker survived: ' + marker)

for marker in bounded_markers + required_errors:
    if marker not in s:
        raise SystemExit('B4 HOTPATH R2 FAIL required bounded/error marker lost: ' + marker)

class_anchor = 'public final class RG35XXGoldenFrameTransport\n{\n'
if s.count(class_anchor) != 1:
    raise SystemExit('B4 HOTPATH R2 FAIL class anchor count=%d' % s.count(class_anchor))
s = s.replace(
    class_anchor,
    class_anchor + '    // RG35XX-B4-HOTPATH-R2-CLEAN: unbounded per-frame stderr removed; lifecycle/errors preserved.\n',
    1
)

if 'RG35XX-B4-HOTPATH-R2-CLEAN' not in s:
    raise SystemExit('B4 HOTPATH R2 FAIL cleanup marker missing')
if s == orig:
    raise SystemExit('B4 HOTPATH R2 FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('B4_HOTPATH_R2_PATCH=PASS')
print('PRIMARY_VARIABLE=UNBOUNDED_FRAME_TRANSPORT_DIAGNOSTICS_ONLY')
print('HOT_PRINTS_REMOVED=%d' % sum(removed.values()))
print('BOUNDED_LIFECYCLE_DIAGNOSTICS_PRESERVED=%d' % len(bounded_markers))
print('ERROR_DIAGNOSTICS=PRESERVED')
print('AUDIO_CHANGE=NONE')
print('CORE_CHANGE=NONE')
