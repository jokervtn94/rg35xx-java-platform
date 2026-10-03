#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash "$ROOT/scripts/build-p1a-g2d-arc-family-jdk8-raster.sh"

OUT="$ROOT/out/p1a-g2d-arc-family-jdk8-raster"
ID="$OUT/P1A-G2D-IDENTITY.txt"
JAR="$OUT/freej2me-rg35xx.jar"
[ -f "$ID" ] || { echo P1A_G2D_IDENTITY_FIX_FAIL=identity_missing >&2; exit 1; }
[ -f "$JAR" ] || { echo P1A_G2D_IDENTITY_FIX_FAIL=jar_missing >&2; exit 1; }

BEFORE_JAR_SHA="$(sha256sum "$JAR" | awk '{print $1}')"
python3 - "$ID" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
old = 'FILL_RASTER=JDK8_PROCESSPATH_EQUIVALENT_INTEGER_ELLIPSE_PARAMETER_SECTOR\n'
new = 'FILL_RASTER=OPENJDK8_FILLPATH_PROCESSPATH_PIE_FIXEDPOINT_NONZERO_ACTIVE_EDGE_SCAN\n'
if s.count(old) != 1:
    raise SystemExit('P1A_G2D_IDENTITY_FIX_FAIL stale_fill_raster_count=%d' % s.count(old))
if new in s:
    raise SystemExit('P1A_G2D_IDENTITY_FIX_FAIL corrected_marker_preexists')
p.write_text(s.replace(old, new, 1), encoding='utf-8')
print('P1A_G2D_IDENTITY_FILL_RASTER_CORRECTION=PASS')
print('P1A_G2D_IDENTITY_RUNTIME_LOGIC_CHANGE=NO')
PY
AFTER_JAR_SHA="$(sha256sum "$JAR" | awk '{print $1}')"
[ "$BEFORE_JAR_SHA" = "$AFTER_JAR_SHA" ] || { echo P1A_G2D_IDENTITY_FIX_FAIL=jar_hash_changed >&2; exit 1; }

grep -q '^FILL_RASTER=OPENJDK8_FILLPATH_PROCESSPATH_PIE_FIXEDPOINT_NONZERO_ACTIVE_EDGE_SCAN$' "$ID"
! grep -q '^FILL_RASTER=JDK8_PROCESSPATH_EQUIVALENT_INTEGER_ELLIPSE_PARAMETER_SECTOR$' "$ID"

(
  cd "$OUT"
  find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt
)

cat > "$OUT/P1A-G2D-IDENTITY-CORRECTION.txt" <<EOF
P1A_G2D_IDENTITY_CORRECTION=PASS
OLD_FILL_RASTER=JDK8_PROCESSPATH_EQUIVALENT_INTEGER_ELLIPSE_PARAMETER_SECTOR
NEW_FILL_RASTER=OPENJDK8_FILLPATH_PROCESSPATH_PIE_FIXEDPOINT_NONZERO_ACTIVE_EDGE_SCAN
RUNTIME_LOGIC_CHANGE=NO
RUNTIME_JAR_SHA_BEFORE=$BEFORE_JAR_SHA
RUNTIME_JAR_SHA_AFTER=$AFTER_JAR_SHA
RUNTIME_JAR_SHA_UNCHANGED=YES
DEVICE_PASS=NO
STABLE=NO
EOF
# Include the correction record itself in the final artifact checksum manifest.
(
  cd "$OUT"
  find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt
)

echo P1A_G2D_IDENTITY_FIX=PASS
echo P1A_G2D_RUNTIME_ARTIFACT_SHA_UNCHANGED=YES
echo P1A_G2D_FILL_RASTER=OPENJDK8_FILLPATH_PROCESSPATH_PIE_FIXEDPOINT_NONZERO_ACTIVE_EDGE_SCAN
