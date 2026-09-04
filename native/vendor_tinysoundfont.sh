#!/bin/sh
set -eu

# Deterministically acquire the exact TinyMidiLoader/TinySoundFont headers
# reviewed for RG35XX RC1. Network is required only for this acquisition step;
# normal native builds use the vendored files and verify them offline.
PIN="853a0a171759f1ddba0de1442133a75912bbeffa"
TML_EXPECTED="333287377fa860fa7f3d8fe8096d3cf32bfbb6ea"
TSF_EXPECTED="a81f25d5ca2e210720d646dec2dbfaeb119acb09"
UPSTREAM="https://github.com/schellingb/TinySoundFont.git"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DEST="$ROOT/native/vendor/TinySoundFont"
TMP="$ROOT/native/vendor/.tinysoundfont-acquire.$$"

fail() {
    echo "RC1 TinySoundFont acquisition: $*" >&2
    exit 1
}

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT HUP INT TERM

command -v git >/dev/null 2>&1 || fail "git is required"
mkdir -p "$ROOT/native/vendor"
rm -rf "$TMP"
mkdir -p "$TMP"

git -C "$TMP" init -q
git -C "$TMP" remote add origin "$UPSTREAM"
git -C "$TMP" fetch -q --depth=1 origin "$PIN"

TML_SOURCE_SHA=$(git -C "$TMP" rev-parse "FETCH_HEAD:tml.h")
TSF_SOURCE_SHA=$(git -C "$TMP" rev-parse "FETCH_HEAD:tsf.h")
[ "$TML_SOURCE_SHA" = "$TML_EXPECTED" ] || fail "upstream tml.h blob mismatch: $TML_SOURCE_SHA != $TML_EXPECTED"
[ "$TSF_SOURCE_SHA" = "$TSF_EXPECTED" ] || fail "upstream tsf.h blob mismatch: $TSF_SOURCE_SHA != $TSF_EXPECTED"

mkdir -p "$DEST"
git -C "$TMP" show "FETCH_HEAD:tml.h" > "$DEST/tml.h.tmp"
git -C "$TMP" show "FETCH_HEAD:tsf.h" > "$DEST/tsf.h.tmp"

TML_LOCAL_SHA=$(git hash-object "$DEST/tml.h.tmp")
TSF_LOCAL_SHA=$(git hash-object "$DEST/tsf.h.tmp")
[ "$TML_LOCAL_SHA" = "$TML_EXPECTED" ] || fail "written tml.h mismatch: $TML_LOCAL_SHA != $TML_EXPECTED"
[ "$TSF_LOCAL_SHA" = "$TSF_EXPECTED" ] || fail "written tsf.h mismatch: $TSF_LOCAL_SHA != $TSF_EXPECTED"

mv -f "$DEST/tml.h.tmp" "$DEST/tml.h"
mv -f "$DEST/tsf.h.tmp" "$DEST/tsf.h"

sh "$ROOT/native/verify_tinysoundfont_vendor.sh"
echo "RC1 TinySoundFont acquisition: PASS ($PIN)"