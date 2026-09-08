# RG35XX Java Platform M1 — Authoritative Source Checkpoint

Date: 2026-09-08
Status: SOURCE-PUSHED / BUILD-PENDING / DEVICE-TEST-PENDING

This checkpoint records the exact source boundary for the first post-crash-fix presentation-quality pass.

## Required VM baseline

M1 does not modify JamVM. Device testing must use the separate JamVM L production build carrying the direct-interpreter ALOAD_0/GETFIELD correctness fix.

## M1 source commits

Font raster refinement:

`117b5a8afe8735f212a94db21b475d344473ca9a`

MIDI de-ringing filter:

`fd8fae8c8f25976449379bff807b7420bebd7e29`

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

## Acceptance state

This file MUST NOT be treated as DEVICE-TEST-PASS until the device evidence required by `tasklog/M1-FONT-AUDIO-QUALITY-TASKLOG.md` is attached/reported.

If later changes are made, create a new checkpoint (M1.1/M2 etc.) rather than silently rewriting the historical meaning of M1.
