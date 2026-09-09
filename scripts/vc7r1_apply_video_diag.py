#!/usr/bin/env python3
"""VC7R.1 device diagnostics for RG35XX color and logical LCD sizing.

This overlay is diagnostic-only. It does not alter rendering, pixel format,
resolution selection, JamVM, GNU Classpath, or native video behavior.
"""
import pathlib
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: vc7r1_apply_video_diag.py <Libretro.java> <RG35XXGoldenFrameTransport.java>")

lib = pathlib.Path(sys.argv[1])
transport = pathlib.Path(sys.argv[2])
ls = lib.read_text(encoding="utf-8")
ts = transport.read_text(encoding="utf-8")


def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit("VC7R1 DIAG FAIL: %s marker count=%d" % (label, n))
    return text.replace(old, new, 1)

# Log the exact core option payload that controls size and backlight tint.
old = 'cfgtokens = cfgvars.split("[| x]", 0);'
new = old + '''\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-VC7R1-CFG: raw=" + cfgvars);\n\t\t\t\t\t\t\t\tif(cfgtokens.length > 11)\n\t\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-VC7R1-CFG: requested=" + cfgtokens[1] + "x" + cfgtokens[2] +\n\t\t\t\t\t\t\t\t\t\t" rotate=" + cfgtokens[3] + " backlightToken=" + cfgtokens[11]);\n\t\t\t\t\t\t\t\t}'''
ls = once(ls, old, new, "config token logger")

# Log settings propagation and the only normal resizeLCD transition.
old = '''\tprivate void settingsChanged()\n\t{\n\t\tMobile.updateSettings();'''
new = '''\tprivate void settingsChanged()\n\t{\n\t\tSystem.err.println("RG35XX-VC7R1-SIZE: settingsChanged enter local=" + lcdWidth + "x" + lcdHeight);\n\t\tMobile.updateSettings();\n\t\tSystem.err.println("RG35XX-VC7R1-SIZE: Mobile after update=" + Mobile.lcdWidth + "x" + Mobile.lcdHeight +\n\t\t\t" rotate=" + Mobile.rotateDisplay);'''
ls = once(ls, old, new, "settingsChanged logger")

old = '''\t\tif(lcdWidth != Mobile.lcdWidth || lcdHeight != Mobile.lcdHeight)\n\t\t{\n\t\t\tlcdWidth = Mobile.lcdWidth;\n\t\t\tlcdHeight = Mobile.lcdHeight;\n\t\t\tMobile.getPlatform().resizeLCD(lcdWidth, lcdHeight);\n\t\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n\t\t}'''
new = '''\t\tif(lcdWidth != Mobile.lcdWidth || lcdHeight != Mobile.lcdHeight)\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R1-SIZE: resize " + lcdWidth + "x" + lcdHeight +\n\t\t\t\t" -> " + Mobile.lcdWidth + "x" + Mobile.lcdHeight);\n\t\t\tlcdWidth = Mobile.lcdWidth;\n\t\t\tlcdHeight = Mobile.lcdHeight;\n\t\t\tMobile.getPlatform().resizeLCD(lcdWidth, lcdHeight);\n\t\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n\t\t\tSystem.err.println("RG35XX-VC7R1-SIZE: resize done data=" +\n\t\t\t\t(lcdData == null ? -1 : lcdData.length));\n\t\t}\n\t\telse\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R1-SIZE: resize skipped same-size");\n\t\t}'''
ls = once(ls, old, new, "resize logger")

# Emit canonical RGB565 values from the exact LUT implementation without changing it.
old = '''\t\tinit565Tables();\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: FrameTransport LUT READY");'''
new = '''\t\tinit565Tables();\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: FrameTransport LUT READY");\n\t\tSystem.err.println("RG35XX-VC7R1-COLOR: RGB565 BLACK=" + hex565(0xFF000000) +\n\t\t\t" WHITE=" + hex565(0xFFFFFFFF) +\n\t\t\t" RED=" + hex565(0xFFFF0000) +\n\t\t\t" GREEN=" + hex565(0xFF00FF00) +\n\t\t\t" BLUE=" + hex565(0xFF0000FF));'''
ts = once(ts, old, new, "LUT diagnostic")

old = '''\tprivate int put565(int argb, int dst)\n\t{'''
new = '''\tprivate String hex565(int argb)\n\t{\n\t\tint hi = high[(argb >>> 8) & 0xFFFF] & 0xFF;\n\t\tint lo = low[argb & 0xFFFF] & 0xFF;\n\t\tint v = (hi << 8) | lo;\n\t\tString s = Integer.toHexString(v).toUpperCase();\n\t\twhile(s.length() < 4) s = "0" + s;\n\t\treturn s;\n\t}\n\n\tprivate int put565(int argb, int dst)\n\t{'''
ts = once(ts, old, new, "hex565 helper")

for required in (
    "RG35XX-VC7R1-CFG:",
    "RG35XX-VC7R1-SIZE:",
):
    if required not in ls:
        raise SystemExit("VC7R1 DIAG FAIL: missing " + required)
if "RG35XX-VC7R1-COLOR:" not in ts:
    raise SystemExit("VC7R1 DIAG FAIL: color marker missing")

lib.write_text(ls, encoding="utf-8", newline="\n")
transport.write_text(ts, encoding="utf-8", newline="\n")
print("VC7R1_DIAG_OVERLAY=PASS")
