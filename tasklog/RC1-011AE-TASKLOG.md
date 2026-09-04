# RG35XX Java Platform — RC1-011AE PlatformGraphics transform patch zero-fuzz rebase

## Trigger
Consolidated run `33865244720` passed 0003 after the 011AD rebase, then strict assembly stopped at `0008-platformgraphics-transform-cache.patch`: hunk #1 failed with `--fuzz=0`, while hunk #2 still matched. The exact pinned FreeJ2ME `PlatformGraphics.java` still contains the intended transform block and the locked DoJa-FLIP to MIDP-Sprite mapping remains valid.

## Governance reload
Before mutation, reloaded `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current `scripts/rc1_assemble.sh`, current patch 0008, preceding patch 0007, and exact pinned upstream `PlatformGraphics.java` around the transform call site.

## Decision
- Action: MODIFY `patches/0008-platformgraphics-transform-cache.patch` context only.
- Preserve the exact locked mapping:
  - FLIP_HORIZONTAL -> TRANS_MIRROR
  - FLIP_VERTICAL -> TRANS_MIRROR_ROT180
  - FLIP_ROTATE -> TRANS_ROT180
  - FLIP_ROTATE_LEFT -> TRANS_ROT270
  - FLIP_ROTATE_RIGHT -> TRANS_ROT90
  - FLIP_ROTATE_RIGHT_HORIZONTAL -> TRANS_MIRROR_ROT270
  - FLIP_ROTATE_RIGHT_VERTICAL -> TRANS_MIRROR_ROT90
  - default -> TRANS_NONE
- Preserve geometry-only `RG35XXTransformCache`; mutable image pixels remain uncached.
- Rebase hunk #1 with narrower exact-source context so zero-fuzz assembly does not depend on unrelated surrounding lines.

## Acceptance
1. 0008 applies with `--fuzz=0` after 0007 in authoritative assembly order.
2. Per-pixel transform switch is replaced by cached source-index lookup exactly once.
3. No new graphics owner/cache class is introduced.
4. BUILD-PASS and DEVICE-TEST-PASS remain unclaimed until strict assembly plus Java/native build and device validation pass.
