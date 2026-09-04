# RG35XX Java Platform — RC1-011AJ Tasklog

## RGJ-RC1-011AJ — PlatformImage cache tail pure-insertion rebase
- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0011-platformimage-rg35xx-cache.patch`.
- Trigger: consolidated strict assembly run `33867304566` still rejected hunk #2 of 0011 under `--fuzz=0`, even after reducing it to a one-line context hunk.
- Exact pinned source: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`, `PlatformImage.java`; immutable byte-array constructor final `dataBuffer` assignment is old line 203 and `isMutable = mutable` is old line 204.
- Decision: preserve all image-cache semantics and convert only the cache-store tail to a zero-context pure insertion immediately after old line 203.
- Preserve: PlatformImage remains decoder/facade owner; RG35XXImageCache remains sole immutable decoded-image cache; mutable DoJa images remain ineligible; cache hits reconstruct fresh ARGB canvas from defensive pixels; no second decoder/cache class.
- Gate: keep `patch --fuzz=0`; do not weaken assembly marker checks.
- BUILD-PASS: not claimed. Java/ARM compile and native lifecycle evidence remain mandatory.
