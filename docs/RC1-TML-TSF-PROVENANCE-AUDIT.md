# RC1 TinyMidiLoader / TinySoundFont Provenance Reconciliation

Status: STATIC-AUDIT-PASS. BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Task: RGJ-RC1-011E.

## Scope

Reconcile the third-party native MIDI dependency pin before consolidated source assembly, with no change to MIDI worker semantics or backend ownership.

Upstream pin: `schellingb/TinySoundFont@853a0a171759f1ddba0de1442133a75912bbeffa`.

## Finding

The first RC1 vendor verification helper contained provisional blob identities that do not match the authoritative Git tree at the pinned commit.

Authoritative tree entries at the pin are:

- `tml.h`: Git blob `333287377fa860fa7f3d8fe8096d3cf32bfbb6ea`, 20,463 bytes.
- `tsf.h`: Git blob `a81f25d5ca2e210720d646dec2dbfaeb119acb09`, 92,719 bytes.

The pinned headers identify themselves as TinyMidiLoader v0.7 and TinySoundFont v0.9 respectively. The repository tree also contains the TinySoundFont license and examples, but example SoundFont files are not accepted as the RG35XX platform SoundFont merely because they are upstream examples.

## Correction

`native/verify_tinysoundfont_vendor.sh` now verifies the two authoritative Git blob identities above.

`native/vendor_tinysoundfont.sh` was added as a deterministic acquisition helper. It fetches only the exact commit, verifies the source tree object IDs before writing, verifies the resulting local files again, then invokes the offline verifier.

The acquisition helper is intentionally separate from normal build logic. Release/native builds must be able to run offline after source assembly and must fail if the exact vendored files are absent or modified.

## Ownership invariant

This reconciliation does not add another synthesizer or parser. `native/rg35xx_tsf_impl.c` remains the only implementation translation unit and `native/rg35xx_tsf_worker.c` remains the replacement worker behind the existing MIDI adapter.

## Remaining gate

The actual vendored files must still be materialized in `native/vendor/TinySoundFont/` as part of reproducible source assembly and pass the verifier. The authoritative SoundFont asset/provider also remains unresolved. Neither condition is inferred from the dependency repository.

Gate result: STATIC-AUDIT-PASS for dependency identity, acquisition policy and offline verification contract only.