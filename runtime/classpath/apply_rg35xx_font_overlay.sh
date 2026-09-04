#!/bin/sh
set -eu
: "${RG35XX_CLASSPATH_ROOT:?set RG35XX_CLASSPATH_ROOT to disposable GNU Classpath 0.99 source}"
: "${RG35XX_FONT_FILE:?set RG35XX_FONT_FILE to materialized DejaVuSans.ttf}"
: "${RG35XX_FONT_RUNTIME_PATH:?set RG35XX_FONT_RUNTIME_PATH to the absolute target-device DejaVuSans.ttf path}"
fail() { echo "RC1 FONT OVERLAY: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 FONT OVERLAY: $*"; }
HT="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/peer/headless/HeadlessToolkit.java"
OT="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/font/OpenTypeFontPeer.java"
[ -f "$HT" ] || fail "missing HeadlessToolkit.java"
[ -f "$OT" ] || fail "missing OpenTypeFontPeer.java"
[ -s "$RG35XX_FONT_FILE" ] || fail "missing DejaVuSans.ttf"
case "$RG35XX_FONT_RUNTIME_PATH" in /*) ;; *) fail "RG35XX_FONT_RUNTIME_PATH must be absolute on the target device" ;; esac
case "$RG35XX_FONT_RUNTIME_PATH" in *"$RG35XX_CLASSPATH_ROOT"*) fail "runtime font path must not reference the disposable Classpath assembly tree" ;; esac

# Guard against source drift. GNU Classpath 0.99 has both public constructors and a
# fonts.properties-backed filesystem mapping in OpenTypeFontPeer.
grep -q 'public OpenTypeFontPeer(String name, int style, int size)' "$OT" || fail "unexpected OpenTypeFontPeer int constructor"
grep -q 'public OpenTypeFontPeer(String name, Map atts)' "$OT" || fail "unexpected OpenTypeFontPeer Map constructor"
grep -q 'mapFontToFilename' "$OT" || fail "OpenTypeFontPeer mapping owner missing"
grep -q 'getResourceAsStream("fonts.properties")' "$OT" || fail "fonts.properties contract missing"
FONT_PROPS=$(find "$RG35XX_CLASSPATH_ROOT" -type f -path '*/gnu/java/awt/font/fonts.properties' -print)
COUNT=$(printf '%s\n' "$FONT_PROPS" | sed '/^$/d' | wc -l | tr -d ' ')
[ "$COUNT" = 1 ] || fail "expected exactly one gnu/java/awt/font/fonts.properties, found $COUNT"

# Keep a staged copy in the disposable runtime tree for packaging, but map the Classpath
# runtime to the explicit target-device path. Never bake a build-host/assembly path into
# fonts.properties: that would pass compilation and fail later on RG35XX.
FONT_STAGE="$RG35XX_CLASSPATH_ROOT/resource/rg35xx/DejaVuSans.ttf"
mkdir -p "$(dirname "$FONT_STAGE")"
cp "$RG35XX_FONT_FILE" "$FONT_STAGE"
cat > "$FONT_PROPS" <<EOF
SansSerif/p=$RG35XX_FONT_RUNTIME_PATH
SansSerif/b=$RG35XX_FONT_RUNTIME_PATH
SansSerif/i=$RG35XX_FONT_RUNTIME_PATH
SansSerif/bi=$RG35XX_FONT_RUNTIME_PATH
Dialog/p=$RG35XX_FONT_RUNTIME_PATH
Dialog/b=$RG35XX_FONT_RUNTIME_PATH
Dialog/i=$RG35XX_FONT_RUNTIME_PATH
Dialog/bi=$RG35XX_FONT_RUNTIME_PATH
Monospaced/p=$RG35XX_FONT_RUNTIME_PATH
Monospaced/b=$RG35XX_FONT_RUNTIME_PATH
Monospaced/i=$RG35XX_FONT_RUNTIME_PATH
Monospaced/bi=$RG35XX_FONT_RUNTIME_PATH
EOF

python3 - "$HT" "$OT" <<'PY'
from pathlib import Path
import re, sys
ht=Path(sys.argv[1]); ot=Path(sys.argv[2])
s=ht.read_text()
if not re.search(r'protected\s+FontPeer\s+getFontPeer\s*\(\s*String\s+name\s*,\s*int\s+style\s*\).*?return\s+null\s*;', s, re.S):
    raise SystemExit('unexpected getFontPeer baseline; refuse unreviewed rewrite')
