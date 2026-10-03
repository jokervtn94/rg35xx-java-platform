#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/scripts/build-p2b-font-text-candidate.sh"
BACKUP="$(mktemp)"
cp "$BASE" "$BACKUP"
cleanup(){ cp "$BACKUP" "$BASE"; rm -f "$BACKUP"; }
trap cleanup EXIT
python3 - "$BASE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
old='JAVA8="$JAVA8" bash "$ROOT/scripts/build-p2a-image-decode-candidate.sh" | tee "$OUT/P2B-P2A-PARENT-REBUILD.txt"'
new='JAVA8="$JAVA8" bash "$ROOT/scripts/build-p2a-image-decode-candidate-v3.sh" | tee "$OUT/P2B-P2A-PARENT-REBUILD.txt"'
if s.count(old)!=1:
    raise SystemExit('P2B_R1_V2_PARENT_ENTRYPOINT_PATCH_FAIL count=%d' % s.count(old))
s=s.replace(old,new)

# Exact accepted P2A v3 already carries the canonical Miyoo Font baseline and
# the Raw2D Font metric hooks. P2B recompiles Font.java to prove Java6/source
# compatibility, but the minimum semantic JAR delta must leave Font.class
# byte-identical and replace only the backing owner + whole-string renderer.
old_owner="""expected=['javax/microedition/lcdui/Font.class','org/recompile/mobile/PlatformGraphics.class','org/recompile/rg35xx/RG35XXCore2D$RawImage.class','org/recompile/rg35xx/RG35XXCore2D.class']
with zipfile.ZipFile(a) as za,zipfile.ZipFile(b) as zb:
    if set(za.namelist())!=set(zb.namelist()): raise SystemExit('P2B_OWNER_SCOPE_FAIL entry-set')
    changed=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if changed!=expected: raise SystemExit('P2B_OWNER_SCOPE_FAIL changed='+repr(changed))
print('P2B_CHANGED_JAR_ENTRIES='+','.join(changed)); print('P2B_OWNER_SCOPE_VERIFIED=PASS')
"""
new_owner="""font_entry='javax/microedition/lcdui/Font.class'
expected=['org/recompile/mobile/PlatformGraphics.class','org/recompile/rg35xx/RG35XXCore2D$RawImage.class','org/recompile/rg35xx/RG35XXCore2D.class']
with zipfile.ZipFile(a) as za,zipfile.ZipFile(b) as zb:
    if set(za.namelist())!=set(zb.namelist()): raise SystemExit('P2B_OWNER_SCOPE_FAIL entry-set')
    if hashlib.sha256(za.read(font_entry)).digest()!=hashlib.sha256(zb.read(font_entry)).digest():
        raise SystemExit('P2B_OWNER_SCOPE_FAIL Font.class parent identity drift')
    changed=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if changed!=expected: raise SystemExit('P2B_OWNER_SCOPE_FAIL changed='+repr(changed))
print('P2B_FONT_CLASS_PARENT_IDENTITY=PASS')
print('P2B_CHANGED_JAR_ENTRIES='+','.join(changed)); print('P2B_OWNER_SCOPE_VERIFIED=PASS')
"""
if s.count(old_owner)!=1:
    raise SystemExit('P2B_R1_V2_OWNER_GATE_PATCH_FAIL count=%d' % s.count(old_owner))
s=s.replace(old_owner,new_owner)
p.write_text(s,encoding='utf-8')
print('P2B_R1_P2A_ACCEPTED_V3_ENTRYPOINT=PASS')
print('P2B_R1_FONT_CLASS_PARENT_IDENTITY_CONTRACT=PASS')
print('P2B_R1_RUNTIME_SEMANTIC_DELTA=NONE')
PY
JAVA8="${JAVA8:-${JAVA_HOME:-}}" bash "$BASE"
