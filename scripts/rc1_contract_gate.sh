#!/bin/sh
set -eu

# RGJ-RC1-011Q/011R — integration-contract executability gate.
# Historical `patches/*.patch` contains both executable diffs and specifications.
# The active set contains only authoritative source-mutation owners; superseded
# design contracts stay in history but must not be double-applied.

MODE="${1:---project-static}"
case "$MODE" in
  --project-static|--build-ready) ;;
  *) echo "usage: sh scripts/rc1_contract_gate.sh [--project-static|--build-ready]" >&2; exit 2 ;;
esac

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "RC1 CONTRACT GATE: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 CONTRACT GATE: $*"; }

# Superseded mutation owners retained as design/history only:
# - 0004 -> 0016 exact audio-pipe argv/FD/fork integration.
# - 0005 -> 0010 + RG35XXLifecycle Java bootstrap ownership; 0017 final EOF.
# - 0006 -> 0018 exact PlatformPlayer direct MIDI/WAV facade/backend integration.
ACTIVE_CONTRACTS="
0003-manager-rg35xx-media-profile.patch
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

  if grep -q '^--- a/' "$f" \
     && grep -q '^+++ b/' "$f" \
     && grep -Eq '^@@ -[0-9]+(,[0-9]+)? \+[0-9]+(,[0-9]+)? @@' "$f"; then
    EXECUTABLE=$((EXECUTABLE + 1))
    note "EXECUTABLE-DIFF-SHAPE: $p"
  else
    SPEC_ONLY=$((SPEC_ONLY + 1))
    note "SPEC-ONLY/PLACEHOLDER: $p"
  fi
done

[ "$TOTAL" -gt 0 ] || fail "active contract set is empty"
note "summary total=$TOTAL executable-shape=$EXECUTABLE spec-or-placeholder=$SPEC_ONLY"

if [ "$MODE" = "--build-ready" ] && [ "$SPEC_ONLY" -ne 0 ]; then
  fail "$SPEC_ONLY active integration contracts are specification-only or contain placeholder hunks; materialize exact pinned-source diffs/overlays before BUILD-READY"
fi

if [ "$MODE" = "--project-static" ]; then
  note "STATIC CONTRACT INVENTORY PASS — specification/placeholder items remain build blockers by design"
else
  note "BUILD-READY CONTRACT DIFF-SHAPE PASS"
  note "rc1_assemble.sh still performs patch --dry-run against the exact pinned source before mutation"
fi
