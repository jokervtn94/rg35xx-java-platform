#!/usr/bin/env python3
import pathlib
import sys

if len(sys.argv) != 3:
    raise SystemExit('usage: vc7r22_apply_hotpath_cleanup.py <PlatformGraphics.java> <RG35XXGoldenFrameTransport.java>')

pg = pathlib.Path(sys.argv[1])
ft = pathlib.Path(sys.argv[2])
g = pg.read_text(encoding='utf-8')
f = ft.read_text(encoding='utf-8')

# VC7R9 was a diagnostic probe, not runtime behavior. Its helper samples up to
# 256 pixels twice per image operation and prints a large StringBuffer to stderr.
# Keep call sites/source markers so the historical assembly chain remains
# compatible, but turn the helper itself into a production no-op.
start = g.find('\tprivate void vc7r9ProbeImage(String phase, Image image, int x, int y)')
end = g.find('\n\tpublic void drawImage(Image image, int x, int y, int anchor)', start)
if start < 0 or end < 0:
    raise SystemExit('VC7R22: VC7R9 image probe helper not found')
replacement = '''\tprivate void vc7r9ProbeImage(String phase, Image image, int x, int y)\n\t{\n\t\t/* RG35XX-VC7R22-HOTPATH-CLEAN: production no-op. */\n\t}\n'''
g = g[:start] + replacement + g[end:]

# Remove executable RG35XX-JAVA-DIAG println statements, including multiline
# concatenations. VC7R19 may already have removed some or all of them, so this
# pass is intentionally idempotent. Comments/string remnants alone are harmless.
lines = f.splitlines(True)
out = []
removed = 0
i = 0
while i < len(lines):
    line = lines[i]
    if 'System.err.println(' in line:
        stmt = line
        j = i
        while ');' not in stmt and j + 1 < len(lines):
            j += 1
            stmt += lines[j]
        if 'RG35XX-JAVA-DIAG:' in stmt:
            removed += 1
            i = j + 1
            continue
    out.append(line)
    i += 1
f = ''.join(out)

# VC7R5 uses StringBuffer + System.err.println(b.toString()), so it bypassed the
# VC7R19 string-prefix gate. Make that sampling helper a no-op as well.
p5s = f.find('    private void vc7r5LogSamples(String phase, int w, int h, int pixels, boolean encoded)')
if p5s >= 0:
    p5e = f.find('\n    private void sendFrameLocked(', p5s)
    if p5e < 0:
        raise SystemExit('VC7R22: VC7R5 helper end not found')
    f = f[:p5s] + '''    private void vc7r5LogSamples(String phase, int w, int h, int pixels, boolean encoded)\n    {\n        /* RG35XX-VC7R22-HOTPATH-CLEAN: production no-op. */\n    }\n''' + f[p5e:]

# Fail closed on executable diagnostics, not historical comments or inert text.
for name, text in [('PlatformGraphics', g), ('FrameTransport', f)]:
    if 'System.err.println(b.toString())' in text:
        raise SystemExit('VC7R22: hidden StringBuffer stderr survived in ' + name)

# Scan any surviving println statement for JAVA-DIAG to catch formatting changes.
scan_lines = f.splitlines(True)
i = 0
while i < len(scan_lines):
    line = scan_lines[i]
    if 'System.err.println(' in line:
        stmt = line
        j = i
        while ');' not in stmt and j + 1 < len(scan_lines):
            j += 1
            stmt += scan_lines[j]
        if 'RG35XX-JAVA-DIAG:' in stmt:
            raise SystemExit('VC7R22: executable JAVA-DIAG survived frame transport cleanup')
        i = j + 1
        continue
    i += 1

if 'RG35XX-VC7R22-HOTPATH-CLEAN' not in g:
    raise SystemExit('VC7R22: graphics cleanup marker missing')
if 'RG35XX-VIDEO JAVA worker error' not in f or 'RG35XX-VIDEO JAVA control-frame error' not in f:
    raise SystemExit('VC7R22: required error diagnostics were removed')

pg.write_text(g, encoding='utf-8', newline='\n')
ft.write_text(f, encoding='utf-8', newline='\n')
print('VC7R22_HOTPATH_CLEANUP=PASS')
print('FRAME_JAVA_DIAG_WRITES_REMOVED=%d' % removed)
print('FRAME_JAVA_DIAG_EXECUTABLE_SURVIVORS=0')
print('VC7R9_IMAGE_SAMPLER=NOOP')
print('VC7R5_COLOR_SAMPLER=NOOP_OR_ABSENT')
print('ERROR_DIAGNOSTICS=PRESERVED')
