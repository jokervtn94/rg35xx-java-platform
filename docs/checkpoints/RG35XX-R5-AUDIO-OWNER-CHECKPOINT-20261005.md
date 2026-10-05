# RG35XX R5 MIDI PLAYER OWNERSHIP — CURRENT CHECKPOINT 2026-10-05

Project: Port FreeJ2ME Miyoo/Aweigit to original RG35XX
Branch role: `physical-test/*`
Current branch: `physical-test/rg35xx-r5-audio-owner-20261005`
Previous branch head/checkpoint: `e7b86e79ae25c06019cdb05a077ca2625c404947`
Status scope: R5 owner-aware native audio candidate prepared for original-RG35XX physical validation.

## Rule lock

This checkpoint is subordinate to the user-supplied locked rule set identified by SHA256 in `docs/rules/RG35XX-BUILD-PORT-RULE-INDEX-LOCKED-20261005.md`. The repository index is an operational guardrail; it does not override the source rule documents.

Mandatory direction:

> PLATFORM FIRST. MODULE SECOND. GAME COMPATIBILITY LAST.

Canonical source lineage remains:

```text
repository = aweigit/freej2me-miyoomini
commit     = ca11dfe8ea1cc273d92460f9a83bbf192023fa63
```

No game-specific production code is authorized by this checkpoint.

## Evidence that led to R5

Generic MIDI lifecycle diagnostic physical observation supplied by the user:

```text
C0 first play                 = AUDIBLE PASS
C1A same Player first         = AUDIBLE PASS
C1B same Player resume        = AUDIBLE PASS
C2A before free               = AUDIBLE PASS
C2B reload after free         = AUDIBLE PASS
C3A Player one                = AUDIBLE PASS
C3B preloaded Player two      = AUDIBLE PASS
```

Therefore the broad hypotheses "generic pause/resume is broken", "generic free/reload is broken", and "two preloaded Players inherently fail" are not supported by the device evidence.

The remaining owner hypothesis is narrower:

```text
FAILURE_OWNER=RG35XX_NATIVE_MMAPI_PLAYER_OWNERSHIP_BOUNDARY
```

Target sequence:

```text
Player A starts
-> Player B takes SDL_mixer global Mix_Music slot
-> application returns to previously-started Player A
```

R5 changes only the RG35XX SDL1_mixer native ownership boundary so pause/resume/isPlaying/stop act only for the manager that owns current `Mix_Music`. Canonical Java `PlatformPlayer`/MMAPI semantics are not redesigned.

## R5 source/build identity

Module/build branch:

```text
module/p3-audio-player-ownership-r5-20261005
```

R5 build source commit:

```text
3352230e893f4e3582e54b6e0ca37927d97d85e9
```

Checkpoint documentation commit immediately before this branch:

```text
e7b86e79ae25c06019cdb05a077ca2625c404947
```

CI:

```text
workflow run = 37287669946
artifact id  = 11334633999
artifact     = RG35XX-R5-AUDIO-OWNER-3352230e893f4e3582e54b6e0ca37927d97d85e9
```

Final device package:

```text
RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-OWNER.zip
SHA256=4f799c927405a0d735025586ca7942be12e2e5df617b4183cf237618ef73ca5f
```

R5 candidate native audio:

```text
libaudio.so SHA256=bf6fbdd24fb6ef37dba60438be9992441e4ce8567313f7df3fdebdbea8cd32e5
NATIVE_AUDIO_DELTA=PLAYER_MANAGER_OWNERSHIP_ONLY
```

Protected/unaffected identities retained by the R5 package:

```text
platform jar = a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
input native = 6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
video native = c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
audio prime  = 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

R5 host gates:

```text
R5_AUDIO_OWNER_INDEPENDENT_GATE=PASS
R5_AUDIO_OWNER_PROTECTED_NONAUDIO_HASH_GATE=PASS
R5_AUDIO_OWNER_NATIVE_MARKER_GATE=PASS
R5_AUDIO_OWNER_JAVA6_DIAGNOSTIC_GATE=PASS
R5_AUDIO_OWNER_P6_P7_HASH_REBIND_GATE=PASS
R5_AUDIO_OWNER_A1P5_PRIME_GATE=PASS
R5_AUDIO_OWNER_CANONICAL_JAVA_DELTA=NONE
R5_AUDIO_OWNER_RUNTIME_DELTA=NONE
R5_AUDIO_OWNER_GAME_SPECIFIC_CODE=NO
```

## Current acceptance state

Do not promote beyond the exact state below:

```text
GENERIC_MIDI_LIFECYCLE_C0_C3_AUDIBLE_DEVICE=PASS
R5_HOST_GATE=PASS
R5_PHYSICAL_OWNER_TEST=PASS
P6_RETEST=PASS_SCOPED
P7_RETEST=REQUIRED
P8=BLOCKED
DEVICE-PASS=NO
STABLE=NO
```

The user then confirmed the R5 discriminator on the original RG35XX:

```text
A1_LOW_AUDIBLE=PASS
B_HIGH_AUDIBLE=PASS
A2_LOW_RETURN_AUDIBLE=PASS
R5_PHYSICAL_OWNER_TEST=PASS
```

The same R5 payload then passed the required Full Port R1 manual checks for
WAV/MIDI audibility and normal return to GarlicOS. This accepts the scoped P6
retest evidence. P7 Tier-0 must still be rerun because native audio changed.

## Required next physical sequence

Use the R5 package only; do not create another speculative candidate before this sequence is evaluated.

1. Run `RG35XX-R5-MIDI-OWNER-DIAG` on original RG35XX.
2. Required audible sequence: `A1 LOW -> B HIGH -> A2 LOW`.
3. Reject if A2 remains HIGH or becomes silent.
4. If owner diagnostic passes, run `RG35XX-FULL-PORT-R1-TEST` on the same R5 package because native audio changed.
5. Confirm required P6 display/audio/return observations physically; automated markers alone are insufficient.
6. Then run `RG35XX-R1-P7-TIER0` on the same R5 package.
7. Tier-0 inputs remain exact commercial JARs; do not rebuild/repack them.
8. Vua Cướp Biển: display/input/gameplay/no-hang physical regression required.
9. God of War: display/input/gameplay/no-hang physical regression required; audible audio is mandatory.
10. Only after required P0-P7 acceptance may P8 baseline promotion be considered.

## Tier-0 exact game identities

```text
Vua-Cuop-Bien-240x320.jar
SHA256=220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578

God-of-War-Betrayal_J2ME_EN_v148.jar
SHA256=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
```

## Stop conditions

Stop and reclassify instead of patching if:

- the R5 exact identity is not what is actually loaded on device;
- failure owner becomes unresolved;
- a proposed change crosses another protected owner without evidence;
- a game-specific hack is proposed;
- CI/exit-code/API PASS is being used as a substitute for device observation;
- Tier-0 regression is broken;
- a new candidate would use A9/diagnostic/old experimental code as production parent.

## Promotion lock

```text
R5_PHYSICAL_OWNER_TEST must PASS
AND P6 physical regression must PASS
AND P7 Vua must PASS
AND P7 GoW must PASS including audible audio
BEFORE P8 can advance.
```

Until then:

```text
DEVICE-PASS=NO
STABLE=NO
```
