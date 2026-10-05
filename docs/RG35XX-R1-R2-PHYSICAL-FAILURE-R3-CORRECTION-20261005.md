# RG35XX Full Port R1 — R2 physical evidence and R3 lineage correction

Date: 2026-10-05

## R2 physical evidence

The R2 install-layout correction succeeded in moving the campaign past the prior
missing-runtime failure. The original RG35XX physically executed the full P6
campaign through P1, P2A, P2B and all three P2C phases.

Observed programmatic results before the first blocking failure:

```text
P2A_EXERCISER_RESULT=PASS
P2B_EXERCISER_RESULT=PASS
P2C_EXERCISER_RESULT=PASS PHASE=1
P2C_EXERCISER_RESULT=PASS PHASE=2
P2C_EXERCISER_RESULT=PASS PHASE=3
P3_TEST_BOOT=PASS
P3_RMS_CRUD_ENUMERATE=PASS
P3_RMS_REOPEN_DELETE=PASS
P3_FILE_CREATE_WRITE_READ_DELETE=PASS
P3_RUNTIME_SERVICE_RESULT=FAIL_EXCEPTION
java.lang.UnsatisfiedLinkError: sdlMixerInit
```

P7 correctly refused to run because P6 had not reached programmatic PASS:

```text
P7_PRECONDITION=FAIL:P6_PROGRAMMATIC_NOT_PASS
```

Therefore no Tier-0 game result is claimed from this campaign.

## Failure classification

The failure exactly reproduces the first P3 audio-native failure already
resolved before P3 physical acceptance. The accepted P3 documentation records
that the pre-fix platform had not loaded `libaudio.so` before the canonical
`SdlMixerManager` JNI call.

R2 carried platform SHA256:

```text
b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117
```

That JAR lacks the accepted `RG35XXLauncher` audio-loader markers.

The exact P3 follow-up artifact that was physically accepted is:

```text
P3_WORKFLOW_RUN=37211752518
P3_ARTIFACT_ID=11306309186
P3_COMMIT=4fe82701dc98f29b96585e85deb146093ac14cc3
P3_PLATFORM_SHA256=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
```

The accepted JAR contains:

```text
libaudio.so
RG35XX_A7_AUDIO_BRIDGE=LOADED
DEVICE_INIT=LAZY
```

A byte-level JAR comparison proves the only changed entries between the R2
pre-fix JAR and the accepted P3 JAR are the four `RG35XXLauncher` class-family
entries. Canonical MMAPI, `PlatformPlayer`, `SdlMixerManager`, JamVM, glibj and
all native binaries remain unchanged.

Classification:

```text
FAILURE_OWNER=RG35XX_AUDIO_BOUNDARY_ARTIFACT_SELECTION
ROOT_CAUSE=FULL_PORT_INTEGRATION_SELECTED_PRE_FIX_P3_PLATFORM
NEW_AUDIO_IMPLEMENTATION_REQUIRED=NO
```

## R3 correction

R3 restores the exact already-accepted P3 platform JAR instead of rebuilding or
inventing a new audio path.

Host/CI result:

```text
R1_R3_INDEPENDENT_GATE=PASS
R1_R3_ACCEPTED_P3_PLATFORM_GATE=PASS
R1_R3_AUDIO_LOADER_MARKER_GATE=PASS
R1_R3_RUNTIME_HASH_GATE=PASS
R1_R3_NATIVE_HASH_GATE=PASS
R1_R3_COMMERCIAL_GAME_CONTENT=NO
R1_R3_RUNTIME_SEMANTIC_DELTA=NONE
R1_R3_NATIVE_AUDIO_DELTA=NONE
```

GitHub Actions:

```text
RUN=37260735304
SOURCE_COMMIT=0eea7cecc596616746808114c39c01826ad72aa0
ARTIFACT_ID=11324480934
ARTIFACT_DIGEST=sha256:8fe161346052e163c2c10c2da17370d8d7ed6bdf61ae0302b7e33fb8220d0a61
R3_DEVICE_ZIP_SHA256=93dab9974944b41b4153775aea1a7670ea0b269f55a121680f42ff47032643b3
```

## Current status

```text
R2_INSTALL_LAYOUT_BOOTSTRAP=PASS
P1_GRAPHICS_R2_CAMPAIGN=PASS_PROGRAMMATIC
P2A_IMAGE_R2_CAMPAIGN=PASS_PROGRAMMATIC
P2B_FONT_R2_CAMPAIGN=PASS_PROGRAMMATIC
P2C_INPUT_FRONTEND_R2_CAMPAIGN=PASS_PROGRAMMATIC
P3_R2_CAMPAIGN=FAIL_PRE_FIX_PLATFORM_SELECTED
R3_AUDIO_LINEAGE_CORRECTION_HOST=PASS
P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
P7_PHYSICAL_REGRESSION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
```

Physical acceptance remains mandatory. Run P6 on R3 first. P7 may run only
after P6 succeeds and physical observations are reviewed. God of War audible
audio remains a required Tier-0 observation.
