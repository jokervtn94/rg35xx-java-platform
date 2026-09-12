#!/usr/bin/env python3
import pathlib
import re
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

# The historical frame transport contains per-frame diagnostic writes around
# request/wake/snapshot/encode/IPC. They are useful during bring-up but cause
# synchronous SD stderr traffic in normal gameplay. Remove only JAVA-DIAG
# statements; keep RG35XX-VIDEO error reports and stack traces intact.
#
# Important: VC7R19 already removes several hot-path writes. Therefore this
# cleanup must be idempotent: removed=0 is valid when the input is already clean.
diag = re.compile(r'\n[ \t]*System\.err\.println\("RG35XX-JAVA-DIAG:.*?\);\n', re.S)
f, removed = diag.subn('\n', f)

# VC7R5 uses StringBuffer + System.err.println(b.toString()), so it bypassed the
# VC7R19 string-prefix gate. Make that sampling helper a no-op as well.
p5s = f.find('    private void vc7r5LogSamples(String phase, int w, int h, int pixels, boolean encoded)')
if p5s >= 0:
    p5e = f.find('\n    private void sendFrameLocked(', p5s)
    if p5e < 0:
        raise SystemExit('VC7R22: VC7R5 helper end not found')
    f = f[:p5s] + '''    private void vc7r5LogSamples(String phase, int w, int h, int pixels, boolean encoded)\n    {\n        /* RG35XX-VC7R22-HOTPATH-CLEAN: production no-op. */\n    }\n''' + f[p5e:]

# Fail closed: no hidden generic StringBuffer print is allowed to survive in
# either known graphics/frame diagnostic path. This is the actual cleanliness
# gate; it works whether the preceding revision removed 0 or many lines.
for name, text in [('PlatformGraphics', g), ('FrameTransport', f)]:
    if 'System.err.println(b.toString())' in text:
        raise SystemExit('VC7R22: hidden StringBuffer stderr survived in ' + name)
if 'RG35XX-JAVA-DIAG:' in f:
    raise SystemExit('VC7R22: JAVA-DIAG marker survived frame transport cleanup')
if 'RG35XX-VC7R22-HOTPATH-CLEAN' not in g:
    raise SystemExit('VC7R22: graphics cleanup marker missing')
if 'RG35XX-VIDEO JAVA worker error' not in f or 'RG35XX-VIDEO JAVA control-frame error' not in f:
    raise SystemExit('VC7R22: required error diagnostics were removed')

pg.write_text(g, encoding='utf-8', newline='\n')
ft.write_text(f, encoding='utf-8', newline='\n')
print('VC7R22_HOTPATH_CLEANUP=PASS')
print('FRAME_JAVA_DIAG_WRITES_REMOVED=%d' % removed)
print('FRAME_JAVA_DIAG_INPUT_ALREADY_CLEAN=%s' % ('YES' if removed == 0 else 'NO'))
print('VC7R9_IMAGE_SAMPLER=NOOP')
print('VC7R5_COLOR_SAMPLER=NOOP_OR_ABSENT')
print('ERROR_DIAGNOSTICS=PRESERVED')
