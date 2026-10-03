#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/scripts/build-p2c-input-frontend-physical-package.sh"
[ -f "$BASE" ] || { echo P2C_PHYSICAL_V2_FAIL=base_missing >&2; exit 1; }
BACKUP="$(mktemp)"
cp "$BASE" "$BACKUP"
cleanup(){ cp "$BACKUP" "$BASE" || true; rm -f "$BACKUP"; }
trap cleanup EXIT
python3 - "$BASE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(encoding='utf-8')
old='>>"MASTER"'
new='>>"$MASTER"'
if s.count(old)!=2:
    raise SystemExit('P2C_PHYSICAL_V2_REDIRECT_PATCH_FAIL count=%d' % s.count(old))
s=s.replace(old,new)
p.write_text(s,encoding='utf-8')
print('P2C_PHYSICAL_V2_REDIRECT_PATCH=PASS')
PY
bash "$BASE"
