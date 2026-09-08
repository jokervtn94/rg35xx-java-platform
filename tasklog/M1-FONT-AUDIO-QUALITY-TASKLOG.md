# M1 Font + Audio Quality Tasklog

Status: SOURCE-PUSHED / BUILD-PASS / DEVICE-TEST-PENDING
Date: 2026-09-08
Scope: RG35XX 320x240 Java ME presentation quality after JamVM L production crash fix.

## Device evidence that opened M1

1. KDTT is now able to run beyond the former JamVM CHECKCAST/SIGSEGV crash after the separate JamVM L production fix.
2. Device screenshot shows readable text but with visibly coarse/blocky fallback raster and uneven spacing on the 320x240 presentation path.
3. Device report says MIDI/audio still has a persistent metallic/ringing hiss ("rit rit").
4. Earlier deployed runtime logs contained a 14700 Hz / mono-x3 path. The authoritative current platform source, however, renders TinySoundFont directly at 44100 Hz stereo and the current mixer already applies 25% master headroom. M1 therefore follows current source truth rather than preserving the older deployed diagnostic description.

## Source ownership checked before modification

- MIDP layout/metrics owner: upstream `PlatformFont` / `PlatformGraphics`.
- RG35XX fallback bitmap raster helper: `src/org/recompile/mobile/RG35XXBitmapText.java`.
- Native MIDI synth owner: `native/rg35xx_tsf_worker.c` with TinySoundFont/TinyMidiLoader.
- Final native mix/headroom owner: `native/rg35xx_mixer.c`.
- No second font engine, second MIDI engine, second libretro entrypoint, or second TML/TSF implementation is introduced.

## M1-A — Font raster refinement

Classification: MODIFY existing helper only.

Source commit:
`117b5a8afe8735f212a94db21b475d344473ca9a`

File:
`src/org/recompile/mobile/RG35XXBitmapText.java`

Changes:

- Keep `Font.stringWidth`, `Font.charWidth`, and `Font.getHeight` as the layout contract.
- Reserve explicit horizontal and vertical bearings instead of stretching the 5x7 fallback seed to nearly the entire metric cell.
- Cap fallback expansion to reduce thick/merged pixel blocks on 320x240 output.
- Keep the existing integer framebuffer scaling path unchanged.
- Add deterministic support for common precomposed Vietnamese Latin characters by mapping them to base Latin glyphs and drawing compact breve/circumflex/horn/crossbar/tone marks inside the existing cell.
- No host font discovery and no new font file is introduced.

Expected result:

- Cleaner separation between adjacent letters.
- Less boxed/underlined appearance after 2x integer scaling.
- Better fallback readability for Vietnamese text when the normal DejaVu/GNU Classpath path is unavailable or bypassed by a JAR.
- No layout width changes because MIDP metrics remain authoritative.

Risk:

- Very small font cells may not have enough vertical pixels to show every Vietnamese mark perfectly.
- This helper remains a fallback renderer; it does not replace the DejaVu/GNU Classpath font path.

Rollback:

Revert commit `117b5a8afe8735f212a94db21b475d344473ca9a` only.

## M1-B — MIDI de-ringing filter

Classification: MODIFY existing TinySoundFont worker only.

Source commit:
`fd8fae8c8f25976449379bff807b7420bebd7e29`

File:
`native/rg35xx_tsf_worker.c`

Current authoritative baseline retained:

- TinySoundFont output: 44100 Hz.
- Stereo interleaved rendering.
- Existing voice limit and MIDI timing unchanged.
- Existing downstream mixer 3/4 master headroom unchanged.

Change:

Add a deliberately mild per-channel one-pole smoothing stage to MIDI output only:

`filtered = (previous_filtered + 7 * current_sample) / 8`

Properties:

- 87.5% of the current sample is preserved each frame.
- State is maintained separately for left/right channels.
- Filter state resets on synth reset, seek/replay, stop/restart loop, and new MIDI open.
- PCM/WAV playback is untouched.
- MIDI event timing, frame position, loop behavior and END_OF_MEDIA behavior are untouched.
- No allocations are added to the render hot path.

Reason:

This is a conservative high-frequency damping step intended to reduce narrow metallic/ringing energy on the RG35XX speaker while keeping the 44.1 kHz direct-render source path. It is intentionally much less invasive than downsampling the synthesizer.

