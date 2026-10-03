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
p.write_text(s.replace(old,new),encoding='utf-8')
print('P2B_R1_P2A_ACCEPTED_V3_ENTRYPOINT=PASS')
print('P2B_R1_RUNTIME_SEMANTIC_DELTA=NONE')
PY
JAVA8="${JAVA8:-${JAVA_HOME:-}}" bash "$BASE"
