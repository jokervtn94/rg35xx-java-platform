#!/usr/bin/env python3
"""VC7R.1 diagnostic-only overlay for RG35XX color/config/resize evidence.

This patch intentionally changes no rendering policy, pixel format, logical
resolution defaults, JamVM, GNU Classpath, media startup, or native core.
It only adds stderr diagnostics to the already assembled VC7R Java sources.
"""
import pathlib
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: vc7r1_apply_video_diag.py <Libretro.java> <RG35XXGoldenFrameTransport.java>")

lib = pathlib.Path(sys.argv[1])
transport = pathlib.Path(sys.argv[2])
ls = lib.read_text(encoding="utf-8")
ts = transport.read_text(encoding="utf-8")
lorig = ls
torig = ts


def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit("VC7R1 DIAG FAIL: %s marker count=%d" % (label, n))
    return text.replace(old, new, 1)

# ---------------------------------------------------------------------------
# Core config packet evidence. Capture the packet before it mutates settings.
# This tells us whether the frontend/core is requesting 240x320 and whether
# backlightcolor is actually Green (token 11) on the failing device.
# ---------------------------------------------------------------------------
cfg_old = '\t\t\t\t\t\t\t\tString cfgvars = new String(buffer, 0, bytesRead);\n\t\t\t\t\t\t\t\t/* Tokens: [0]="FJ2ME_LR_OPTS:", [1]=width, [2]=height, [3]=rotate, [4]=phone, [5]=fps, ... */\n\t\t\t\t\t\t\t\tcfgtokens = cfgvars.split("[| x]", 0);'
cfg_new = '\t\t\t\t\t\t\t\tString cfgvars = new String(buffer, 0, bytesRead);\n\t\t\t\t\t\t\t\t/* Tokens: [0]="FJ2ME_LR_OPTS:", [1]=width, [2]=height, [3]=rotate, [4]=phone, [5]=fps, ... */\n\t\t\t\t\t\t\t\tcfgtokens = cfgvars.split("[| x]", 0);\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-VC7R1-CFG: raw=" + cfgvars);\n\t\t\t\t\t\t\t\tif(cfgtokens.length > 11)\n\t\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-VC7R1-CFG: requested=" + cfgtokens[1] + "x" + cfgtokens[2] +\n\t\t\t\t\t\t\t\t\t                   " rotate=" + cfgtokens[3] + " backlightToken=" + cfgtokens[11]);\n\t\t\t\t\t\t\t\t}'
ls = once(ls, cfg_old, cfg_new, "config packet diagnostic")

# ---------------------------------------------------------------------------
# settingsChanged / resize evidence. Preserve the original mutation ordering.
# ---------------------------------------------------------------------------
settings_old = '''\tprivate void settingsChanged()\n\t{\n\t\tMobile.updateSettings();\n\n\t\tframeHeader[5] = (byte) (Mobile.rotateDisplay / 90);\n\n\t\tif(lcdWidth != Mobile.lcdWidth || lcdHeight != Mobile.lcdHeight)\n\t\t{\n\t\t\tlcdWidth = Mobile.lcdWidth;\n\t\t\tlcdHeight = Mobile.lcdHeight;\n\t\t\tMobile.getPlatform().resizeLCD(lcdWidth, lcdHeight);\n\t\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n\t\t}\n\t}'''
settings_new = '''\tprivate void settingsChanged()\n\t{\n\t\tSystem.err.println("RG35XX-VC7R1-SIZE: settingsChanged enter current=" + lcdWidth + "x" + lcdHeight);\n\t\tMobile.updateSettings();\n\t\tSystem.err.println("RG35XX-VC7R1-SIZE: Mobile after update=" + Mobile.lcdWidth + "x" + Mobile.lcdHeight +\n\t\t                   " rotate=" + Mobile.rotateDisplay);\n\n\t\tframeHeader[5] = (byte) (Mobile.rotateDisplay / 90);\n\n\t\tif(lcdWidth != Mobile.lcdWidth || lcdHeight != Mobile.lcdHeight)\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R1-SIZE: resize " + lcdWidth + "x" + lcdHeight + " -> " +\n\t\t\t                   Mobile.lcdWidth + "x" + Mobile.lcdHeight);\n\t\t\tlcdWidth = Mobile.lcdWidth;\n\t\t\tlcdHeight = Mobile.lcdHeight;\n\t\t\tMobile.getPlatform().resizeLCD(lcdWidth, lcdHeight);\n\t\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n\t\t}\n\t\telse\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R1-SIZE: resize skipped same-size " + lcdWidth + "x" + lcdHeight);\n\t\t}\n\t}'''
ls = once(ls, settings_old, settings_new, "settingsChanged diagnostic")

# ---------------------------------------------------------------------------
# RGB565 canonical-value evidence. Important: the transport source uses four
# spaces, not tabs. Do not alter the proven conversion itself; report outputs
# from the same formula so device logs can separate configuration tint from a
# transport/pixel-format failure.
# ---------------------------------------------------------------------------
lut_old = '''        init565Tables();\n        System.err.println("RG35XX-JAVA-DIAG: FrameTransport LUT READY");'''
lut_new = '''        init565Tables();\n        System.err.println("RG35XX-JAVA-DIAG: FrameTransport LUT READY");\n        System.err.println("RG35XX-VC7R1-COLOR: BLACK=" + hex565(0xFF000000) +\n                           " WHITE=" + hex565(0xFFFFFFFF) +\n                           " RED=" + hex565(0xFFFF0000) +\n                           " GREEN=" + hex565(0xFF00FF00) +\n                           " BLUE=" + hex565(0xFF0000FF));'''
ts = once(ts, lut_old, lut_new, "LUT diagnostic")

helper_old = '''    private int put565(int argb, int dst)\n    {'''
helper_new = '''    private static String hex565(int argb)\n    {\n        int value = (((argb >> 16) & 0xF8) << 8) |\n                    (((argb >> 8) & 0xFC) << 3) |\n                    ((argb >> 3) & 0x1F);\n        String s = Integer.toHexString(value & 0xFFFF).toUpperCase();\n        while(s.length() < 4) s = "0" + s;\n        return s;\n    }\n\n    private int put565(int argb, int dst)\n    {'''
ts = once(ts, helper_old, helper_new, "RGB565 helper diagnostic")

for marker in ("RG35XX-VC7R1-CFG:", "RG35XX-VC7R1-SIZE:"):
    if marker not in ls:
        raise SystemExit("VC7R1 DIAG FAIL: missing marker " + marker)
if "RG35XX-VC7R1-COLOR:" not in ts:
    raise SystemExit("VC7R1 DIAG FAIL: missing color marker")
if ls == lorig or ts == torig:
    raise SystemExit("VC7R1 DIAG FAIL: expected both sources to mutate")

lib.write_text(ls, encoding="utf-8", newline="\n")
transport.write_text(ts, encoding="utf-8", newline="\n")
print("VC7R1 DIAG OVERLAY PASS")
print("LIBRETRO=" + str(lib))
print("TRANSPORT=" + str(transport))
print("BEHAVIOR_CHANGE=NO_DIAGNOSTIC_ONLY")
