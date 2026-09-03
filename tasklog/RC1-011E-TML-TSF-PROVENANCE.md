# RGJ-RC1-011E — TML/TSF Provenance Reconciliation

Status: STATIC-AUDIT-PASS. BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Action: MODIFY / ADD / AUDIT.

Mandatory reload completed before mutation: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current dependency gate/verifier, and the exact upstream TinySoundFont Git tree at the pinned commit.

## Source pin

`schellingb/TinySoundFont@853a0a171759f1ddba0de1442133a75912bbeffa`.

## Reconciliation

The first `native/verify_tinysoundfont_vendor.sh` recorded provisional expected blob identities that did not match the authoritative upstream Git tree at the pin. They are explicitly superseded here; do not restore them.

Authoritative file identities:

- `tml.h` -> `333287377fa860fa7f3d8fe8096d3cf32bfbb6ea`
- `tsf.h` -> `a81f25d5ca2e210720d646dec2dbfaeb119acb09`

The verifier was corrected to these IDs.

## Acquisition contract

Added `native/vendor_tinysoundfont.sh`. It fetches only the exact pinned commit, validates source object IDs before output, writes sibling temporary files, validates written Git blob identities, atomically moves them into `native/vendor/TinySoundFont/`, then runs the offline verifier.

Normal build logic must not download dependencies. The physical vendored headers remain an assembled-source input gate until materialized and verified.

## Ownership

No MIDI/parser/synth ownership changed. `rg35xx_tsf_impl.c` remains the sole TML/TSF implementation translation unit and `rg35xx_tsf_worker.c` remains behind the existing MIDI adapter.

SoundFont ownership is not resolved by this task and no example SF2 is promoted.

Audit: `docs/RC1-TML-TSF-PROVENANCE-AUDIT.md`.

Gate result: STATIC-AUDIT-PASS for provenance/acquisition/integrity policy only.