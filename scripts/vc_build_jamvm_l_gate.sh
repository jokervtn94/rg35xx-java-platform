#!/usr/bin/env bash
set -euo pipefail

# B1 admission gate for the device-proven JamVM L Production binary.
# This script intentionally does not invent or patch another VM variant.

EXPECTED_SHA="eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34"
EXPECTED_BUILDER_COMMIT="4c4641c0c9ddd263452287bf4873d64be716ff91"
EXPECTED_FIX_COMMIT="6ae5cf3966b7b6b1f4fb81c0118dfc690b9736ca"
JAMVM="${1:-}"

if [ -z "$JAMVM" ] || [ ! -f "$JAMVM" ]; then
  echo "usage: $0 /path/to/jamvm" >&2
  exit 2
fi

actual="$(sha256sum "$JAMVM" | awk '{print $1}')"
[ "$actual" = "$EXPECTED_SHA" ] || {
  echo "B1 FAIL: JamVM SHA mismatch" >&2
  echo "expected=$EXPECTED_SHA" >&2
  echo "actual=$actual" >&2
  exit 10
}

file "$JAMVM" | grep -qi 'ELF 32-bit.*ARM' || {
  echo "B1 FAIL: not ELF32 ARM" >&2
  exit 11
}

if command -v readelf >/dev/null 2>&1; then
  readelf -h "$JAMVM" | grep -q 'Machine:.*ARM' || exit 12
fi

# Production L must not contain diagnostic variant markers.
for bad in 'BAD_CHECKCAST' 'RG35XX-JAMVM-D' 'RG35XX-JAMVM-E' 'RG35XX-JAMVM-F' \
           'RG35XX-JAMVM-G' 'RG35XX-JAMVM-H' 'RG35XX-JAMVM-I' 'LOWPTR_CHECKCAST'; do
  if strings "$JAMVM" 2>/dev/null | grep -Fq "$bad"; then
    echo "B1 FAIL: diagnostic marker admitted: $bad" >&2
    exit 13
  fi
done

cat <<EOF
B1 PASS
component=JamVM-L-Production
sha256=$actual
builder_workflow_commit=$EXPECTED_BUILDER_COMMIT
fix_source_commit=$EXPECTED_FIX_COMMIT
admission=DEVICE-PROVEN
fix=disable unsafe direct interpreter ALOAD_0+GETFIELD fusion to GETFIELD_THIS
diagnostics=none
EOF