if not re.search(r'public\s+ClasspathFontPeer\s+getClasspathFontPeer\s*\(\s*String\s+name\s*,\s*Map\s+attrs\s*\).*?return\s+null\s*;', s, re.S):
    raise SystemExit('unexpected getClasspathFontPeer baseline; refuse unreviewed rewrite')
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
fields='''\n  /* RG35XX RC1: one cached peer per logical family/attribute set. */\n  private final Map rg35xxFontPeers = new HashMap();\n\n  private synchronized ClasspathFontPeer rg35xxFontPeer(String name, Map attrs)\n  {\n    String logical = (name == null || name.length() == 0) ? "SansSerif" : name;\n    if (!(logical.equals("SansSerif") || logical.equals("Dialog") || logical.equals("Monospaced")))\n      logical = "SansSerif";\n    Map byAttrs = (Map) rg35xxFontPeers.get(logical);\n    if (byAttrs == null)\n      {\n        byAttrs = new HashMap();\n        rg35xxFontPeers.put(logical, byAttrs);\n      }\n    Map attrKey = new HashMap();\n    if (attrs != null) attrKey.putAll(attrs);\n    ClasspathFontPeer peer = (ClasspathFontPeer) byAttrs.get(attrKey);\n    if (peer == null)\n      {\n        peer = new OpenTypeFontPeer(logical, attrKey);\n        byAttrs.put(attrKey, peer);\n      }\n    return peer;\n  }\n'''
if 'rg35xxFontPeers' not in s:
    s=s[:brace+1]+fields+s[brace+1:]
pat1=re.compile(r'(protected\s+FontPeer\s+getFontPeer\s*\(\s*String\s+name\s*,\s*int\s+style\s*\)\s*\{)(?:\s*//[^\n]*\n)?\s*return\s+null\s*;\s*\}', re.S)
rep1=r'''\1\n    Map attrs = new HashMap();\n    attrs.put(java.awt.font.TextAttribute.WEIGHT, (style & Font.BOLD) != 0 ? java.awt.font.TextAttribute.WEIGHT_BOLD : java.awt.font.TextAttribute.WEIGHT_REGULAR);\n    attrs.put(java.awt.font.TextAttribute.POSTURE, (style & Font.ITALIC) != 0 ? java.awt.font.TextAttribute.POSTURE_OBLIQUE : java.awt.font.TextAttribute.POSTURE_REGULAR);\n    return rg35xxFontPeer(name, attrs);\n  }'''
s,n1=pat1.subn(rep1,s,count=1)
if n1 != 1: raise SystemExit('guarded getFontPeer rewrite failed')
pat2=re.compile(r'(public\s+ClasspathFontPeer\s+getClasspathFontPeer\s*\(\s*String\s+name\s*,\s*Map\s+attrs\s*\)\s*\{)(?:\s*//[^\n]*\n)?\s*return\s+null\s*;\s*\}', re.S)
s,n2=pat2.subn(r'''\1\n    return rg35xxFontPeer(name, attrs);\n  }''',s,count=1)
if n2 != 1: raise SystemExit('guarded getClasspathFontPeer rewrite failed')
ht.write_text(s)
o=ot.read_text()
needle='''    catch (Exception ex)\n      {\n        ex.printStackTrace();\n      }'''
count=o.count(needle)
if count != 2:
    raise SystemExit('unexpected OpenTypeFontPeer constructor failure paths: %d' % count)
replacement='''    catch (Exception ex)\n      {\n        throw new RuntimeException("RG35XX: unable to initialize OpenType font peer", ex);\n      }'''
o=o.replace(needle,replacement)
ot.write_text(o)
PY

grep -q 'new OpenTypeFontPeer(logical, attrKey)' "$HT" || fail "Map-constructor integration missing"
grep -q 'private synchronized ClasspathFontPeer rg35xxFontPeer' "$HT" || fail "font peer cache is not synchronized"
grep -q 'throw new RuntimeException("RG35XX: unable to initialize OpenType font peer", ex);' "$OT" || fail "fail-closed OpenType constructor policy missing"
[ "$(grep -c '^import gnu.java.awt.peer.ClasspathFontPeer;' "$HT")" = 1 ] || fail "ClasspathFontPeer import duplication"
[ "$(grep -c '^import java.awt.Font;' "$HT")" = 1 ] || fail "Font import duplication"
[ "$(grep -c '^import java.awt.peer.FontPeer;' "$HT")" = 1 ] || fail "FontPeer import duplication"
[ "$(grep -c '^import java.util.Map;' "$HT")" = 1 ] || fail "Map import duplication"
grep -Fq "SansSerif/p=$RG35XX_FONT_RUNTIME_PATH" "$FONT_PROPS" || fail "SansSerif runtime mapping missing"
grep -Fq "Monospaced/p=$RG35XX_FONT_RUNTIME_PATH" "$FONT_PROPS" || fail "Monospaced runtime mapping missing"
[ -s "$FONT_STAGE" ] || fail "staged font package payload missing"
note "font overlay applied against verified GNU Classpath 0.99 OpenTypeFontPeer API"
note "runtime path=$RG35XX_FONT_RUNTIME_PATH; staged payload=$FONT_STAGE"
note "logical-family/attribute peer cache enabled; constructor failures fail closed"
note "compile + JamVM Font.hashCode/createGlyphVector/metrics smoke tests remain mandatory"
