#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a7-rg35xx-audio-loader.py <repo-root>')

root = Path(sys.argv[1]).resolve()
launcher = root / 'adapter/java/org/recompile/rg35xx/RG35XXLauncher.java'
text = launcher.read_text(encoding='utf-8')

anchor = '''        final FramePresenter presenter = new FramePresenter(platform, raw2d);\n'''
insert = '''        try {\n            String nativeDir = System.getProperty("rg35xx.native.dir");\n            if (nativeDir != null && nativeDir.length() > 0) {\n                System.load(new File(nativeDir, "libaudio.so").getAbsolutePath());\n            } else {\n                System.loadLibrary("audio");\n            }\n            System.out.println("RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER");\n        } catch (UnsatisfiedLinkError e) {\n            RG35XXVideo.shutdownDisplay();\n            System.err.println("RG35XX_A7_AUDIO_BRIDGE_LOAD_FAIL=" + e.toString());\n            System.exit(7);\n        }\n\n        final FramePresenter presenter = new FramePresenter(platform, raw2d);\n'''

count = text.count(anchor)
if count != 1:
    raise SystemExit('A7_AUDIO_LOADER_STAGE_FAIL anchor_count=%d' % count)
if 'RG35XX_A7_AUDIO_BRIDGE=' in text or 'libaudio.so' in text:
    raise SystemExit('A7_AUDIO_LOADER_STAGE_FAIL already_staged')

launcher.write_text(text.replace(anchor, insert, 1), encoding='utf-8')
print('A7_AUDIO_LOADER_STAGE=PASS')
print('A7_AUDIO_DEVICE_INIT=LAZY')
print('A7_AUDIO_CANONICAL_MMAPI=UNCHANGED')
print('A7_AUDIO_VIDEO_OWNER=UNCHANGED')
