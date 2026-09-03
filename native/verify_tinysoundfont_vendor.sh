#!/bin/sh
set -eu

# RC1 dependency integrity gate. This script does not download dependencies.
# The native build must be reproducible/offline and must use the exact files
# reviewed in docs/RC1-TML-TSF-DEPENDENCY-GATE.md.
PIN="853a0a171759f1ddba0de1442133a75912bbeffa"
TML_EXPECTED="6b3b6cdd1a212115787d7f32fc63a9e1f680814a"
TSF_EXPECTED="7c64a18a73d43bb0d4878c2e729b7e259b985cd4"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TML="$ROOT/native/vendor/TinySoundFont/tml.h"
TSF="$ROOT/native/vendor/TinySoundFont/tsf.h"

fail() {
    echo "RC1 TinySoundFont vendor gate: $*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || fail "git is required to verify vendored blob identity"
[ -f "$TML" ] || fail "missing $TML (expected upstream pin $PIN)"
[ -f "$TSF" ] || fail "missing $TSF (expected upstream pin $PIN)"

TML_ACTUAL=$(git hash-object "$TML")
TSF_ACTUAL=$(git hash-object "$TSF")
[ "$TML_ACTUAL" = "$TML_EXPECTED" ] || fail "tml.h blob mismatch: $TML_ACTUAL != $TML_EXPECTED"
[ "$TSF_ACTUAL" = "$TSF_EXPECTED" ] || fail "tsf.h blob mismatch: $TSF_ACTUAL != $TSF_EXPECTED"

echo "RC1 TinySoundFont vendor gate: PASS ($PIN)"
