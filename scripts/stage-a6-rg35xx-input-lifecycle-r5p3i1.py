#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-input-lifecycle-r5p3i1.py <repo-root>')
root = Path(sys.argv[1]).resolve()
launcher = root / 'adapter/java/org/recompile/rg35xx/RG35XXLauncher.java'
text = launcher.read_text(encoding='utf-8')
old = '''        startParentTraceWatchdog();\n        platform.runJar();\n        input.start();\n'''
new = '''        startParentTraceWatchdog();\n        parentTrace("RG35XX_A6_TRACE_INPUT_START_BEFORE_RUNJAR");\n        input.start();\n        parentTrace("RG35XX_A6_TRACE_RUNJAR_BEGIN");\n        platform.runJar();\n        parentTrace("RG35XX_A6_TRACE_RUNJAR_RETURN");\n'''
if text.count(old) != 1:
    raise SystemExit('A6_R5P3I1_STAGE_FAIL lifecycle anchor count=%d' % text.count(old))
launcher.write_text(text.replace(old, new, 1), encoding='utf-8')
print('A6_R5P3I1_INPUT_LIFECYCLE_STAGE=PASS')
print('A6_R5P3I1_INPUT_ORDER=INPUT_START_BEFORE_RUNJAR')
print('A6_R5P3I1_DISPLAY_READY_DEFER=UNCHANGED')
print('A6_R5P3I1_KEY_MAPPING=UNCHANGED')
