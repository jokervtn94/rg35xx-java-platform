# RG35XX Java Platform — RC1 011X Tasklog

This file extends the immutable RC1 engineering record.

## RGJ-RC1-011X — TinySoundFont/TinyMidiLoader materialization before build-ready gate
- Action: MODIFY (build workflow only)
- Status: IMPLEMENTED
- Trigger: consolidated build run `33862703969` passed toolchain materialization and all other external-input acquisition, then failed in `rc1_prebuild_gate.sh --build-ready` because `native/vendor/TinySoundFont/tml.h` and `tsf.h` were not materialized.
- Existing owner: `native/vendor_tinysoundfont.sh`; no new vendoring implementation or native module is introduced.
- Exact source pin remains `schellingb/TinySoundFont@853a0a171759f1ddba0de1442133a75912bbeffa`.
- Required blobs remain `tml.h=333287377fa860fa7f3d8fe8096d3cf32bfbb6ea` and `tsf.h=a81f25d5ca2e210720d646dec2dbfaeb119acb09`.
- Fix: consolidated workflow must run `sh native/vendor_tinysoundfont.sh` during external-input materialization and then run `sh native/verify_tinysoundfont_vendor.sh` before assembly.
- Boundary: this only closes the missing external-input materialization blocker. It does not claim BUILD-PASS.
