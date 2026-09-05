#!/usr/bin/env python3
"""Materialize the Golden asynchronous RGB565 transport into pinned Libretro.java.

The transform is deliberately fail-closed. It only accepts the exact structural
markers present in pinned FreeJ2ME commit 13ec186903087156c145268f8706eecfaf9f1e50.
"""
import pathlib
import re
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: g1_apply_java_transport.py <src/org/recompile/freej2me/Libretro.java>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("G1 JAVA OVERLAY FAIL: %s marker count=%d" % (label, n))
    s = s.replace(old, new, 1)

once(
    "import java.io.File;\nimport java.net.URLDecoder;",
    "import java.io.File;\nimport java.io.OutputStream;\nimport java.io.PrintStream;\nimport java.net.URLDecoder;",
    "imports")

once(
    "public class Libretro\n{\n\tprivate int lcdWidth, lcdHeight;",
    "public class Libretro\n{\n\tprivate static PrintStream ipcOut;\n\tprivate RG35XXGoldenFrameTransport rg35xxFrames;\n\n\tprivate int lcdWidth, lcdHeight;",
    "fields")

once(
    "\tpublic static void main(String args[])\n\t{\n\t\tMobile.clearOldLog();",
    "\tpublic static void main(String args[])\n\t{\n"
    "\t\t/* stdout is the binary/video protocol. Preserve the original stream and\n"
    "\t\t * prevent application/debug prints from corrupting frame transactions. */\n"
    "\t\tipcOut = System.out;\n"
    "\t\tSystem.setOut(new PrintStream(new OutputStream()\n"
    "\t\t{\n"
    "\t\t\tpublic void write(int b) {}\n"
    "\t\t\tpublic void write(byte[] b, int off, int len) {}\n"
    "\t\t}));\n"
    "\t\tMobile.clearOldLog();",
    "main stdout owner")

once(
    "\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n\n\t\t// The painter here is only really used to check for frontend pauses",
    "\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n"
    "\t\trg35xxFrames = new RG35XXGoldenFrameTransport(ipcOut);\n\n"
    "\t\t// The painter here is only really used to check for frontend pauses",
    "transport init")

once(
    "\t\tSystem.out.println(\"+READY\");\n\t\tSystem.out.flush();",
    "\t\tipcOut.println(\"+READY\");\n\t\tipcOut.flush();",
    "ready stream")

# Replace the synchronous frame serialization inside command 15. Keep all input,
# repeat, fast-forward and config behavior before the Send Frame marker intact.
pat = re.compile(
    r"(?P<indent>\t+)\/\* Send Frame to Libretro \*\/\s*"
    r"try\s*\{.*?\}\s*catch\(Exception e\)\s*\{.*?\}",
    re.S,
)
matches = list(pat.finditer(s))
if len(matches) != 1:
    raise SystemExit("G1 JAVA OVERLAY FAIL: synchronous frame block count=%d" % len(matches))
indent = matches[0].group("indent")
replacement = (
    indent + "/* Golden G1: do not serialize the frame on the command parser thread. */\n" +
    indent + "rg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,\n" +
    indent + "\tMobile.getPlatform().getLcdFrontbuffer());"
)
s = s[:matches[0].start()] + replacement + s[matches[0].end():]

# Pinned-source safety checks.
for forbidden in (
    "System.out.write(frameHeader",
    "System.out.write(frameBuffer",
    "System.out.flush();",
):
    if forbidden in s:
        raise SystemExit("G1 JAVA OVERLAY FAIL: synchronous stdout frame path remains: " + forbidden)

for required in (
    "RG35XXGoldenFrameTransport",
    "rg35xxFrames.requestFrame",
    "ipcOut.println(\"+READY\")",
    "new OutputStream()",
):
    if required not in s:
        raise SystemExit("G1 JAVA OVERLAY FAIL: required token missing: " + required)

if s == orig:
    raise SystemExit("G1 JAVA OVERLAY FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("G1 JAVA OVERLAY PASS:", p)
