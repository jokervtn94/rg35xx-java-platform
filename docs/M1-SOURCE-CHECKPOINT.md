# RG35XX Java Platform M1 — Authoritative Source Checkpoint

Date: 2026-09-08
Status: SOURCE-PUSHED / BUILD-PASS / DEVICE-TEST-PENDING

This checkpoint records the exact source boundary for the first post-crash-fix presentation-quality pass.

## Required VM baseline

M1 does not modify JamVM. Device testing must use the separate JamVM L production build carrying the direct-interpreter ALOAD_0/GETFIELD correctness fix.

## M1 source commits

Font raster refinement:

`117b5a8afe8735f212a94db21b475d344473ca9a`

MIDI de-ringing filter:

`fd8fae8c8f25976449379bff807b7420bebd7e29`

Tasklog build-evidence update:

`dec6633bf6999ce79d0d6c33856483fc16490864`

Tasklog:

`tasklog/M1-FONT-AUDIO-QUALITY-TASKLOG.md`

## Authoritative modified files

- `src/org/recompile/mobile/RG35XXBitmapText.java`
- `native/rg35xx_tsf_worker.c`

No other source owner is replaced by M1.

## Preserved owners

- MIDP font metrics/layout remain owned by upstream PlatformFont/PlatformGraphics.
- GNU Classpath/DejaVu remains the authoritative normal font backend.
- RG35XXBitmapText remains fallback-only.
- TinySoundFont/TinyMidiLoader remains the sole MIDI synthesis implementation.
- `rg35xx_mixer.c` remains the final mix/headroom owner.
- `freej2me_libretro.c` remains the sole libretro core entrypoint.

## Audio baseline locked by source

TinySoundFont render rate: 44100 Hz.
Output: stereo interleaved.
M1 filter: `(previous + 7 * current) / 8` independently on L/R MIDI samples.
PCM/WAV path: unchanged.
Final mixer headroom: unchanged at 3/4.

## Font baseline locked by source

- Layout widths/heights come from the active MIDP Font metrics.
- Fallback glyph raster has explicit bearings and capped 5x7 expansion.
- Common precomposed Vietnamese characters receive deterministic base/diacritic fallback rendering.
- No host font lookup is allowed.

## Build source pins

The existing RC1 consolidated workflow retains its pinned inputs and toolchain. M1 does not change those pins.

## Accepted M1 build identity

Workflow: `RC1 Consolidated ARM Build`

Run ID: `34206307274`

Build source head: `fd8fae8c8f25976449379bff807b7420bebd7e29`

Job ID: `101996481591`

Result: `success`

Artifact ID: `10047933171`

Artifact name: `rg35xx-rc1-consolidated-build-evidence`

Artifact digest: `sha256:5318cc1e250b60a41797cb60e34a6d63ddf52ee8c8d6dc314ae5956cb6026b49`

Produced payload SHA-256:

- `freej2me_plus-lr.jar`: `cae779a1ac2dfd7cd65e8893b30fee8196c1c6107f693c335701fe34fea4d322`
- `freej2me_plus_libretro.so`: `f409396d489cd2b1aca3ce43b3c60dba90aae5a0305f9428629c8e1d88a57e87`

Runtime assets remain the pinned RC1 identities:

- DejaVuSans.ttf: `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`
- GeneralUser-GS.sf2: `9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe`

## Acceptance state

BUILD-PASS means the pinned assembly, Java compile, ARMv5TE/uClibc compile/link and undefined-symbol scan completed successfully. It does not mean the font/audio changes are validated on hardware.

This file MUST NOT be treated as DEVICE-TEST-PASS until the device evidence required by `tasklog/M1-FONT-AUDIO-QUALITY-TASKLOG.md` is attached/reported.

If later changes are made, create a new checkpoint (M1.1/M2 etc.) rather than silently rewriting the historical meaning of M1.
