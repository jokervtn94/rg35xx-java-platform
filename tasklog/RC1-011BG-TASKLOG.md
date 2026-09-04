# RG35XX Java Platform — RC1-011BG Tasklog

Task: RGJ-RC1-011BG
Action: ADD / AUDIT
Status: IMPLEMENTED

## Purpose
Materialize the first real-device validation gate after RC1-011BF BUILD-PASS. This task does not alter emulator/runtime semantics and must not claim DEVICE-TEST-PASS without evidence captured on an RG35XX.

## Build basis
- BUILD-PASS commit under test: `086d4987c0d60b5eb9abc3887e73638b24a1b964`.
- Consolidated run: `33883673553`.
- Evidence artifact: `9940954185`.
- Evidence artifact SHA-256: `e2f3e70634026a1916f9cd75af5875b32c087fdae9622349d9f18afad943b630`.

## Device validation scope
1. Boot libretro core and JamVM without crash/hang.
2. Verify 640x480 RGB565 video remains stable and stdout is not polluted by text/audio.
3. Verify key press/release/repeat with no stuck key across game switch.
4. Verify PCM/WAV playback, MIDI/SoundFont playback and ToneControl/playTone paths.
5. Verify native END_OF_MEDIA reaches Java listener semantics.
6. Verify ordinary game switch preserves the dedicated audio pipe while resetting players/media/cache/input/frame state in the locked lifecycle order.
7. Verify RMS save/reopen using pinned upstream synchronous multi-file RecordStore semantics; no historical async/single-file assumption may be reintroduced.
8. Verify clean shutdown: Java exits, audio drain thread stops, pipe closes, native media/cache/runtime resets, and no forced watchdog behavior is required.
9. Exercise representative private compatibility JARs without committing proprietary binaries/assets.

## Evidence policy
- Device evidence must record firmware/frontend/core path, exact artifact hashes, tested JAR hashes/names, start/end timestamps, observed PASS/FAIL per subsystem, and relevant stderr/system logs.
- A single crash, hang, stuck input, broken save/reopen, corrupted stdout video IPC, or media teardown leak is DEVICE-TEST-FAIL for the affected candidate.
- Warnings already accepted at BUILD-PASS (`rg35xx_audio_parse_header` unused helper and mixer indentation warnings) are compile hygiene items, not substitutes for device evidence.

## Deliverables
- `docs/RC1-DEVICE-VALIDATION.md`: operator checklist and acceptance criteria.
- `scripts/rc1_device_evidence.sh`: read-only evidence collector for an RG35XX test session.

## Gate
DEVICE-TEST-PASS remains forbidden until an actual RG35XX session satisfies all mandatory checks and its evidence is reviewed.