# RG35XX Java Platform — RC1 Device Validation

Status: DEVICE TEST PREPARATION. This document does **not** claim DEVICE-TEST-PASS.

Build candidate under test:
- source commit: `086d4987c0d60b5eb9abc3887e73638b24a1b964`
- consolidated build run: `33883673553`
- build evidence artifact: `9940954185`
- artifact ZIP SHA-256: `e2f3e70634026a1916f9cd75af5875b32c087fdae9622349d9f18afad943b630`

## 1. Files that must be deployed

Use the files produced by the accepted build, not locally rebuilt substitutes:
- `freej2me_plus_libretro.so`
- `freej2me_plus-lr.jar`
- runtime DejaVu Sans at `/mnt/mmc/Java/runtime/DejaVuSans.ttf`
- runtime SoundFont at `/mnt/mmc/Java/runtime/GeneralUser-GS.sf2`

Before launch, record SHA-256 for every deployed file. The test session is invalid if the tested core/JAR differs from the accepted build candidate.

## 2. Session evidence

Run `scripts/rc1_device_evidence.sh` on the device before and after testing. Preserve its output directory together with frontend/core stderr logs.

Record manually:
- RG35XX model/revision
- firmware/frontend name and version
- exact core path
- exact JAR path(s)
- SD card filesystem if known
- test start/end time
- tester observations for every gate below

Private commercial JARs are permitted as local test inputs, but do not commit their bytecode/assets. Record only title + SHA-256 + result.

## 3. Mandatory boot/video gate

PASS requires all of the following:
1. Core loads without immediate crash, SIGSEGV or endless restart.
2. JamVM starts and the selected JAR reaches visible gameplay/menu state.
3. Video remains stable at the platform contract of 640x480 RGB565.
4. No log text, PCM data or other payload corrupts stdout binary video IPC.
5. Repeated menu/game transitions do not produce persistent black frames, stale frames or geometry corruption.

FAIL on crash, hang, corrupted frames, stdout pollution, permanent black screen, or frontend termination.

## 4. Input gate

Exercise D-pad, action buttons and any game-specific keypad mappings.

PASS requires:
- press and release both register once;
- held keys repeat without bursts after a stall;
- no duplicate transitions;
- no stuck key after pause/resume or ordinary game switch;
- malformed/unused frontend inputs do not kill the Java/libretro IO path.

Use at least one title with continuous movement and one title with menu navigation.

## 5. Graphics/font gate

Exercise text-heavy menus plus sprite/image-heavy gameplay.

PASS requires:
- readable SansSerif/Dialog text;
- width/height/baseline behavior visually consistent with rendered text;
- no missing glyph boxes for the tested title's normal UI text;
- no repeat of compound-glyph `Zone.combineWithSubGlyph` crash;
- drawRGB transparency/clipping and Sprite transforms remain visually correct;
- game switch clears stale image/transform cache state.

## 6. Audio/media gate

Test all supported paths that can be reached by available JARs or small local test MIDlets:
- PCM/WAV
- MIDI using `/mnt/mmc/Java/runtime/GeneralUser-GS.sf2`
- ToneControl sequence
- `Manager.playTone()`
- volume changes
- looping
- END_OF_MEDIA listener behavior

PASS requires:
- audio is audible and not routed through stdout;
- no permanent crackle caused by undrained pipe backlog;
- WAV duration/pitch is plausible at non-44.1 kHz source rates when such a fixture is available;
- MIDI starts without JavaSound dependency;
- tone playback completes;
- END_OF_MEDIA reaches Java listener semantics once;
- stopping/closing a player releases its native state;
- switching games does not retain voices from the previous title.

## 7. Game-switch lifecycle gate

Perform at least five ordinary switches between two different JARs without restarting the frontend.

For every switch verify:
1. old game saves before its in-memory state is discarded;
2. old media players/voices stop;
3. no old key remains held;
4. no old image/sprite transform remains visible;
5. new game starts normally;
6. audio continues working after the switch.

The dedicated audio pipe is process-lifetime state and must remain usable across ordinary game switches. It closes only at platform exit.

## 8. RMS gate

Current RC1 storage baseline is pinned upstream synchronous **multi-file** RecordStore semantics. Do not test against the historical single-target atomic-file assumption.

Use at least:
- Diamond Rush or another title that saves progress frequently;
- Prince of Persia or another title where reopen/version/record IDs are observable.

Procedure:
1. start from a known save state or empty save directory;
2. create/change progress;
3. exit the game normally;
4. relaunch and confirm the saved state;
5. change the state again;
6. switch to another JAR and back;
7. relaunch after a full frontend/core restart.

PASS requires correct save/reopen behavior with no lost progress, malformed RecordStore, unexpected record-ID reset, or cross-title contamination.

## 9. Shutdown gate

Exit the core/frontend normally after audio has been used.

PASS requires:
- Java process terminates without hanging indefinitely;
- audio drain worker terminates;
- dedicated audio pipe is closed at platform exit;
- native mixer/event queue/media cache/runtime are reset/shutdown;
- no orphan JamVM process remains;
- no aggressive watchdog is needed for ordinary exit.

A forced kill caused by a persistent hang is a FAIL, even though the native teardown path contains a bounded SIGKILL fallback for pathological Java shutdown.

## 10. Representative private-JAR sequence

Preferred regression order from the existing compatibility corpus:
1. Diamond Rush — RMS + Timer + gameplay/input.
2. Prince of Persia: The Two Thrones — RMS reopen/record behavior + graphics/input.
3. Asphalt 4 Elite Racing — sustained graphics/input/audio load.
4. Zombie Infection — gameplay/media regression.
5. God of War Betrayal — sprite/input/render regression.
6. Vua Cướp Biển — additional vendor/API compatibility coverage.

If a title is unavailable, mark it NOT TESTED rather than substituting an unrecorded claim.

## 11. Decision rule

`DEVICE-TEST-PASS` may be recorded only when all mandatory gates are PASS on real RG35XX hardware and the evidence bundle has been reviewed.

Any reproducible crash, hang, stdout corruption, stuck input, broken media teardown, lost/corrupted RMS data, or failed clean shutdown makes the candidate `DEVICE-TEST-FAIL` until a new immutable repair task and new build candidate are validated.
