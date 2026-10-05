# RG35XX R1 install/layout failure — 2026-10-05

Status: NEEDS_REPRO until fixed package is physically rerun.

Physical evidence from original RG35XX:
- P6 launcher executed far enough to create evidence, then failed preflight because `/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime/bin/jamvm` was absent.
- P7 correctly refused to run because P6 programmatic PASS was not present.
- The published P7-ready archive itself contains the exact runtime payload at that sibling path, so this is not a runtime semantic/build failure.

Failure owner:
- `INSTALL_LAYOUT_BOUNDARY`

Not owners:
- canonical FreeJ2ME semantics
- RG35XX graphics/input/audio boundaries
- JamVM byte identity
- P1/P2/P3 accepted platform bytes

Minimum required delta:
- package a second exact-hash runtime source under the main `FreeJ2ME-RG35XX` app directory;
- add a small bootstrap that, only when the compiled runtime prefix is missing or hash-invalid, copies this exact source to `/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime`;
- invoke that bootstrap from the generic launcher, P6 test launcher, and P7 launcher before runtime/hash gates;
- do not rebuild or patch JamVM/glibj/platform/native binaries.

Acceptance:
- bootstrap reports PASS and exact JamVM/glibj/classes hashes;
- P6 can proceed past runtime preflight on original RG35XX;
- then P7 remains gated on P6 as before.

DEVICE_PASS=NO
STABLE=NO
