#!/bin/sh
set -eu

: "${RG35XX_CLASSPATH_ROOT:?set RG35XX_CLASSPATH_ROOT to disposable GNU Classpath 0.99 source}"
: "${RG35XX_FONT_FILE:?set RG35XX_FONT_FILE to materialized DejaVuSans.ttf}"

fail() { echo "RC1 FONT OVERLAY: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 FONT OVERLAY: $*"; }

HT="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/peer/headless/HeadlessToolkit.java"
FONT_DST="$RG35XX_CLASSPATH_ROOT/resource/rg35xx/DejaVuSans.ttf"
[ -f "$HT" ] || fail "missing HeadlessToolkit.java"
[ -s "$RG35XX_FONT_FILE" ] || fail "missing DejaVuSans.ttf"

# The concrete code rewrite is source-shape guarded.  We refuse to edit an unknown Classpath tree.
grep -q 'return null;' "$HT" || fail "expected null-returning headless baseline not found"
grep -q 'getFontPeer' "$HT" || fail "getFontPeer entry missing"
grep -q 'getClasspathFontPeer' "$HT" || fail "getClasspathFontPeer entry missing"

mkdir -p "$(dirname "$FONT_DST")"
cp "$RG35XX_FONT_FILE" "$FONT_DST"

python3 - "$HT" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1])
s=p.read_text()
# Imports required by the existing Classpath peer API.
anchor='package gnu.java.awt.peer.headless;\n'
imports='''package gnu.java.awt.peer.headless;\n\nimport gnu.java.awt.font.OpenTypeFontPeer;\nimport gnu.java.awt.peer.ClasspathFontPeer;\nimport java.awt.Font;\nimport java.awt.peer.FontPeer;\nimport java.io.File;\nimport java.util.HashMap;\nimport java.util.Map;\n'''
if 'import gnu.java.awt.font.OpenTypeFontPeer;' not in s:
    if anchor not in s: raise SystemExit('package anchor missing')
    s=s.replace(anchor, imports, 1)

# Add one deterministic cache/resource owner inside HeadlessToolkit.
class_anchor='public class HeadlessToolkit'
pos=s.find(class_anchor)
if pos < 0: raise SystemExit('HeadlessToolkit class anchor missing')
brace=s.find('{', pos)
if brace < 0: raise SystemExit('HeadlessToolkit class body missing')
fields='''\n  private static final String RG35XX_FONT_PATH = "resource/rg35xx/DejaVuSans.ttf";\n  private final Map rg35xxFontPeers = new HashMap();\n\n  private ClasspathFontPeer rg35xxFontPeer(String name, Map attrs)\n  {\n    String logical = (name == null) ? "SansSerif" : name;\n    String key = logical + "|" + String.valueOf(attrs);\n    ClasspathFontPeer peer = (ClasspathFontPeer) rg35xxFontPeers.get(key);\n    if (peer != null) return peer;\n    File f = new File(RG35XX_FONT_PATH);\n    if (!f.isFile()) throw new IllegalStateException("RG35XX font missing: " + f.getPath());\n    try\n      {\n        peer = new OpenTypeFontPeer(logical, attrs, f);\n      }\n    catch (Throwable t)\n      {\n        throw new IllegalStateException("RG35XX FontPeer init failed: " + t);\n      }\n    if (peer == null) throw new IllegalStateException("RG35XX FontPeer is null");\n    rg35xxFontPeers.put(key, peer);\n    return peer;\n  }\n'''
if 'RG35XX_FONT_PATH' not in s:
    s=s[:brace+1]+fields+s[brace+1:]

# Replace only method bodies that are still the null headless baseline.
pat1=re.compile(r'(protected\s+FontPeer\s+getFontPeer\s*\(\s*String\s+name\s*,\s*int\s+style\s*\)\s*\{)\s*return\s+null\s*;\s*\}', re.S)
rep1=r'''\1\n    Map attrs = new HashMap();\n    attrs.put(java.awt.font.TextAttribute.WEIGHT, (style & Font.BOLD) != 0 ? java.awt.font.TextAttribute.WEIGHT_BOLD : java.awt.font.TextAttribute.WEIGHT_REGULAR);\n    attrs.put(java.awt.font.TextAttribute.POSTURE, (style & Font.ITALIC) != 0 ? java.awt.font.TextAttribute.POSTURE_OBLIQUE : java.awt.font.TextAttribute.POSTURE_REGULAR);\n    return rg35xxFontPeer(name, attrs);\n  }'''
s,n1=pat1.subn(rep1,s,count=1)
if n1 != 1: raise SystemExit('guarded getFontPeer rewrite failed')
pat2=re.compile(r'(public\s+ClasspathFontPeer\s+getClasspathFontPeer\s*\(\s*String\s+name\s*,\s*Map\s+attrs\s*\)\s*\{)\s*return\s+null\s*;\s*\}', re.S)
rep2=r'''\1\n    return rg35xxFontPeer(name, attrs);\n  }'''
s,n2=pat2.subn(rep2,s,count=1)
if n2 != 1: raise SystemExit('guarded getClasspathFontPeer rewrite failed')
p.write_text(s)
PY

grep -q 'new OpenTypeFontPeer' "$HT" || fail "OpenTypeFontPeer integration missing after overlay"
grep -q 'RG35XX_FONT_PATH' "$HT" || fail "deterministic font path missing after overlay"
note "font overlay applied to disposable Classpath tree"
note "runtime FontPeer/JamVM smoke test is still required"
