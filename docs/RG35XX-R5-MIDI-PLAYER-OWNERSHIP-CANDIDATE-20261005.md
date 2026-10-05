# RG35XX R5 MIDI Player Ownership Candidate — 2026-10-05

## Status

`MODULE_CANDIDATE_HOST=PASS / PHYSICAL_TEST_REQUIRED / DEVICE_PASS=NO / STABLE=NO`

## Evidence before R5

R4 P6 physical acceptance passed, including audible WAV and MIDI. Vua Cướp Biển Tier-0 passed. God of War passed display/input/gameplay/no-hang/exit but failed audible audio continuity after entering gameplay.

Generic diagnostics then established:

- complex format-1 MIDI is audible on the current SDL1_mixer backend;
- same-Player stop/resume is audible;
- free/reload is audible;
- two preloaded Players with first free then second play are audible;
- therefore generic pause/resume/free/reload/preload lifecycle is not itself the failure owner.

GoW's distinct call sequence is A -> B -> A where A is a previously-open Player that must regain ownership after B has occupied the single SDL_mixer Mix_Music slot. Canonical PlatformPlayer calls resumeMusic() and then isPlaying() before deciding whether to call playMusic(handle). With a global SDL1 implementation, A can resume/query B and incorrectly skip selecting A again.

## Owner classification

```text
FAILURE_OWNER=RG35XX_NATIVE_MMAPI_PLAYER_OWNERSHIP_BOUNDARY
CANONICAL_PLATFORMPLAYER_CHANGE_REQUIRED=NO
CANONICAL_MMAPI_CHANGE_REQUIRED=NO
GAME_SPECIFIC_CODE_REQUIRED=NO
RUNTIME_CHANGE_REQUIRED=NO
```

## Minimum R5 delta

Candidate native source overlay:

`adapter/native/rg35xx_audio_sdl1_mixer_r5_owner.c`

It binds each Java `SdlMixerManager` instance to the `Mix_Music` handle loaded by that manager. The following JNI operations become owner-aware:

- MIDI pause
- MIDI resume
- MIDI isPlaying
- MIDI stop
- MIDI free/owner-map cleanup

`Mix_PlayMusic(handle, loops)` remains the authoritative music-owner switch. Canonical Java PlatformPlayer/MMAPI remains byte-unchanged.

## Generic physical discriminator

`RG35XX-Midi-Ownership-R5.jar` uses generated non-commercial MIDI only and preloads two Players:

1. A1 LOW tone
2. stop A
3. B HIGH tone
4. stop B
5. A2 LOW tone must return

The critical physical discriminator is A2. On the intended owner-aware boundary A2 must be LOW again, not HIGH and not silent.

## Exact R4 parent

```text
PARENT_R4_ARTIFACT_ID=11325956934
PARENT_R4_ZIP_SHA256=0e739da19b7f6078e8c9b1b2223cf3fb55a9f95e187830502320a1987282792d
```

## R5 host result

```text
WORKFLOW_RUN=37287669946
ARTIFACT_ID=11334633999
SOURCE_COMMIT=3352230e893f4e3582e54b6e0ca37927d97d85e9
R5_AUDIO_SHA256=bf6fbdd24fb6ef37dba60438be9992441e4ce8567313f7df3fdebdbea8cd32e5
R5_DEVICE_ZIP_SHA256=4f799c927405a0d735025586ca7942be12e2e5df617b4183cf237618ef73ca5f
```

Independent gates:

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

Protected unchanged identities include:

```text
PLATFORM=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
A1P5_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

## Required physical sequence

1. Install exact R5 package over R4 payload without deleting `/mnt/mmc/Roms/JAVA/`.
2. Run `RG35XX-R5-MIDI-OWNER-DIAG`; require A1 LOW audible, B HIGH audible, A2 LOW audible again.
3. If ownership diagnostic passes, rerun `RG35XX-FULL-PORT-R1-TEST`; require WAV/MIDI audible, rotation and normal return.
4. Then rerun P7 Tier-0 Vua + GoW on exact commercial JAR hashes; GoW menu and gameplay audio continuity must be audible.
5. Only after all physical gates pass may P8 be considered.

```text
P6_PHYSICAL_ACCEPTANCE=RETEST_REQUIRED_NATIVE_CHANGED
P7_PHYSICAL_REGRESSION=RETEST_REQUIRED_NATIVE_CHANGED
DEVICE_PASS=NO
STABLE=NO
```
