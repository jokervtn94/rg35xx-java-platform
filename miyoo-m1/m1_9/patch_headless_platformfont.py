#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformFont.java')
s = p.read_text()
needle = '''\t\t// Check the custom font path and use the custom font if enabled\n'''
insert = '''\t\t// RG35XX M1.9A: device evidence proves java.awt.Font initializes\n\t\t// GtkToolkit and fails because libgtkpeer.so is absent. Keep this\n\t\t// experiment opt-in and avoid host AWT font/toolkit construction only.\n\t\tif (Boolean.getBoolean("rg35xx.headless.font"))\n\t\t{\n\t\t\tint point = getPointSize();\n\t\t\theight = point + 2;\n\t\t\tascent = point;\n\t\t\tdescent = 2;\n\t\t\tawtFont = null;\n\t\t\tmetrics = null;\n\t\t\treturn;\n\t\t}\n\n'''
if s.count(needle) != 1:
    raise SystemExit('M1_9A_PATCH=FAIL_CONSTRUCTOR_ANCHOR')
s = s.replace(needle, insert + needle, 1)
old = '''\t\treturn metrics.stringWidth(str); '''
new = '''\t\tif (metrics == null) { return (str.length() * (getPointSize() + 1)) / 2; }\n\t\treturn metrics.stringWidth(str); '''
if s.count(old) != 1:
    raise SystemExit('M1_9A_PATCH=FAIL_WIDTH_ANCHOR')
s = s.replace(old, new, 1)
p.write_text(s)
print('M1_9A_HEADLESS_PLATFORMFONT_PATCH=PASS')