Risk:

- Very bright MIDI instruments may lose a small amount of extreme high-frequency edge.
- If device testing shows the hiss originates downstream of the synthesizer, M1-B may reduce but not eliminate it.

Rollback:

Revert commit `fd8fae8c8f25976449379bff807b7420bebd7e29` only.

## Build contract

Use the existing consolidated workflow:
`.github/workflows/rc1-consolidated-build.yml`

Pinned inputs remain unchanged:

- FreeJ2ME-Plus: `13ec186903087156c145268f8706eecfaf9f1e50`
- GNU Classpath 0.99 SHA-256: `f929297f8ae9b613a1a167e231566861893260651d913ad9b6c11933895fecc8`
- DejaVu Sans 2.37 archive SHA-256: `5c6e497a2f36552cb5ffb112c413a6af39c0f3c47653662b90b4fa6499822fd7`
- GeneralUser-GS source commit: `684543d5e5efaef08d02be50dcda8d552478fa60`
- Miyoo uClibc toolchain image digest: `sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`

## Build evidence — PASS

GitHub Actions workflow:
`RC1 Consolidated ARM Build`

Run ID:
`34206307274`

Built source head:
`fd8fae8c8f25976449379bff807b7420bebd7e29`

The head includes the preceding M1-A font commit `117b5a8afe8735f212a94db21b475d344473ca9a`.

Job ID:
`101996481591`

Result:
`success`

Successful gates:

- pinned external inputs materialized and verified;
- pinned FreeJ2ME/runtime overlays assembled;
- Java artifact compiled;
- ARMv5TE/uClibc core compiled and linked;
- RG35XX undefined-symbol scan passed;
- build evidence artifact uploaded.

GitHub Actions artifact ID:
`10047933171`

Artifact name:
`rg35xx-rc1-consolidated-build-evidence`

Artifact digest:
`sha256:5318cc1e250b60a41797cb60e34a6d63ddf52ee8c8d6dc314ae5956cb6026b49`

Produced binaries from the downloaded build evidence:

- `freej2me_plus-lr.jar` SHA-256: `cae779a1ac2dfd7cd65e8893b30fee8196c1c6107f693c335701fe34fea4d322`
- `freej2me_plus_libretro.so` SHA-256: `f409396d489cd2b1aca3ce43b3c60dba90aae5a0305f9428629c8e1d88a57e87`

Runtime provenance emitted by the build:

- DejaVuSans.ttf target: `/mnt/mmc/Java/runtime/DejaVuSans.ttf`
- DejaVuSans.ttf SHA-256: `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`
- GeneralUser-GS.sf2 target: `/mnt/mmc/Java/runtime/GeneralUser-GS.sf2`
- GeneralUser-GS.sf2 SHA-256: `9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe`
- GeneralUser-GS.sf2 Git blob: `298b552d2e9d1307e03e5c5c99d2c046aaed9ec3`

Compiler review note:

The build completed successfully. Existing non-fatal warnings remain in upstream/project code (for example unused helper and misleading-indentation warnings in mixer setters); no M1 compile or link error occurred. These warnings are not DEVICE-TEST evidence and may be cleaned separately later.

## M1 device acceptance

Font:

- KDTT Vietnamese dialogue remains within the original layout boxes.
- No character-cell merging or long accidental horizontal strokes.
- Vietnamese precomposed fallback glyphs remain recognizable.
- 320x240 -> 640x480 output stays sharp under integer scaling.

Audio:

- MIDI starts/loops/stops normally.
- No regression in PCM/WAV playback.
- Ringing/hiss is audibly reduced relative to the current device build.
- No new underrun/stutter introduced.
- No measurable game-speed regression during normal play.

Stability:

- JamVM L production remains a separate VM-layer requirement; M1 does not modify JamVM.
- Existing KDTT crash fix must remain active on the device while testing M1.

## Result policy

Do not mark M1 DEVICE-TEST-PASS until a real RG35XX run provides:

- screenshot of the same/similar Vietnamese dialogue view;
- FreeJ2ME core log;
- FreeJ2ME Java stderr log;
- user listening result for MIDI ringing;
- confirmation that KDTT can continue playing beyond the former crash point.

If font improves but audio does not, keep M1-A and branch audio into M1-B2. If audio improves but font regresses layout, keep M1-B and revert/refine M1-A independently.
