#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="$ROOT/scripts/stage-p2a-image-decode.py"
BACKUP="$(mktemp)"
cp "$STAGE" "$BACKUP"
cleanup(){ cp "$BACKUP" "$STAGE"; rm -f "$BACKUP"; }
trap cleanup EXIT

python3 - "$STAGE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
old="""required = [
    'if (interlace == 1) return decodeAdam7(width, height, bitDepth, colorType, palette, transparency, idat.toByteArray());',
    'private static RawImage decodeAdam7(int width, int height, int bitDepth, int colorType,',
    'private static int passSize(int size, int start, int step) {'
]
"""
new="""required = [
    'private static RawImage decodeAdam7(int width, int height, int bitDepth, int colorType,',
    'private static int passSize(int size, int start, int step) {'
]
"""
if s.count(old) != 1:
    raise SystemExit('P2A_IMAGE_V2_STAGE_BOUNDARY_FAIL required-block count=%d' % s.count(old))
p.write_text(s.replace(old,new),encoding='utf-8')
print('P2A_IMAGE_V2_STAGE_BOUNDARY_PATCH=PASS')
print('P2A_IMAGE_V2_RUNTIME_SEMANTIC_DELTA=NONE')
PY

JAVA8="${JAVA8:-${JAVA_HOME:-}}" bash "$ROOT/scripts/build-p2a-image-decode-candidate.sh"
