# RG35XX Audio Boundary R2 Physical Result — MIDI Lifecycle Next Gate

Date: 2026-10-05
Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Physical observation

User observation on original RG35XX:

```text
A_COMPLEX_FORMAT1_AUDIBLE=PASS
B1_INITIAL_BGM_AUDIBLE=FAIL
B2_HIGH_FX_AUDIBLE=FAIL
B3_BGM_RETURN_AUDIBLE=FAIL
```

## Programmatic evidence

The R2 diagnostic identity gate and A1P5 prime passed. Complex format-1 MIDI loaded and played with audible output. After A was stopped/deallocated/closed, B1 loaded and `sdlMixerPlayMusic` returned PASS but was physically silent. B2 and B3 also reached `sdlMixerPlayMusic` PASS and remained physically silent. JVM exit and audio shutdown were normal.

Therefore:

```text
SDL1_COMPLEX_FORMAT1_MIDI_CAPABILITY=PASS_ON_DEVICE
JAVA_START_SKIPPED_AS_PRIMARY_OWNER=NO
FIRST_MIDI_AFTER_AUDIO_INIT=AUDIBLE
SUBSEQUENT_MIDI_AFTER_PRIOR_PLAYER_TEARDOWN=SILENT
MIX_PLAYMUSIC_RETURN_ZERO_DOES_NOT_PROVE_AUDIBLE=YES
```

This is stronger than the earlier multi-Player hypothesis: B1 is already silent before B2/B3 switching can be the cause.

## Current owner classification

```text
PRIMARY_OWNER_CLASS=RG35XX_SDL1_MIXER_MIDI_LIFECYCLE_BOUNDARY
SPECIFIC_TRANSITION=NEEDS_ISOLATION
CANDIDATES:
  SAME_PLAYER_PAUSE_RESUME
  HALT_FREE_RELOAD
  SECOND_PRELOADED_PLAYER_AFTER_FIRST_FREE
```

No production edit is authorized yet. `PlatformPlayer`, MMAPI, and game JAR remain unchanged.

## Next diagnostic

Use one identical generated noncommercial format-0 MIDI tone and run each case in a fresh JVM:

- C0: first playback only.
- C1: same Player stop/start.
- C2: deallocate/free then create/load/start a new Player.
- C3: preload two Players, play/free the first, then start the second.

Package: `RG35XX-MIDI-LIFECYCLE-DIAG.zip`

CI:

```text
RUN=37282609620
JOB=111673938897
ARTIFACT_ID=11332484689
SOURCE_COMMIT=97955f1db24f502378722bc9a65df006a0d497d1
MIDI_LIFE_INDEPENDENT_GATE=PASS
MIDI_LIFE_JAVA6_GATE=PASS
MIDI_LIFE_SAME_FIXTURE_GATE=PASS
MIDI_LIFE_FRESH_JVM_CASE_GATE=PASS
MIDI_LIFE_PRODUCTION_BINARY_DELTA=NONE
MIDI_LIFE_GAME_SPECIFIC_CODE=NO
```

## Status

```text
P6_PHYSICAL_ACCEPTANCE=PASS
P7_PHYSICAL_REGRESSION=FAIL:GOW_AUDIBLE_AUDIO_CONTINUITY
P8_PLATFORM_BASELINE_PROMOTION=BLOCKED
DEVICE_PASS=NO
STABLE=NO
```
