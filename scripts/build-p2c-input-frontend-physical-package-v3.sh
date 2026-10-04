#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/scripts/build-p2c-input-frontend-physical-package.sh"
V2="$ROOT/scripts/build-p2c-input-frontend-physical-package-v2.sh"
DIGEST="$ROOT/scripts/p2c-semantic-jar-digest.py"
EXPECTED_SEMANTIC="${EXPECTED_SEMANTIC:-${EXPECTED_PLATFORM_SEMANTIC:-0a4f197bdbf39b7102c69bb2e560c6e469c32c20ae58c8fb688fadbcecf1c6c6}}"

[ -f "$BASE" ] || { echo P2C_PHYSICAL_V3_FAIL=base_missing >&2; exit 1; }
[ -f "$V2" ] || { echo P2C_PHYSICAL_V3_FAIL=v2_missing >&2; exit 1; }
[ -f "$DIGEST" ] || { echo P2C_PHYSICAL_V3_FAIL=digest_helper_missing >&2; exit 1; }

BACKUP="$(mktemp)"
cp "$BASE" "$BACKUP"
cleanup(){ cp "$BACKUP" "$BASE" || true; rm -f "$BACKUP"; }
trap cleanup EXIT

python3 - "$BASE" "$EXPECTED_SEMANTIC" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); expected=sys.argv[2]
s=p.read_text(encoding='utf-8')

old='EXPECTED_PLATFORM=533442c7e67965c8ac095898bfb32c9fcdd233471cd19e64ca2012ceaca00c60'
new='EXPECTED_PLATFORM_SEMANTIC='+expected
if s.count(old) != 2:
    raise SystemExit('P2C_PHYSICAL_V3_EXPECTED_PLATFORM_COUNT_FAIL count=%d' % s.count(old))
s=s.replace(old,new,1)

old='[ "$(sha256sum "$CAND" | awk \'{print $1}\')" = "$EXPECTED_PLATFORM" ] || fail platform_hash'
new='[ "$(python3 "$ROOT/scripts/p2c-semantic-jar-digest.py" "$CAND")" = "$EXPECTED_PLATFORM_SEMANTIC" ] || fail platform_semantic_hash'
if s.count(old) != 1:
    raise SystemExit('P2C_PHYSICAL_V3_BUILD_GATE_PATCH_FAIL count=%d' % s.count(old))
s=s.replace(old,new)

old='EX_SHA="$(sha256sum "$EX" | awk \'{print $1}\')"'
new='''EX_SHA="$(sha256sum "$EX" | awk '{print $1}')"
PLATFORM_RAW_SHA="$(sha256sum "$CAND" | awk '{print $1}')"
PLATFORM_SEMANTIC_SHA="$(python3 "$ROOT/scripts/p2c-semantic-jar-digest.py" "$CAND")"
[ "$PLATFORM_SEMANTIC_SHA" = "$EXPECTED_PLATFORM_SEMANTIC" ] || fail platform_semantic_identity'''
if s.count(old) != 1:
    raise SystemExit('P2C_PHYSICAL_V3_PLATFORM_IDENTITY_INSERT_FAIL count=%d' % s.count(old))
s=s.replace(old,new)

old='P2C_PLATFORM_JAR_SHA256=$EXPECTED_PLATFORM'
new='''P2C_PLATFORM_JAR_RAW_SHA256=$PLATFORM_RAW_SHA
P2C_PLATFORM_JAR_SEMANTIC_SHA256=$PLATFORM_SEMANTIC_SHA'''
if s.count(old) != 2:
    raise SystemExit('P2C_PHYSICAL_V3_IDENTITY_FIELD_PATCH_FAIL count=%d' % s.count(old))
s=s.replace(old,new)

# The second raw literal is inside the single-quoted device launcher heredoc.
old='EXPECTED_PLATFORM=533442c7e67965c8ac095898bfb32c9fcdd233471cd19e64ca2012ceaca00c60'
new='EXPECTED_PLATFORM=__P2C_PLATFORM_RAW_SHA256__'
if s.count(old) != 1:
    raise SystemExit('P2C_PHYSICAL_V3_LAUNCHER_RAW_PLACEHOLDER_FAIL count=%d' % s.count(old))
s=s.replace(old,new)

old='python3 - "$PKGROOT/SD/Roms/APPS/RG35XX-P2C-INPUT-FRONTEND.sh" "$EX_SHA" <<\'PY\''
new='python3 - "$PKGROOT/SD/Roms/APPS/RG35XX-P2C-INPUT-FRONTEND.sh" "$EX_SHA" "$PLATFORM_RAW_SHA" <<\'PY\''
if s.count(old) != 1:
    raise SystemExit('P2C_PHYSICAL_V3_PLACEHOLDER_ARGS_PATCH_FAIL count=%d' % s.count(old))
s=s.replace(old,new)

old="""old='__P2C_EXERCISER_SHA256__'
if s.count(old)!=1: raise SystemExit('P2C_LAUNCHER_PLACEHOLDER_FAIL')
s=s.replace(old,sys.argv[2])
p.write_text(s,encoding='utf-8')"""
new="""old='__P2C_EXERCISER_SHA256__'
if s.count(old)!=1: raise SystemExit('P2C_LAUNCHER_PLACEHOLDER_FAIL')
s=s.replace(old,sys.argv[2])
raw='__P2C_PLATFORM_RAW_SHA256__'
if s.count(raw)!=1: raise SystemExit('P2C_PLATFORM_RAW_PLACEHOLDER_FAIL')
s=s.replace(raw,sys.argv[3])
p.write_text(s,encoding='utf-8')"""
if s.count(old) != 1:
    raise SystemExit('P2C_PHYSICAL_V3_PLACEHOLDER_BODY_PATCH_FAIL count=%d' % s.count(old))
s=s.replace(old,new)

p.write_text(s,encoding='utf-8')
print('P2C_PHYSICAL_V3_SEMANTIC_JAR_PATCH=PASS')
PY

bash "$V2"
echo "P2C_PHYSICAL_V3_EXPECTED_SEMANTIC_SHA256=$EXPECTED_SEMANTIC"
echo P2C_PHYSICAL_V3_SEMANTIC_JAR_GATE=PASS
