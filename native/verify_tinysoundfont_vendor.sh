#!/bin/sh
set -eu

# RC1 dependency integrity gate. This script does not download dependencies.
# The native build must be reproducible/offline and must use the exact files
# reviewed in docs/RC1-TML-TSF-DEPENDENCY-GATE.md.
PIN="853a0a171759f1ddba0de1442133a75912bbeffa"
# Git blob identities from the authoritative upstream tree at PIN.
# Verified through GitHub Git Trees API on 2026-09-03.
TML_EXPECTED="333287377fa860fa7f3d8fe8096d3cf32bfbb6ea"
TSF_EXPECTED="a81f25d5ca2e210720d646dec2dbfaeb119acb09"
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