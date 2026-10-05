# RG35XX R4 Frontend A/B with Exact Golden Launcher Classes — Physical Result

Date: 2026-10-05
Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Scope and authority correction

Diagnostic only. The R4 candidate runtime, MMAPI classes, native audio, video, input, audio-prime PCM, and God of War input were preserved. Only the four `RG35XXLauncher*` classes were replaced from a locally retained A8 control JAR whose raw JAR SHA256 is:

`f65208e49b16a0ff275b0013ef748e216551096a068b84942da17d403c972b12`

The protected device-accepted platform JAR raw identity is:

`057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c`

The raw JAR hashes differ, so the `f652...` JAR itself must not be relabeled as the protected raw artifact. However, after recovering the protected `057567...` artifact from historical CI, both JARs were extracted and compared entry-by-entry. Result:

`F652_VS_057_EXTRACTED_ENTRY_DIFF_COUNT=0`

Therefore all four launcher class bytes used by this A/B are now independently verified byte-identical to the exact protected device-accepted `057567...` Golden classes. The launcher-family conclusion below is authoritative even though the source archive raw SHA differed.

## Physical result

User observation on original RG35XX: menu audio is present, but audio is still cut when entering gameplay.

The diagnostic log records:

- `IDENTITY_GATE=PASS` for the diagnostic package;
- `AUDIO_ROUTE_PRIME=PASS`;
- `REAL_GAME_PROCESS=START`;
- SDL1_mixer backend initialization PASS;
- repeated MIDI load/play PASS markers through gameplay;
- one ALSA underrun marker;
- normal runtime exit / programmatic launch PASS.

Physical audible continuity nevertheless failed. Automated MIDI/API PASS is not accepted as audible audio PASS.

## Exact Golden byte comparisons after recovery

The following R4 audio/MMAPI classes are byte-for-byte identical to the protected exact `057567...` platform JAR:

- `org/recompile/mobile/PlatformPlayer.class`
- `org/recompile/mobile/SdlMixerManager.class`
- `org/recompile/mobile/PlatformPlayer$sdlPlayer.class`
- `org/recompile/mobile/PlatformPlayer$audioplayer.class`
- `org/recompile/mobile/PlatformPlayer$midiControl.class`
- `javax/microedition/media/Manager.class`

`libaudio.so` is byte-identical to protected Golden:

`4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`

A1P5 prime PCM is byte-identical to protected Golden:

`8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e`

Exact `057567...` versus R4 platform JAR entry comparison has nine differing entries:

- `org/recompile/mobile/PlatformGraphics.class`
- `org/recompile/rg35xx/RG35XXCore2D$RawImage.class`
- `org/recompile/rg35xx/RG35XXCore2D.class`
- `org/recompile/rg35xx/RG35XXFrontendPolicy.class` (R4 addition)
- `org/recompile/rg35xx/RG35XXKeyDispatcher.class`
- four `RG35XXLauncher*` classes

The four launcher classes are already physically A/B-tested and did not restore audible gameplay audio.

## Classification

`PROTECTED_GOLDEN_LAUNCHER_FAMILY=ELIMINATED_AS_PRIMARY_OWNER`

`PROTECTED_GOLDEN_MMAPI_AUDIO_CLASS_FAMILY=ELIMINATED_AS_PRIMARY_OWNER_BY_BYTE_IDENTITY`

`PROTECTED_GOLDEN_NATIVE_AUDIO_BINARY=ELIMINATED_AS_PRIMARY_OWNER_BY_BYTE_IDENTITY`

`PROTECTED_057_FULL_PLATFORM_BOUNDARY=NOT_YET_DIFFERENTIALLY_TESTED`

`RUNTIME_FAILURE_OWNER=NOT_YET_PROVEN`

No launcher/MMAPI/native-audio rewrite is justified by current evidence.

## Exact protected Golden provenance

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

Run one self-contained diagnostic using the exact protected device-accepted platform JAR + input/video/audio native + protected A1P5 prime on the unchanged R4 candidate JamVM/glibj.

No `/mnt/mmc/CFW/java` mutation and no production R4 replacement are permitted.

Interpretation:

- audible gameplay returns -> failure owner is narrowed to the remaining post-Golden platform/input lineage (the non-audio platform differences and/or R4 input boundary);
- gameplay remains silent -> the exact protected platform/input/video/audio/prime boundary is eliminated as the primary cause under the R4 candidate runtime, and the remaining primary owner class becomes the R4 candidate runtime/process-environment boundary.

## Status

`P6_PHYSICAL_ACCEPTANCE=PASS`

`P7_PHYSICAL_REGRESSION=FAIL:GOW_AUDIBLE_AUDIO_CONTINUITY`

`PROTECTED_GOLDEN_LAUNCHER_AB=FAIL:GAMEPLAY_AUDIO_STILL_CUT`

`PROTECTED_057_FULL_PLATFORM_AB=READY_NOT_TESTED`

`DEVICE_PASS=NO`

`STABLE=NO`
