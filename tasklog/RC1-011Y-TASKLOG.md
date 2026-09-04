# RG35XX Java Platform — RC1 011Y Tasklog

This file extends the immutable RC1 engineering record.

## RGJ-RC1-011Y — TinySoundFont acquisition execution + failure-evidence hardening
- Action: MODIFY
- Status: IMPLEMENTED
- Trigger: consolidated build run `33862955201` failed in external-input materialization before assembly.
- First blocker: `native/vendor_tinysoundfont.sh` invoked `native/verify_tinysoundfont_vendor.sh` directly, but the checked-out verifier did not carry an executable bit on the GitHub runner, producing exit code 126 / permission denied.
- Correction: invoke the verifier explicitly through `sh`, preserving its existing exact pin/blob checks and avoiding dependence on repository executable-mode metadata.
- Secondary workflow defect: the `if: always()` evidence step referenced `$EXT_ROOT` under `set -u` even when the materialization step failed before exporting `EXT_ROOT` to `GITHUB_ENV`; this hid useful failure evidence behind a second error.
- Correction: guard optional evidence paths with `${EXT_ROOT:-}` before dereferencing them.
- Scope boundary: no platform class, native module, protocol, build pin, toolchain carrier, or lifecycle behavior changes. This is build-harness robustness only.
- Acceptance: next consolidated workflow run must pass TinySoundFont acquisition/verification and retain a non-failing evidence step even if a later stage fails.
- BUILD-PASS remains unclaimed until consolidated Java + ARMv5TE/uClibc compile/link completes and output is reviewed.
