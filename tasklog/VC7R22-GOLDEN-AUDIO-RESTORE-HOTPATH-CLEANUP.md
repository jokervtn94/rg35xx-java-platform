# VC7R22 — Golden Audio Restore + Hotpath Cleanup

Status: CI-PASS / DEVICE-TEST-PENDING
Date: 2026-09-12

## Device evidence that triggered this checkpoint

Current KDTT/Ninja logs continue producing frames and cleanly deinitialize the native video/core path, but Java stderr contains heavy rendering diagnostics while games appear stalled during loading. The VC7R9 image probe and historical frame transport diagnostics are therefore production hot-path overhead, not required rendering behavior.

## Confirmed hot-path gate defect

VC7R19 removed direct statements matching `System.err.println("RG35XX-...")`, but diagnostic families bypassed that gate:

1. VC7R9 image sampling builds a `StringBuffer` and prints with `System.err.println(b.toString())` while sampling source pixels around image operations.
2. VC7R13 fullscreen composition probe samples up to 512 pixels, builds a stack trace/StringBuffer, and writes stderr on qualifying full-screen blits.
3. `RG35XXGoldenFrameTransport` historically contained per-request/per-frame `RG35XX-JAVA-DIAG` writes around worker wake, snapshot, RGB565 encoding, IPC header/payload and flush.
4. VC7R5 frame color sampling also used StringBuffer-based stderr diagnostics.

VC7R22 now replaces VC7R9, VC7R13 and VC7R5 diagnostic helper bodies with production no-ops, removes executable frame-transport `RG35XX-JAVA-DIAG` writes, and preserves `RG35XX-VIDEO JAVA ... error` diagnostics and stack traces.

## CI result

GitHub Actions run `34695957733` for commit `dfc48d971725c3aeca90730e08e44eabac2c98f0` passed all build and artifact gates.

Confirmed markers:

- `VC7R22_HOTPATH_CLEANUP=PASS`
- `FRAME_JAVA_DIAG_EXECUTABLE_SURVIVORS=0`
- `VC7R9_IMAGE_SAMPLER=NOOP`
- `VC7R13_FULLSCREEN_SAMPLER=NOOP`
- `VC7R5_COLOR_SAMPLER=NOOP_OR_ABSENT`
- `ERROR_DIAGNOSTICS=PRESERVED`
- `VC7R22_BUILD=PASS`
- `VC7R22_CORE_PACKAGED=NO`
- `VC7R22_ARTIFACT_POLICY_GATE=PASS`

Uploaded artifact:

- name: `rg35xx-vc7r22-hotpath-clean-runtime`
- artifact id: `10298303783`
- archive SHA256: `6ca07e1ace086e767c40f0c7d618762b56417dcb066e7329e83922518ac983d4`

Artifact audit contents:

- `freej2me-lr-vc7r22.jar`
- `VC7R22-FONT-MANIFEST.json`
- `STATUS.txt`
- `CORE-POLICY.txt`
- `SHA256SUMS.txt`

Audited JAR SHA256:

- `cb8926539749535a53cb4a627e814e198aaa0eba3cce8cac1bb213957e37189b`

No `.so` file is present in the artifact. This is intentional and confirms that VC7R22 did not silently substitute the source-built VC7R3 audio core.

## Audio forensic result

The currently rebuildable VC7R3 native audio implementation is not the exact device-proven Golden worker-ring binary. Current source couples output pumping to `retro_run()` and the source-built Actions artifacts have different SHA256 identities from the stable binaries.

Authoritative identities remain:

- Golden reference core: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
- CN short-audio-prime core: `9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40`
- Rejected M1 core: `f409396d489cd2b1aca3ce43b3c60dba90aae5a0305f9428629c8e1d88a57e87`

The CN patch source is preserved at commit `7b7e91516d16a1988bae7bd907bacaecdf2fa972` and changes only the audited MIDI prime instructions from 12288 to 3072. Its source-build Actions artifact is not the device-tested CN binary and must not be substituted.

## VC7R22 fail-closed worker-ring recovery

A recovery installer source is now preserved at `scripts/vc7r22_recover_worker_ring_from_sd.ps1` (commit `307cead620f31cadcd9f89036b5c217863980f0c`).

The installer does not contain or invent a replacement native core. It scans the SD card and existing recovery/backup trees for exact SHA256 identities:

- exact CN core `9c248b0b...` → use directly;
- exact Golden core `4ba55aea...` → apply only the three audited CN prime instructions and require the result to hash exactly to CN `9c248b0b...`;
- anything else → fail closed with no unknown core installed.

Before writing, the installer backs up current core/runtime targets. It then installs the CI-audited VC7R22 Java runtime (`cb892653...`) together with the exact CN native core and verifies every installed SHA.

This closes the gap between "we know the Golden/CN binary contract" and "we can safely recover it from historical SD backups" without treating a source-rebuilt frame-coupled core as equivalent.

## VC7R22 release policy

- Preserve VC7R21 Java graphics/transparency behavior.
- Preserve RG35XX Lazy Media startup; do not restore eager `prepareMediaEngine()`, MediaWarmup, or `/dev/snd/seq` startup probing.
- Do not publish the source-built VC7R3 native core as a Golden audio restore.
- VC7R22 CI packages the cleaned Java runtime only until an exact Golden/CN core is recovered by SHA256.
- A full installer must fail closed unless the audio core is exactly Golden `4ba55a...` or CN `9c248b...` (CN preferred because short playTone priming is fixed).

## Golden audio contract to preserve once exact binary is recovered

- asynchronous libretro audio callback
- dedicated audio worker
- ring buffer: 16384 frames
- MIDI prime: 3072 frames for CN
- worker chunk: 1470
- SoundFont synth: 14700 Hz
- output: 44100 Hz, mono-x3 staging
- PCM prime approximately 2940 with underrun re-prime
- native END_OF_MEDIA and BGM resume
- audio lifecycle independent from game frame cadence

## Device acceptance (not yet claimed)

1. KDTT and Ninja reach menus without apparent loading stall.
2. `playTone`, MIDI, PCM and ToneControl are audible.
3. Native END_OF_MEDIA/BGM resume works.
4. `freej2me-core.log` shows Golden worker/ring markers.
5. No JavaSound `getSequencer` failure.
6. No eager MediaWarmup or `/dev/snd/seq` startup probe.
7. VC7R21 transparency, RGB565, dynamic resolution and Smart-Fit remain intact.

Do not mark STABLE or DEVICE-TEST-PASS before hardware evidence.
