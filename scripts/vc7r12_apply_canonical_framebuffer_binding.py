#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: vc7r12_apply_canonical_framebuffer_binding.py <Libretro.java>')

p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s
marker = 'RG35XX-VC7R12-FRAME-BIND:'
if marker in s:
    raise SystemExit('VC7R12 FAIL: patch already applied')

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('VC7R12 FAIL %s count=%d' % (label, n))
    s = s.replace(old, new, 1)

# Import PlatformImage so each transport request can atomically bind to the
# CURRENT LCD frontbuffer object created by MobilePlatform lifecycle/resize.
once('import org.recompile.mobile.MobilePlatform;\n',
     'import org.recompile.mobile.MobilePlatform;\nimport org.recompile.mobile.PlatformImage;\n',
     'PlatformImage import')

# Golden G1 cached lcdData once. VC7R2 can resize before load and MobilePlatform.load()
# can subsequently recreate the frontbuffer without changing logical dimensions.
# Never serialize from that stale int[]. Always acquire object + data together.
old_req = '''\t\t\t\t\t\t\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,\n\t\t\t\t\t\t\t\t\tMobile.getPlatform().getLcdFrontbuffer());\n'''
new_req = '''\t\t\t\t\t\t\t\trg35xxRequestCurrentFrame();\n'''
once(old_req, new_req, 'normal frame request')

old_ctl = '''\t\t\t\t\t\t\t\t\t\trg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, lcdData,\n\t\t\t\t\t\t\t\t\t\t\tMobile.getPlatform().getLcdFrontbuffer());\n'''
new_ctl = '''\t\t\t\t\t\t\t\t\t\trg35xxSendCurrentControlFrame();\n'''
once(old_ctl, new_ctl, 'control frame request')

# Even when VC7R2 logical dimensions are unchanged after load, load() may have
# replaced the PlatformImage. Rebind the legacy lcdData field for all non-transport
# users and diagnostics. This is intentionally outside the resize-only branch.
keep_anchor = '''\t\telse\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: " + phase + " keep " + lcdWidth + "x" + lcdHeight);\n\t\t}\n\t}\n\n'''
keep_new = '''\t\telse\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: " + phase + " keep " + lcdWidth + "x" + lcdHeight);\n\t\t}\n\t\trg35xxRebindCurrentFrontbuffer("view-" + phase);\n\t}\n\n'''
once(keep_anchor, keep_new, 'VC7R2 keep rebind')

helper_anchor = '\tprivate void settingsChanged()\n\t{\n'
if s.count(helper_anchor) != 1:
    raise SystemExit('VC7R12 FAIL settingsChanged anchor count=%d' % s.count(helper_anchor))
helpers = '''\tprivate void rg35xxRebindCurrentFrontbuffer(String phase)\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front == null) return;\n\t\tint[] current = front.getDataBuffer();\n\t\tint oldId = lcdData == null ? 0 : System.identityHashCode(lcdData);\n\t\tint newId = current == null ? 0 : System.identityHashCode(current);\n\t\tlcdData = current;\n\t\tSystem.err.println("RG35XX-VC7R12-FRAME-BIND: REBIND phase=" + phase\n\t\t\t+ " frontId=" + System.identityHashCode(front)\n\t\t\t+ " oldDataId=" + oldId + " newDataId=" + newId\n\t\t\t+ " size=" + lcdWidth + "x" + lcdHeight);\n\t}\n\n\tprivate void rg35xxRequestCurrentFrame()\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front == null) return;\n\t\tint[] current = front.getDataBuffer();\n\t\tlcdData = current;\n\t\tSystem.err.println("RG35XX-VC7R12-FRAME-BIND: REQUEST frontId=" + System.identityHashCode(front)\n\t\t\t+ " dataId=" + System.identityHashCode(current)\n\t\t\t+ " size=" + lcdWidth + "x" + lcdHeight);\n\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, current, front);\n\t}\n\n\tprivate void rg35xxSendCurrentControlFrame()\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front == null) return;\n\t\tint[] current = front.getDataBuffer();\n\t\tlcdData = current;\n\t\tSystem.err.println("RG35XX-VC7R12-FRAME-BIND: CONTROL frontId=" + System.identityHashCode(front)\n\t\t\t+ " dataId=" + System.identityHashCode(current)\n\t\t\t+ " size=" + lcdWidth + "x" + lcdHeight);\n\t\trg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, current, front);\n\t}\n\n'''
s = s.replace(helper_anchor, helpers + helper_anchor, 1)

for required in (
    'RG35XX-VC7R12-FRAME-BIND: REBIND',
    'RG35XX-VC7R12-FRAME-BIND: REQUEST',
    'rg35xxFrames.requestFrame(lcdWidth, lcdHeight, current, front)',
    'rg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, current, front)',
    'rg35xxRebindCurrentFrontbuffer("view-" + phase)',
):
    if required not in s:
        raise SystemExit('VC7R12 FAIL missing token: ' + required)

# No Golden transport call may still combine cached lcdData with a freshly fetched lock.
if 'requestFrame(lcdWidth, lcdHeight, lcdData' in s:
    raise SystemExit('VC7R12 FAIL stale normal-frame transport remains')
if 'sendControlFrame(lcdWidth, lcdHeight, lcdData' in s:
    raise SystemExit('VC7R12 FAIL stale control-frame transport remains')
if s == orig:
    raise SystemExit('VC7R12 FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('VC7R12_CANONICAL_FRAMEBUFFER_BINDING=PASS')
print('POLICY=FETCH_CURRENT_FRONTBUFFER_OBJECT_AND_DATA_TOGETHER_FOR_EVERY_TRANSPORT_REQUEST')
print('VC7R2_SAME_SIZE_AFTER_LOAD_REBIND=ENABLED')
