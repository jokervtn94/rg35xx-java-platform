#!/usr/bin/env python3
"""Restore the CQ/CR-style dynamic logical LCD behavior on the clean runtime.

Scope is deliberately narrow:
- infer an explicit WxH token from the loaded JAR filename (the behavior that
  produced the historical RG35XX-VIEW: filename logical size device logs),
- apply that logical size at LOAD and again immediately before RUN so a stale
  240x320 core option cannot collapse the game's already-known logical LCD,
- leave physical 640x480 fitting to the proven native Smart-Fit path,
- do not alter RGB565 transport, JamVM, GNU Classpath, font raster, media, or
  native lifecycle.

This is a source reconstruction of the tasklog-proven CQ/CR behavior; it is not
claimed byte-identical to historical CQ runtime SHA 45853d... .
"""
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: vc7r2_apply_proven_dynamic_view.py <Libretro.java>")

p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s

marker = "RG35XX-VC7R2-VIEW:"
if marker in s:
    raise SystemExit("VC7R2 VIEW FAIL: patch already present")

# Add Pattern/Matcher imports using an anchor present in the pinned source.
anchor = "import java.net.URLDecoder;\n"
if s.count(anchor) != 1:
    raise SystemExit("VC7R2 VIEW FAIL: URLDecoder import anchor count=%d" % s.count(anchor))
s = s.replace(anchor, anchor + "import java.util.regex.Matcher;\nimport java.util.regex.Pattern;\n", 1)

# Remember the filename-derived logical size independently from core options.
field_anchor = "\tprivate int lcdWidth, lcdHeight;\n\tint[] lcdData;\n"
if s.count(field_anchor) != 1:
    raise SystemExit("VC7R2 VIEW FAIL: LCD field anchor count=%d" % s.count(field_anchor))
s = s.replace(field_anchor, field_anchor +
'''\n\t/* CQ/CR-proven logical view: physical 640x480 remains native-only. */
\tprivate int rg35xxViewWidth = 0;
\tprivate int rg35xxViewHeight = 0;
\tprivate static final Pattern RG35XX_VIEW_SIZE = Pattern.compile("(^|[^0-9])([0-9]{2,3})[xX]([0-9]{2,3})([^0-9]|$)");
''', 1)

# Detect/apply before MobilePlatform.load().
load_anchor = "\t\t\t\t\t\t\t\tpath = new String(buffer, 0, bytesRead);\n\n\t\t\t\t\t\t\t\tif(Mobile.getPlatform().load(getFormattedLocation(URLDecoder.decode(path, Mobile.textEncoding))))\n"
if s.count(load_anchor) != 1:
    raise SystemExit("VC7R2 VIEW FAIL: LOAD anchor count=%d" % s.count(load_anchor))
s = s.replace(load_anchor,
"\t\t\t\t\t\t\t\tpath = new String(buffer, 0, bytesRead);\n" +
"\t\t\t\t\t\t\t\trg35xxCaptureFilenameLogicalSize(path);\n\n" +
"\t\t\t\t\t\t\t\tif(Mobile.getPlatform().load(getFormattedLocation(URLDecoder.decode(path, Mobile.textEncoding))))\n", 1)

# Re-assert immediately after successful load. This is specifically what keeps
# a stale 240x320 frontend option from winning over the filename-derived size.
success_anchor = "\t\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\tif(Mobile.libretroRestartRequested == 1)\n"
if s.count(success_anchor) != 1:
    raise SystemExit("VC7R2 VIEW FAIL: load-success anchor count=%d" % s.count(success_anchor))
s = s.replace(success_anchor,
"\t\t\t\t\t\t\t\t{\n" +
"\t\t\t\t\t\t\t\t\trg35xxReassertFilenameLogicalSize(\"after-load\");\n" +
"\t\t\t\t\t\t\t\t\tif(Mobile.libretroRestartRequested == 1)\n", 1)

# Re-assert immediately before the game starts, covering late settingsChanged()
# callbacks during JAR load without altering global boot architecture.
run_anchor = "\t\t\t\t\t\t\tcase 13: // Run jar\n\t\t\t\t\t\t\t\tMobile.getPlatform().runJar();\n"
if s.count(run_anchor) != 1:
    raise SystemExit("VC7R2 VIEW FAIL: RUN anchor count=%d" % s.count(run_anchor))
s = s.replace(run_anchor,
"\t\t\t\t\t\t\tcase 13: // Run jar\n" +
"\t\t\t\t\t\t\t\trg35xxReassertFilenameLogicalSize(\"before-run\");\n" +
"\t\t\t\t\t\t\t\tMobile.getPlatform().runJar();\n", 1)

