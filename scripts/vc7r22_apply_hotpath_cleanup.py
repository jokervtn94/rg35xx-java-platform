#!/usr/bin/env python3
import pathlib
import sys

if len(sys.argv) != 3:
    raise SystemExit('usage: vc7r22_apply_hotpath_cleanup.py <PlatformGraphics.java> <RG35XXGoldenFrameTransport.java>')

pg = pathlib.Path(sys.argv[1])
ft = pathlib.Path(sys.argv[2])
g = pg.read_text(encoding='utf-8')
f = ft.read_text(encoding='utf-8')


def replace_method_body(text, signature, replacement_body, label):
    """Replace exactly one Java method body without touching adjacent helpers."""
    start = text.find(signature)
    if start < 0:
        raise SystemExit('VC7R22: %s helper not found' % label)
    brace = text.find('{', start + len(signature))
    if brace < 0:
        raise SystemExit('VC7R22: %s opening brace not found' % label)

    depth = 0
    i = brace
    in_string = False
    in_char = False
    escaped = False
    line_comment = False
    block_comment = False
    while i < len(text):
        c = text[i]
        n = text[i + 1] if i + 1 < len(text) else ''

        if line_comment:
            if c == '\n':
                line_comment = False
            i += 1
            continue
        if block_comment:
            if c == '*' and n == '/':
                block_comment = False
                i += 2
                continue
            i += 1
            continue
        if in_string:
            if escaped:
                escaped = False
            elif c == '\\':
                escaped = True
            elif c == '"':
                in_string = False
            i += 1
            continue
        if in_char:
            if escaped:
                escaped = False
            elif c == '\\':
                escaped = True
            elif c == "'":
                in_char = False
            i += 1
            continue

        if c == '/' and n == '/':
            line_comment = True
            i += 2
            continue
        if c == '/' and n == '*':
            block_comment = True
            i += 2
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if c == "'":
            in_char = True
            i += 1
            continue
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                end = i + 1
                return text[:brace] + replacement_body + text[end:]
        i += 1

    raise SystemExit('VC7R22: %s closing brace not found' % label)


# VC7R9 was a diagnostic probe, not runtime behavior. Replace only this method's
# body. Do not slice to drawImage(): later revisions add helpers such as
# vc7r13ProbeFullscreen between these methods and those must remain intact.
g = replace_method_body(
    g,
    '\tprivate void vc7r9ProbeImage(String phase, Image image, int x, int y)',
    '{\n\t\t/* RG35XX-VC7R22-HOTPATH-CLEAN: production no-op. */\n\t}',
    'VC7R9 image probe')

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

# VC7R5 uses StringBuffer + System.err.println(b.toString()). Replace exactly the
# helper body so any methods inserted after it by later revisions are preserved.
p5sig = '    private void vc7r5LogSamples(String phase, int w, int h, int pixels, boolean encoded)'
if p5sig in f:
    f = replace_method_body(
        f,
        p5sig,
        '{\n        /* RG35XX-VC7R22-HOTPATH-CLEAN: production no-op. */\n    }',
        'VC7R5 color sampler')

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
if 'vc7r13ProbeFullscreen(' not in g:
    raise SystemExit('VC7R22: VC7R13 fullscreen helper/call chain was accidentally removed')
if 'RG35XX-VIDEO JAVA worker error' not in f or 'RG35XX-VIDEO JAVA control-frame error' not in f:
    raise SystemExit('VC7R22: required error diagnostics were removed')

pg.write_text(g, encoding='utf-8', newline='\n')
ft.write_text(f, encoding='utf-8', newline='\n')
print('VC7R22_HOTPATH_CLEANUP=PASS')
print('FRAME_JAVA_DIAG_WRITES_REMOVED=%d' % removed)
print('FRAME_JAVA_DIAG_EXECUTABLE_SURVIVORS=0')
print('VC7R9_IMAGE_SAMPLER=NOOP')
print('VC7R5_COLOR_SAMPLER=NOOP_OR_ABSENT')
print('VC7R13_FULLSCREEN_HELPER=PRESERVED')
print('ERROR_DIAGNOSTICS=PRESERVED')
