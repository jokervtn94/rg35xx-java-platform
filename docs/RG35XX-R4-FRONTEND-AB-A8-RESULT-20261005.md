# RG35XX R4 Frontend A/B with A8 Control Launcher — Physical Result

Date: 2026-10-05
Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Scope correction

Diagnostic only. The R4 candidate runtime, MMAPI classes, native audio, video, input, audio-prime PCM, and God of War input were preserved. Only the four `RG35XXLauncher*` classes were replaced from the locally retained A8 control package whose platform JAR raw SHA256 is:

`f65208e49b16a0ff275b0013ef748e216551096a068b84942da17d403c972b12`

That control package is **not** the protected exact device-accepted A7/A8 platform JAR. The protected exact platform identity is:

`057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c`

Therefore this result is valid only as an A/B against the `f652...` control launcher family. It must not be cited as a full canonical A8 platform differential.

## Physical result

User observation on original RG35XX: menu audio is present, but audio is still cut when entering gameplay.

The diagnostic log records:

- `IDENTITY_GATE=PASS` for the diagnostic package it declared;
- `AUDIO_ROUTE_PRIME=PASS`;
- `REAL_GAME_PROCESS=START`;
- SDL1_mixer backend initialization PASS;
- repeated MIDI load/play PASS markers through gameplay;
- one ALSA underrun marker;
- normal runtime exit / programmatic launch PASS.

Physical audible continuity nevertheless failed. Automated MIDI/API PASS is not accepted as audible audio PASS.

## Byte-level comparison against the f652 control package

The following R4 classes were byte-for-byte identical to the `f652...` A8 control package:

- `org/recompile/mobile/PlatformPlayer.class`
- `org/recompile/mobile/SdlMixerManager.class`
- `org/recompile/mobile/PlatformPlayer$sdlPlayer.class`
- `org/recompile/mobile/PlatformPlayer$audioplayer.class`
- `org/recompile/mobile/PlatformPlayer$midiControl.class`
- `javax/microedition/media/Manager.class`

`libaudio.so` is also byte-identical and matches the protected audio hash:

`4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`

A1P5 prime PCM also matches the protected hash:

`8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e`

## Classification

`F652_CONTROL_LAUNCHER_FAMILY=ELIMINATED_AS_PRIMARY_OWNER`

`PROTECTED_057_PLATFORM_FAMILY=NOT_YET_DIFFERENTIALLY_TESTED`

`RUNTIME_FAILURE_OWNER=NOT_PROVEN`

The failed launcher substitution does not justify changing launcher code. It also does not yet eliminate the protected exact platform family because the source JAR for those four substituted classes was not the protected `057567...` raw JAR.

## Exact protected Golden provenance recovered

Historical device-accepted A7 artifact:

```text
RUN_ID=36079435727
ARTIFACT_ID=10841810644
HEAD_SHA=5b7a8e88bd32a735a1342715e718eecf8cf10fad
PLATFORM_JAR_SHA256=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

These exact bytes are the authoritative control for the next A/B.

## Next diagnostic

Run one self-contained diagnostic using the exact protected device-accepted A7 platform JAR + input/video/audio native + protected A1P5 prime on the unchanged R4 candidate JamVM/glibj.

No `/mnt/mmc/CFW/java` mutation and no production R4 replacement are permitted.

Interpretation:

- audible gameplay returns -> failure owner is in the post-A7 platform/input lineage carried by R4;
- gameplay remains silent -> protected platform/input/audio bytes are eliminated as the primary cause under the R4 candidate runtime, and the remaining primary owner class moves to the runtime/process environment boundary.

## Status

`P6_PHYSICAL_ACCEPTANCE=PASS`

`P7_PHYSICAL_REGRESSION=FAIL:GOW_AUDIBLE_AUDIO_CONTINUITY`

`F652_CONTROL_FRONTEND_AB=FAIL:GAMEPLAY_AUDIO_STILL_CUT`

`PROTECTED_057_PLATFORM_AB=READY_NOT_TESTED`

`DEVICE_PASS=NO`

`STABLE=NO`
