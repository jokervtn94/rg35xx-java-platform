#!/bin/sh
set -eu
: "${RG35XX_CLASSPATH_ROOT:?set RG35XX_CLASSPATH_ROOT to disposable GNU Classpath 0.99 source}"
: "${RG35XX_FONT_FILE:?set RG35XX_FONT_FILE to materialized DejaVuSans.ttf}"
fail() { echo "RC1 FONT OVERLAY: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 FONT OVERLAY: $*"; }
HT="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/peer/headless/HeadlessToolkit.java"
OT="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/font/OpenTypeFontPeer.java"
[ -f "$HT" ] || fail "missing HeadlessToolkit.java"
[ -f "$OT" ] || fail "missing OpenTypeFontPeer.java"
[ -s "$RG35XX_FONT_FILE" ] || fail "missing DejaVuSans.ttf"
grep -q 'public OpenTypeFontPeer(String name, int style, int size)' "$OT" || fail "unexpected OpenTypeFontPeer int constructor"
grep -q 'public OpenTypeFontPeer(String name, Map atts)' "$OT" || fail "unexpected OpenTypeFontPeer Map constructor"
grep -q 'mapFontToFilename' "$OT" || fail "OpenTypeFontPeer mapping owner missing"
grep -q 'getResourceAsStream("fonts.properties")' "$OT" || fail "fonts.properties contract missing"
FONT_PROPS=$(find "$RG35XX_CLASSPATH_ROOT" -type f -path '*/gnu/java/awt/font/fonts.properties' -print)
COUNT=$(printf '%s\n' "$FONT_PROPS" | sed '/^$/d' | wc -l | tr -d ' ')
[ "$COUNT" = 1 ] || fail "expected exactly one gnu/java/awt/font/fonts.properties, found $COUNT"
# OpenTypeFontPeer opens the mapped value with new File(filename); use an absolute deterministic
# assembly path, not a classpath-resource-looking relative path.
FONT_DST="$RG35XX_CLASSPATH_ROOT/resource/rg35xx/DejaVuSans.ttf"
mkdir -p "$(dirname "$FONT_DST")"
cp "$RG35XX_FONT_FILE" "$FONT_DST"
cat > "$FONT_PROPS" <<EOF
SansSerif/p=$FONT_DST
SansSerif/b=$FONT_DST
SansSerif/i=$FONT_DST
SansSerif/bi=$FONT_DST
Dialog/p=$FONT_DST
Dialog/b=$FONT_DST
Dialog/i=$FONT_DST
Dialog/bi=$FONT_DST
Monospaced/p=$FONT_DST
Monospaced/b=$FONT_DST
Monospaced/i=$FONT_DST
Monospaced/bi=$FONT_DST
EOF
python3 - "$HT" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1]); s=p.read_text()
# Add only imports absent from the upstream file. Do not duplicate ClasspathFontPeer/Font/FontPeer/Map.
anchor='import gnu.java.awt.EmbeddedWindow;\n'
if 'import gnu.java.awt.font.OpenTypeFontPeer;' not in s:
    if anchor not in s: raise SystemExit('import anchor missing')
    s=s.replace(anchor, anchor+'import gnu.java.awt.font.OpenTypeFontPeer;\n', 1)
if 'import java.util.HashMap;' not in s:
    map_anchor='import java.util.Map;\n'
    if map_anchor not in s: raise SystemExit('Map import anchor missing')
    s=s.replace(map_anchor, 'import java.util.HashMap;\n'+map_anchor, 1)
pos=s.find('public class HeadlessToolkit')
if pos < 0: raise SystemExit('HeadlessToolkit class anchor missing')
brace=s.find('{', pos)
if brace < 0: raise SystemExit('HeadlessToolkit class body missing')
fields='''\n  private final Map rg35xxFontPeers = new HashMap();\n\n  private ClasspathFontPeer rg35xxFontPeer(String name, Map attrs)\n  {\n    String logical = (name == null || name.length() == 0) ? "SansSerif" : name;\n    if (!(logical.equals("SansSerif") || logical.equals("Dialog") || logical.equals("Monospaced"))) logical = "SansSerif";\n    String key = logical + "|" + String.valueOf(attrs);\n    ClasspathFontPeer peer = (ClasspathFontPeer) rg35xxFontPeers.get(key);\n    if (peer != null) return peer;\n    peer = new OpenTypeFontPeer(logical, attrs);\n    rg35xxFontPeers.put(key, peer);\n    return peer;\n  }\n'''
if 'rg35xxFontPeers' not in s: s=s[:brace+1]+fields+s[brace+1:]
pat1=re.compile(r'(protected\s+FontPeer\s+getFontPeer\s*\(\s*String\s+name\s*,\s*int\s+style\s*\)\s*\{)(?:\s*//[^\n]*\n)?\s*return\s+null\s*;\s*\}', re.S)
rep1=r'''\1\n    Map attrs = new HashMap();\n    attrs.put(java.awt.font.TextAttribute.WEIGHT, (style & Font.BOLD) != 0 ? java.awt.font.TextAttribute.WEIGHT_BOLD : java.awt.font.TextAttribute.WEIGHT_REGULAR);\n    attrs.put(java.awt.font.TextAttribute.POSTURE, (style & Font.ITALIC) != 0 ? java.awt.font.TextAttribute.POSTURE_OBLIQUE : java.awt.font.TextAttribute.POSTURE_REGULAR);\n    return rg35xxFontPeer(name, attrs);\n  }'''
s,n1=pat1.subn(rep1,s,count=1)
if n1 != 1: raise SystemExit('guarded getFontPeer rewrite failed')
pat2=re.compile(r'(public\s+ClasspathFontPeer\s+getClasspathFontPeer\s*\(\s*String\s+name\s*,\s*Map\s+attrs\s*\)\s*\{)(?:\s*//[^\n]*\n)?\s*return\s+null\s*;\s*\}', re.S)
s,n2=pat2.subn(r'''\1\n    return rg35xxFontPeer(name, attrs);\n  }''',s,count=1)
if n2 != 1: raise SystemExit('guarded getClasspathFontPeer rewrite failed')
p.write_text(s)
PY
grep -q 'new OpenTypeFontPeer(logical, attrs)' "$HT" || fail "correct constructor integration missing"
[ "$(grep -c '^import gnu.java.awt.peer.ClasspathFontPeer;' "$HT")" = 1 ] || fail "ClasspathFontPeer import duplication"
[ "$(grep -c '^import java.awt.Font;' "$HT")" = 1 ] || fail "Font import duplication"
[ "$(grep -c '^import java.awt.peer.FontPeer;' "$HT")" = 1 ] || fail "FontPeer import duplication"
[ "$(grep -c '^import java.util.Map;' "$HT")" = 1 ] || fail "Map import duplication"
grep -q "^SansSerif/p=$FONT_DST$" "$FONT_PROPS" || fail "SansSerif mapping missing"
grep -q "^Monospaced/p=$FONT_DST$" "$FONT_PROPS" || fail "Monospaced mapping missing"
note "font overlay applied against verified OpenTypeFontPeer(name, Map) API"
note "OpenTypeFontPeer uses filesystem mapping; fonts.properties points to materialized absolute TTF"
note "compile + JamVM glyph smoke test remain mandatory"
