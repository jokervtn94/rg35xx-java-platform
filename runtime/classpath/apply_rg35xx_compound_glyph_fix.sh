#!/bin/sh
set -eu
: "${RG35XX_CLASSPATH_ROOT:?set RG35XX_CLASSPATH_ROOT to disposable GNU Classpath 0.99 source}"
fail() { echo "RC1 GLYPH FIX: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 GLYPH FIX: $*"; }

ZONE="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/font/opentype/truetype/Zone.java"
[ -f "$ZONE" ] || fail "missing Zone.java"

grep -q 'void combineWithSubGlyph(Zone zone, int numPhantomPoints)' "$ZONE" || fail "unexpected Zone.java baseline"
grep -q 'System.arraycopy(zone.points, 0, this.points, offset, count);' "$ZONE" || fail "compound-glyph copy baseline missing"

python3 - "$ZONE" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1])
s=p.read_text()
pat=re.compile(r'''  void combineWithSubGlyph\(Zone zone, int numPhantomPoints\)\n  \{\n    int offset = this\.numPoints - numPhantomPoints;\n    int count = zone\.numPoints;\n    System\.arraycopy\(zone\.points, 0, this\.points, offset, count\);\n    this\.numPoints \+= count - numPhantomPoints;\n  \}''')
rep='''  void combineWithSubGlyph(Zone zone, int numPhantomPoints)\n  {\n    int offset = this.numPoints - numPhantomPoints;\n    int count = zone.numPoints;\n    int required = offset + count;\n\n    /* RG35XX RC1: compound glyphs can exceed the loader's initial point\n       estimate. GNU Classpath 0.99 copied blindly into the fixed Zone array,\n       which produced ArrayIndexOutOfBoundsException in Vietnamese/compound\n       glyph rendering. Grow only when required and preserve existing points. */\n    if (required > this.points.length)\n      {\n        int capacity = this.points.length * 2;\n        if (capacity < required)\n          capacity = required;\n        Point[] grown = new Point[capacity];\n        System.arraycopy(this.points, 0, grown, 0, this.numPoints);\n        this.points = grown;\n      }\n\n    System.arraycopy(zone.points, 0, this.points, offset, count);\n    this.numPoints += count - numPhantomPoints;\n  }'''
s2,n=pat.subn(rep,s,count=1)
if n != 1:
    raise SystemExit('unexpected Zone.combineWithSubGlyph baseline; refuse unreviewed rewrite')
p.write_text(s2)
PY

grep -q 'int required = offset + count;' "$ZONE" || fail "capacity guard missing"
grep -q 'Point\[\] grown = new Point\[capacity\];' "$ZONE" || fail "growth allocation missing"
grep -q 'System.arraycopy(this.points, 0, grown, 0, this.numPoints);' "$ZONE" || fail "existing-point preservation missing"
note "GNU Classpath compound-glyph Zone capacity fix applied"
note "This addresses the observed Zone.combineWithSubGlyph ArrayIndexOutOfBoundsException; compile and JamVM glyph smoke tests remain mandatory."
