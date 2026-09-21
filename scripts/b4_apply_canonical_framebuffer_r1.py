#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: b4_apply_canonical_framebuffer_r1.py <Libretro.java>')

p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('B4 CANONICAL FRAMEBUFFER R1 FAIL %s count=%d' % (label, n))
    s = s.replace(old, new, 1)

if 'RG35XX-B4-FRAME-BIND' in s:
    raise SystemExit('B4 CANONICAL FRAMEBUFFER R1 FAIL already applied')

once(
    'import org.recompile.mobile.MobilePlatform;\n',
    'import org.recompile.mobile.MobilePlatform;\nimport org.recompile.mobile.PlatformImage;\n',
    'PlatformImage import'
)

once(
    '\tprivate RG35XXGoldenFrameTransport rg35xxFrames;\n\n\tprivate int lcdWidth, lcdHeight;',
    '\tprivate RG35XXGoldenFrameTransport rg35xxFrames;\n'
    '\tprivate int rg35xxB4FrameBindSeq = 0;\n'
    '\tprivate int rg35xxB4FrameBindLastDataId = 0;\n\n'
    '\tprivate int lcdWidth, lcdHeight;',
    'frame bind fields'
)

old_req = '''\t\t\t\t\t\t\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,\n\t\t\t\t\t\t\t\t\tMobile.getPlatform().getLcdFrontbuffer());\n'''
new_req = '''\t\t\t\t\t\t\t\trg35xxB4RequestCurrentFrame();\n'''
once(old_req, new_req, 'normal frame request')

old_ctl = '''\t\t\t\t\t\t\t\t\t\trg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, lcdData,\n\t\t\t\t\t\t\t\t\t\t\tMobile.getPlatform().getLcdFrontbuffer());\n'''
new_ctl = '''\t\t\t\t\t\t\t\t\t\trg35xxB4SendCurrentControlFrame();\n'''
once(old_ctl, new_ctl, 'control frame request')

anchor = '\tprivate static void updatePauseTimer()\n\t{\n'
if s.count(anchor) != 1:
    raise SystemExit('B4 CANONICAL FRAMEBUFFER R1 FAIL helper anchor count=%d' % s.count(anchor))

helpers = '''\tprivate void rg35xxB4FrameBindLog(String stage, PlatformImage front, int[] current, int cachedBefore)\n\t{\n\t\trg35xxB4FrameBindSeq++;\n\t\tint currentId = current == null ? 0 : System.identityHashCode(current);\n\t\tboolean changed = currentId != rg35xxB4FrameBindLastDataId;\n\t\tboolean mismatch = cachedBefore != 0 && cachedBefore != currentId;\n\t\tif(rg35xxB4FrameBindSeq <= 16 || changed || mismatch)\n\t\t{\n\t\t\tSystem.err.println("RG35XX-B4-FRAME-BIND stage=" + stage\n\t\t\t\t+ " seq=" + rg35xxB4FrameBindSeq\n\t\t\t\t+ " frontId=" + (front == null ? 0 : System.identityHashCode(front))\n\t\t\t\t+ " cachedBeforeDataId=" + cachedBefore\n\t\t\t\t+ " currentDataId=" + currentId\n\t\t\t\t+ " previousCurrentDataId=" + rg35xxB4FrameBindLastDataId\n\t\t\t\t+ " changed=" + changed\n\t\t\t\t+ " mismatch=" + mismatch\n\t\t\t\t+ " size=" + lcdWidth + "x" + lcdHeight);\n\t\t}\n\t\trg35xxB4FrameBindLastDataId = currentId;\n\t}\n\n\tprivate void rg35xxB4RequestCurrentFrame()\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front == null) return;\n\t\tint[] current = front.getDataBuffer();\n\t\tint cachedBefore = lcdData == null ? 0 : System.identityHashCode(lcdData);\n\t\trg35xxB4FrameBindLog("REQUEST", front, current, cachedBefore);\n\t\tlcdData = current;\n\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, current, front);\n\t}\n\n\tprivate void rg35xxB4SendCurrentControlFrame()\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front == null) return;\n\t\tint[] current = front.getDataBuffer();\n\t\tint cachedBefore = lcdData == null ? 0 : System.identityHashCode(lcdData);\n\t\trg35xxB4FrameBindLog("CONTROL", front, current, cachedBefore);\n\t\tlcdData = current;\n\t\trg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, current, front);\n\t}\n\n'''

s = s.replace(anchor, helpers + anchor, 1)

for token in (
    'RG35XX-B4-FRAME-BIND stage=',
    'rg35xxB4RequestCurrentFrame();',
    'rg35xxB4SendCurrentControlFrame();',
    'rg35xxFrames.requestFrame(lcdWidth, lcdHeight, current, front);',
    'rg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, current, front);',
    'cachedBeforeDataId=',
    'mismatch='
):
    if token not in s:
        raise SystemExit('B4 CANONICAL FRAMEBUFFER R1 FAIL missing token: ' + token)

if 'requestFrame(lcdWidth, lcdHeight, lcdData' in s:
    raise SystemExit('B4 CANONICAL FRAMEBUFFER R1 FAIL stale requestFrame source remains')
if 'sendControlFrame(lcdWidth, lcdHeight, lcdData' in s:
    raise SystemExit('B4 CANONICAL FRAMEBUFFER R1 FAIL stale control source remains')
if s == orig:
    raise SystemExit('B4 CANONICAL FRAMEBUFFER R1 FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('B4_CANONICAL_FRAMEBUFFER_R1_PATCH=PASS')
print('PRIMARY_VARIABLE=CURRENT_FRONTBUFFER_OBJECT_AND_DATA_BOUND_TOGETHER_AT_TRANSPORT_REQUEST')
print('LOG_POLICY=FIRST_16_OR_IDENTITY_CHANGE_OR_MISMATCH')
print('NATIVE_CORE_CHANGE=NONE')
