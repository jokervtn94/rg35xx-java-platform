#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-adam7.py <repo-root>')
root = Path(sys.argv[1]).resolve()
path = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'
text = path.read_text(encoding='utf-8')
old = '        if (interlace != 0) throw new IOException("PNG Adam7 unsupported in RG35XX raw2d");\n'
new = ('        if (interlace == 1) return RG35XXAdam7.decode(png);\n'
       '        if (interlace != 0) throw new IOException("PNG interlace method unsupported: " + interlace);\n')
count = text.count(old)
if count != 1:
    raise SystemExit('A6_ADAM7_STAGE_FAIL expected=1 found=%d' % count)
path.write_text(text.replace(old, new, 1), encoding='utf-8')
print('A6_ADAM7_STAGE=PASS')
print('A6_ADAM7_REWRITES=1')
