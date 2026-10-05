# RG35XX R4 Frontend A/B with A8 Launcher — Physical Result

Date: 2026-10-05
Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Scope

Diagnostic only. The R4 candidate runtime, MMAPI classes, native audio, video, input, audio-prime PCM, and God of War input were preserved. Only the four `RG35XXLauncher*` classes were replaced with the exact A8 Golden class bytes.

## Physical result

User observation on original RG35XX: menu audio is present, but audio is still cut when entering gameplay.

The diagnostic log records:

- `IDENTITY_GATE=PASS`
- `AUDIO_ROUTE_PRIME=PASS`
- `REAL_GAME_PROCESS=START`
- SDL1_mixer backend initialization PASS
- repeated MIDI load/play PASS markers through gameplay
- one ALSA underrun marker
- normal runtime exit / programmatic launch PASS

Physical audible continuity nevertheless failed. Automated MIDI/API PASS is not accepted as audible audio PASS.

## Byte-level comparison after the result

The following R4 classes are already byte-for-byte identical to A8 Golden:

- `org/recompile/mobile/PlatformPlayer.class`
- `org/recompile/mobile/SdlMixerManager.class`
- `org/recompile/mobile/PlatformPlayer$sdlPlayer.class`
- `org/recompile/mobile/PlatformPlayer$audioplayer.class`
- `org/recompile/mobile/PlatformPlayer$midiControl.class`
- `javax/microedition/media/Manager.class`

`libaudio.so` is also byte-identical to A8 Golden:

`4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`

A1P5 prime PCM is byte-identical to A8 Golden:

`8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e`

## Classification

`A8_LAUNCHER_FAMILY=ELIMINATED_AS_PRIMARY_OWNER`

`MMAPI_PLATFORMPLAYER_FAMILY=ELIMINATED_AS_PRIMARY_OWNER_BY_IDENTITY`

`NATIVE_AUDIO_BINARY=ELIMINATED_AS_PRIMARY_OWNER_BY_IDENTITY`

This does not prove that the physical audio path is healthy; it proves that changing those already-Golden byte families is not justified by current evidence.

The remaining meaningful boundary is between:

1. post-A8 platform/input differences, and
2. the R4 candidate runtime/process environment.

## Next diagnostic

Run one reconstruction A/B using the exact A8 platform payload (exact A8 platform JAR + input/video/audio native + prime) on the unchanged R4 candidate runtime. This is diagnostic-only and does not mutate `/mnt/mmc/CFW/java` or production R4.

Interpretation:

- audible gameplay returns -> failure is in post-A8 platform/input lineage;
- gameplay remains silent -> post-A8 platform lineage is eliminated and the candidate runtime/process boundary becomes the remaining primary owner class.

## Status

`P6_PHYSICAL_ACCEPTANCE=PASS`

`P7_PHYSICAL_REGRESSION=FAIL:GOW_AUDIBLE_AUDIO_CONTINUITY`

`DEVICE_PASS=NO`

`STABLE=NO`
