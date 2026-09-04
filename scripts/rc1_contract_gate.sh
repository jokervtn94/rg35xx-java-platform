#!/bin/sh
set -eu

# RGJ-RC1-011Q — integration-contract executability gate.
# The historical `patches/*.patch` directory contains a mix of executable
# unified diffs and design/specification documents. Build-ready must never feed
# a specification document to `patch(1)` and pretend the source was assembled.

MODE="${1:---project-static}"
case "$MODE" in
  --project-static|--build-ready) ;;
  *) echo "usage: sh scripts/rc1_contract_gate.sh [--project-static|--build-ready]" >&2; exit 2 ;;
esac

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "RC1 CONTRACT GATE: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 CONTRACT GATE: $*"; }

ACTIVE_CONTRACTS="
0003-manager-rg35xx-media-profile.patch
0004-libretro-dedicated-audio-pipe.patch
0005-libretro-java-audio-bootstrap.patch
0006-platformplayer-native-backend.patch
0007-platformgraphics-rg35xx-fast-drawrgb.patch
0008-platformgraphics-transform-cache.patch
0010-libretro-platform-lifecycle.patch
0011-platformimage-rg35xx-cache.patch
0014-libretro-native-media-events.patch
0015-libretro-native-media-runtime.patch
0016-libretro-java-audio-fd-exact.patch
0017-libretro-media-process-boundary.patch
0018-manager-platformplayer-rg35xx-direct-media.patch
0019-platformplayer-tonecontrol-rg35xx.patch
0020-pinned-graphics-input-lifecycle-consolidation.patch
0021-pinned-rms-safe-baseline.patch
"

TOTAL=0
EXECUTABLE=0
SPEC_ONLY=0
for p in $ACTIVE_CONTRACTS; do
  f="$ROOT/patches/$p"
  [ -f "$f" ] || fail "missing active integration contract: $p"
  TOTAL=$((TOTAL + 1))

  # Require all three structural pieces of a normal unified diff. Merely having
  # a .patch suffix, prose beginning with '#', or code snippets is not enough.
  if grep -q '^--- ' "$f" && grep -q '^+++ ' "$f" && grep -q '^@@ ' "$f"; then
    EXECUTABLE=$((EXECUTABLE + 1))
    note "EXECUTABLE-DIFF: $p"
  else
    SPEC_ONLY=$((SPEC_ONLY + 1))
    note "SPEC-ONLY: $p"
  fi
done

[ "$TOTAL" -gt 0 ] || fail "active contract set is empty"
note "summary total=$TOTAL executable=$EXECUTABLE spec-only=$SPEC_ONLY"

if [ "$MODE" = "--build-ready" ] && [ "$SPEC_ONLY" -ne 0 ]; then
  fail "$SPEC_ONLY active integration contracts are specification-only; materialize executable source overlays/diffs before BUILD-READY"
fi

if [ "$MODE" = "--project-static" ]; then
  note "STATIC CONTRACT INVENTORY PASS — specification-only items remain build blockers by design"
else
  note "BUILD-READY CONTRACT EXECUTABILITY PASS"
fi
