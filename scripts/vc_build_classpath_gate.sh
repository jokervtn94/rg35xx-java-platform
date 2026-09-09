#!/usr/bin/env bash
set -euo pipefail

# B2: GNU Classpath is an immutable device baseline in the clean rebuild.
# We do NOT rebuild/byte-patch glibj.zip here. Admission is exact-hash only.

EXPECTED_SHA="d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea"
GLIBJ="${1:-}"

if [ -z "$GLIBJ" ] || [ ! -f "$GLIBJ" ]; then
  echo "usage: $0 /path/to/glibj.zip" >&2
  exit 2
fi

actual="$(sha256sum "$GLIBJ" | awk '{print $1}')"
[ "$actual" = "$EXPECTED_SHA" ] || {
  echo "B2 FAIL: glibj.zip differs from immutable baseline" >&2
  echo "expected=$EXPECTED_SHA" >&2
  echo "actual=$actual" >&2
  exit 20
}

unzip -t "$GLIBJ" >/dev/null || {
  echo "B2 FAIL: invalid glibj.zip" >&2
  exit 21
}

# Explicitly reject historical binary-patch markers if they ever appear.
if unzip -p "$GLIBJ" 2>/dev/null | strings 2>/dev/null | grep -Eq 'RG35XX-PNG-COMPAT|PNGChunk.*RG35XX'; then
  echo "B2 FAIL: experimental PNG byte patch marker detected" >&2
  exit 22
fi

cat <<EOF
B2 PASS
component=GNU-Classpath-glibj
sha256=$actual
policy=IMMUTABLE-DEVICE-BASELINE
rebuild=no
byte_patch=no
EOF
