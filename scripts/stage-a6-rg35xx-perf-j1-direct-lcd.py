#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-perf-j1-direct-lcd.py <repo-root>')
root = Path(sys.argv[1]).resolve()
p = root / 'adapter/java/org/recompile/rg35xx/RG35XXLauncher.java'
s = p.read_text(encoding='utf-8')

if 'RG35XX_A6_TRACE_INPUT_START_BEFORE_RUNJAR' not in s:
    raise SystemExit('A6_PERF_J1_STAGE_FAIL R5P3I1 lifecycle overlay missing')
if 'java.lang.reflect.Method' not in s or 'rawPixelsMethod.invoke' not in s:
    raise SystemExit('A6_PERF_J1_STAGE_FAIL reflection parent missing')

s = s.replace('import java.lang.reflect.Method;\n', '', 1)
s = s.replace('        private final Method rawPixelsMethod;\n', '', 1)
old_ctor = '''        FramePresenter(MobilePlatform platform, boolean rawMode) {\n            this.platform = platform;\n            this.rawMode = rawMode;\n            Method method = null;\n            if (rawMode) {\n                try {\n                    method = platform.getClass().getMethod("getRG35XXLCDPixels", new Class[0]);\n                } catch (Exception e) {\n                    throw new IllegalStateException("RG35XX_A4_RAW2D_METHOD_MISSING", e);\n                }\n            }\n            rawPixelsMethod = method;\n        }\n'''
new_ctor = '''        FramePresenter(MobilePlatform platform, boolean rawMode) {\n            this.platform = platform;\n            this.rawMode = rawMode;\n        }\n'''
if s.count(old_ctor) != 1:
    raise SystemExit('A6_PERF_J1_STAGE_FAIL presenter ctor anchor count=%d' % s.count(old_ctor))
s = s.replace(old_ctor, new_ctor, 1)
old_call = '                    int[] raw = (int[]) rawPixelsMethod.invoke(platform, new Object[0]);\n'
new_call = '                    int[] raw = platform.getRG35XXLCDPixels();\n'
if s.count(old_call) != 1:
    raise SystemExit('A6_PERF_J1_STAGE_FAIL reflection call anchor count=%d' % s.count(old_call))
s = s.replace(old_call, new_call, 1)

if 'java.lang.reflect.Method' in s or 'rawPixelsMethod' in s or '.invoke(platform' in s:
    raise SystemExit('A6_PERF_J1_STAGE_FAIL reflection residue')
if 'platform.getRG35XXLCDPixels()' not in s:
    raise SystemExit('A6_PERF_J1_STAGE_FAIL direct accessor missing')

p.write_text(s, encoding='utf-8')
print('A6_PERF_J1_STAGE=PASS')
print('A6_PERF_J1_OWNER=RG35XX_FRAMEPRESENTER_REFLECTION_PER_FRAME')
print('A6_PERF_J1_ACCESS=DIRECT_MOBILEPLATFORM_GETRG35XXLCDPIXELS')
print('A6_PERF_J1_NATIVE_VIDEO=P3_DEVICE_PROVEN')