# Insert helpers immediately before settingsChanged().
helper_anchor = "\tprivate void settingsChanged()\n\t{\n"
if s.count(helper_anchor) != 1:
    raise SystemExit("VC7R2 VIEW FAIL: settingsChanged anchor count=%d" % s.count(helper_anchor))
helpers = r'''\tprivate void rg35xxCaptureFilenameLogicalSize(String path)
\t{
\t\tif(path == null) return;
\t\tString name = new File(path).getName();
\t\tMatcher m = RG35XX_VIEW_SIZE.matcher(name);
\t\tint foundW = 0;
\t\tint foundH = 0;
\t\twhile(m.find())
\t\t{
\t\t\ttry
\t\t\t{
\t\t\t\tint w = Integer.parseInt(m.group(2));
\t\t\t\tint h = Integer.parseInt(m.group(3));
\t\t\t\t/* Golden native receiver accepts dynamic game frames up to 800x800. */
\t\t\t\tif(w >= 96 && h >= 96 && w <= 800 && h <= 800)
\t\t\t\t{
\t\t\t\t\tfoundW = w;
\t\t\t\t\tfoundH = h;
\t\t\t\t}
\t\t\t}
\t\t\tcatch(NumberFormatException ignored) {}
\t\t}
\t\tif(foundW > 0 && foundH > 0)
\t\t{
\t\t\trg35xxViewWidth = foundW;
\t\t\trg35xxViewHeight = foundH;
\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: filename logical size " + foundW + "x" + foundH + " file=" + name);
\t\t\trg35xxReassertFilenameLogicalSize("filename");
\t\t}
\t\telse
\t\t{
\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: no filename size; keep runtime size " + lcdWidth + "x" + lcdHeight + " file=" + name);
\t\t}
\t}

\tprivate void rg35xxReassertFilenameLogicalSize(String phase)
\t{
\t\tif(rg35xxViewWidth <= 0 || rg35xxViewHeight <= 0) return;
\t\tif(Mobile.config != null)
\t\t{
\t\t\tMobile.config.settings.put("scrwidth", "" + rg35xxViewWidth);
\t\t\tMobile.config.settings.put("scrheight", "" + rg35xxViewHeight);
\t\t}
\t\tMobile.lcdWidth = rg35xxViewWidth;
\t\tMobile.lcdHeight = rg35xxViewHeight;
\t\tif(lcdWidth != rg35xxViewWidth || lcdHeight != rg35xxViewHeight)
\t\t{
\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: " + phase + " resize " + lcdWidth + "x" + lcdHeight + " -> " + rg35xxViewWidth + "x" + rg35xxViewHeight);
\t\t\tlcdWidth = rg35xxViewWidth;
\t\t\tlcdHeight = rg35xxViewHeight;
\t\t\tMobile.getPlatform().resizeLCD(lcdWidth, lcdHeight);
\t\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();
\t\t}
\t\telse
\t\t{
\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: " + phase + " keep " + lcdWidth + "x" + lcdHeight);
\t\t}
\t}

'''
s = s.replace(helper_anchor, helpers + helper_anchor, 1)

# During subsequent core option updates, the historical CQ/CR behavior keeps
# the already established game logical size. Core options may still update all
# other settings normally.
update_anchor = "\t\tMobile.updateSettings();\n\n\t\tframeHeader[5] = (byte) (Mobile.rotateDisplay / 90);\n"
if s.count(update_anchor) != 1:
    raise SystemExit("VC7R2 VIEW FAIL: updateSettings anchor count=%d" % s.count(update_anchor))
s = s.replace(update_anchor,
"\t\tMobile.updateSettings();\n" +
"\t\tif(rg35xxViewWidth > 0 && rg35xxViewHeight > 0)\n" +
"\t\t{\n" +
"\t\t\tSystem.err.println(\"RG35XX-VC7R2-VIEW: settings update keep runtime size \" + rg35xxViewWidth + \"x\" + rg35xxViewHeight);\n" +
"\t\t\tMobile.lcdWidth = rg35xxViewWidth;\n" +
"\t\t\tMobile.lcdHeight = rg35xxViewHeight;\n" +
"\t\t}\n\n" +
"\t\tframeHeader[5] = (byte) (Mobile.rotateDisplay / 90);\n", 1)

if s == orig or marker not in s:
    raise SystemExit("VC7R2 VIEW FAIL: no effective mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("VC7R2 PROVEN DYNAMIC VIEW OVERLAY PASS")
print("SOURCE=" + str(p))
print("CV_CW_BOOT_RESOLUTION=NOT_USED")
print("PHYSICAL_OUTPUT=UNCHANGED_NATIVE_SMART_FIT")
print("HISTORICAL_CQ_BINARY_IDENTITY=NOT_CLAIMED")
