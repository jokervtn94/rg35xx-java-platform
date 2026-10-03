#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_SCRIPT="$ROOT/scripts/build-p2a-image-decode-candidate.sh"
BACKUP="$(mktemp)"
cp "$BUILD_SCRIPT" "$BACKUP"
cleanup(){ cp "$BACKUP" "$BUILD_SCRIPT"; rm -f "$BACKUP"; }
trap cleanup EXIT

python3 - "$BUILD_SCRIPT" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
old="expected=['org/recompile/rg35xx/RG35XXCore2D$RawImage.class','org/recompile/rg35xx/RG35XXCore2D.class']"
new="expected=['org/recompile/rg35xx/RG35XXCore2D.class']"
if s.count(old) != 1:
    raise SystemExit('P2A_IMAGE_V3_DIFF_GATE_PATCH_FAIL expected-list count=%d' % s.count(old))
s=s.replace(old,new)
old_id='CHANGED_JAR_ENTRIES=org/recompile/rg35xx/RG35XXCore2D\\$RawImage.class,org/recompile/rg35xx/RG35XXCore2D.class'
new_id='CHANGED_JAR_ENTRIES=org/recompile/rg35xx/RG35XXCore2D.class'
if s.count(old_id) != 1:
    raise SystemExit('P2A_IMAGE_V3_IDENTITY_PATCH_FAIL changed-entry count=%d' % s.count(old_id))
s=s.replace(old_id,new_id)
p.write_text(s,encoding='utf-8')
print('P2A_IMAGE_V3_ACTUAL_JAR_DIFF_PATCH=PASS')
print('P2A_IMAGE_V3_CHANGED_JAR_ENTRIES=org/recompile/rg35xx/RG35XXCore2D.class')
print('P2A_IMAGE_V3_RUNTIME_SEMANTIC_DELTA=NONE')
PY

JAVA8="${JAVA8:-${JAVA_HOME:-}}" bash "$ROOT/scripts/build-p2a-image-decode-candidate-v2.sh"
