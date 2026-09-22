# RG35XX Clean R2B Audio — Device Test Kit

Date: 2026-09-22

## Preflight

CURRENT_SYMPTOM:
- R2C evidence removes the previous text-raster crashes, but NinjaSchool2 and KDTT terminate a game thread at `NoSuchMethodError: getSequencer`.
- Audio is absent while video/core can remain alive.

HISTORY_FOUND:
- RG35XX desktop JavaSound `MidiSystem.getSequencer()` and `AudioSystem.getClip()` are historical target failures.
- Device-proven audio ownership history uses dedicated native audio worker/ring independent of frame cadence.

PREVIOUS_FIX / EVIDENCE:
- Async callback + dedicated worker/ring: historical DEVICE-EVIDENCE / scoped DEVICE-PASS.
- CN short prime 3072: DEVICE-EVIDENCE for short playTone.
- Current R2B source reconstruction: BUILD-PASS only.

REGRESSION_RISK:
- Do not reintroduce 735 frames per retro_run.
- Do not restore MediaWarmup or /dev/snd/seq boot probing.
- Do not change font, transparency, Canvas or video in this checkpoint.

MINIMAL_PROPOSED_CHANGE:
- Install only the already BUILD-PASS R2B Java runtime + R2B native audio core on exact R2A.
- Enforce exact R2A, JamVM L, glibj, protected B4 core and SoundFont hashes before write.
- Backup and rollback are mandatory.

EXPECTED_DEVICE_TEST:
- no `NoSuchMethodError: getSequencer`;
- audible MIDI/BGM;
- worker marker ring=16384 target=3072 chunk=1470;
- async callback registered;
- normal game exit, no hard reset;
- render/input remain unchanged.

## Binary provenance

Build commit: `ef1bb0534c6d3090185ae49cb175155f5d2d98e2`
Run: `35687872223`
Artifact: `10676804838`
Artifact SHA256: `5e10f751bd87a4e57f49396d8aced162219eebc8fcf1a1dff8445dbbc7db55e4`

Runtime:
`202714a2509b9c7e62accc925f24cea3d0d1b1d47d3699b015bf8605da3ae929`

Core:
`54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51`

SoundFont required:
`c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854`

## Status

- BUILD-PASS=YES
- DEVICE-TEST-PENDING=YES
- DEVICE-PASS=NO
- STABLE=NO
- exact Golden/CN binary claim=NO
