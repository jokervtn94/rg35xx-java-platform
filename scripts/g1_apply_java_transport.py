#!/usr/bin/env python3
"""Materialize the Golden asynchronous RGB565 transport into pinned Libretro.java.

The transform is deliberately fail-closed. It only accepts the exact structural
markers present in pinned FreeJ2ME commit 13ec186903087156c145268f8706eecfaf9f1e50.
"""
import pathlib
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

# The pinned source contains nested synchronized/for blocks inside the old
# try/catch, so brace-based regex is intentionally avoided. Replace between two
# stable comments that bracket exactly the synchronous frame serializer.
start_marker = "\t\t\t\t\t\t\t\t/* Send Frame to Libretro */\n"
end_marker = "\t\t\t\t\t\t\t\t// We are now ready to start monitoring for pauses, the first frame was requested and sent\n"
if s.count(start_marker) != 1:
    raise SystemExit("G1 JAVA OVERLAY FAIL: send marker count=%d" % s.count(start_marker))
if s.count(end_marker) != 1:
    raise SystemExit("G1 JAVA OVERLAY FAIL: end marker count=%d" % s.count(end_marker))
start = s.index(start_marker)
end = s.index(end_marker, start)
replacement = (
    "\t\t\t\t\t\t\t\t/* Golden G1: frame serialization is owned by RG35XX-FrameWorker. */\n"
    "\t\t\t\t\t\t\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,\n"
    "\t\t\t\t\t\t\t\t\tMobile.getPlatform().getLcdFrontbuffer());\n\n"
)
s = s[:start] + replacement + s[end:]

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
