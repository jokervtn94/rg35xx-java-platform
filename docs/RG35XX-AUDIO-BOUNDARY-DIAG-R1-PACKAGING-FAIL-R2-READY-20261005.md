# RG35XX Audio Boundary Diagnostic R1 Packaging Failure / R2 Ready

Date: 2026-10-05
Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Physical evidence

The first diagnostic launcher did not reach the Java audio test. Device log:

```text
AUDIO_DIAG_LAUNCH=FAIL:BOOTSTRAP_MISSING
```

Classification:

```text
FAILURE_OWNER=DIAGNOSTIC_PACKAGING_BOUNDARY
AUDIO_TEST_EXECUTED=NO
PLATFORM_AUDIO_FAILURE_INFERRED=NO
RUNTIME_FAILURE_INFERRED=NO
```

The R1 overlay contained only the diagnostic JAR and launcher but the launcher required the external `RG35XX-R1-RUNTIME-BOOTSTRAP.sh`. Therefore the diagnostic package contract was incomplete.

## Minimum delta

R2 preserves the exact diagnostic JAR and synthetic MIDI fixtures byte-for-byte and changes only the launcher packaging boundary:

```text
PARENT_DIAGNOSTIC_ZIP_SHA256=75a6085729f282918bf9b7c43eb8b5d067862322648282063edd2773c5e5c8dc
DIAGNOSTIC_JAR_SHA256=8600a6aaeb5782486a55570e54f11e67cf9edcc2d5233329fdf2b5177d9e0f09
DIAGNOSTIC_SEMANTIC_DELTA=NONE
PACKAGING_DELTA=DIRECT_R4_LAUNCH_ONLY
```

R2 launcher:

1. hash-gates the already installed exact R4 runtime/platform/native payload;
2. runs the exact A1P5 zero-PCM prime directly with `aplay`;
3. exports `SDL_AUDIODRIVER=alsa`;
4. launches the diagnostic MIDlet directly with the installed R4 JamVM/glibj/platform;
5. does not depend on `/mnt/mmc/CFW/java`, the R1 runtime bootstrap script, or the generic FreeJ2ME launcher.

No production binary is embedded or changed.

## CI

```text
RUN=37279633639
JOB=111664418633
SOURCE_COMMIT=52f05b5239e370167a2aeb2bad07467a2f6fdb2a
ARTIFACT_ID=11330719971
R2_ZIP_SHA256=ab947a4d0c5c22e67899b30f7ccd1a5d4eab2f4f41cf90c133a4a948155a114c
```

Independent gates:

```text
AUDIO_DIAG_R2_INDEPENDENT_GATE=PASS
AUDIO_DIAG_R2_PARENT_JAR_IDENTITY_GATE=PASS
AUDIO_DIAG_R2_DIRECT_R4_LAUNCH_GATE=PASS
AUDIO_DIAG_R2_DIRECT_A1P5_PRIME_GATE=PASS
AUDIO_DIAG_R2_NO_BOOTSTRAP_DEPENDENCY=PASS
AUDIO_DIAG_R2_NO_GENERIC_LAUNCHER_DEPENDENCY=PASS
AUDIO_DIAG_R2_PRODUCTION_BINARY_DELTA=NONE
AUDIO_DIAG_R2_DIAGNOSTIC_SEMANTIC_DELTA=NONE
AUDIO_DIAG_R2_GAME_SPECIFIC_CODE=NO
DEVICE_PASS=NO
STABLE=NO
```

## Status

```text
P6_PHYSICAL_ACCEPTANCE=PASS
P7_PHYSICAL_REGRESSION=FAIL:GOW_AUDIBLE_AUDIO_CONTINUITY
AUDIO_BOUNDARY_DIAGNOSTIC_R1=FAIL:PACKAGING_ONLY
AUDIO_BOUNDARY_DIAGNOSTIC_R2=READY_NOT_TESTED
P8_PLATFORM_BASELINE_PROMOTION=BLOCKED
DEVICE_PASS=NO
STABLE=NO
```
