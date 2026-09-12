# VC7R22 — Golden Audio Restore + Hotpath Cleanup

Status: BUILD-GATE-IN-PROGRESS / DEVICE-TEST-PENDING
Date: 2026-09-12

## Device evidence that triggered this checkpoint

Current KDTT/Ninja logs continue producing frames and cleanly deinitialize the native video/core path, but Java stderr contains heavy rendering diagnostics while games appear stalled during loading. The VC7R9 image probe and historical frame transport diagnostics are therefore production hot-path overhead, not required rendering behavior.

## Confirmed hot-path gate defect

VC7R19 removed direct statements matching `System.err.println("RG35XX-...")`, but two diagnostic families bypassed that gate:

1. VC7R9 image sampling builds a `StringBuffer` and prints with `System.err.println(b.toString())`. It samples up to 256 source pixels for BEFORE/AFTER phases across many image operations.
2. `RG35XXGoldenFrameTransport` contains per-request/per-frame `RG35XX-JAVA-DIAG` writes around worker wake, snapshot, RGB565 encoding, IPC header/payload and flush.

VC7R22 disables the VC7R9/VC7R5 sampling helpers and removes frame-transport `RG35XX-JAVA-DIAG` writes while preserving `RG35XX-VIDEO JAVA ... error` diagnostics and stack traces.

## Audio forensic result

The currently rebuildable VC7R3 native audio implementation is not the exact device-proven Golden worker-ring binary. Current source couples output pumping to `retro_run()` and the source-built Actions artifacts have different SHA256 identities from the stable binaries.

Authoritative identities remain:

- Golden reference core: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
- CN short-audio-prime core: `9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40`
- Rejected M1 core: `f409396d489cd2b1aca3ce43b3c60dba90aae5a0305f9428629c8e1d88a57e87`

The CN patch source is preserved at commit `7b7e91516d16a1988bae7bd907bacaecdf2fa972` and changes only the audited MIDI prime instructions from 12288 to 3072. Its source-build Actions artifact is not the device-tested CN binary and must not be substituted.

## VC7R22 release policy

- Preserve VC7R21 Java graphics/transparency behavior.
- Preserve RG35XX Lazy Media startup; do not restore eager `prepareMediaEngine()`, MediaWarmup, or `/dev/snd/seq` startup probing.
- Do not publish the source-built VC7R3 native core as a Golden audio restore.
- VC7R22 CI packages the cleaned Java runtime only until an exact Golden/CN core is recovered by SHA256.
- A future full installer must fail closed unless the audio core is exactly Golden `4ba55a...` or CN `9c248b...` (CN preferred because short playTone priming is fixed).

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
