# P2C Input / Frontend — Original RG35XX Physical Acceptance

Date: 2026-10-04

## Scope

This record accepts the P2C input/frontend module on the original RG35XX. It does not promote the complete RG35XX platform to stable.

```text
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2C_INPUT_FRONTEND
PHYSICAL_TEST_LEVEL=MODULE
PHYSICAL_BRANCH_HEAD=02d49e8bf9cea1957ab5071704e30ae99a474854
HOST_MODULE_CHECKPOINT=7f8b3bdeadd7b1cd2201f1bf62d8c29ecfb54eac
RUNTIME_CANDIDATE_COMMIT=0738281012b83d748cfb88ba063d21248a3f9c97
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
LOGICAL_RESOLUTION=176x208
P2C_INPUT_FRONTEND_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2C_PHYSICAL_TEST=PASS
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
```

## Evidence identity

The user-returned device evidence was collected at:

```text
EVIDENCE_DIRECTORY=G:\RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
EVIDENCE_SNAPSHOT=RG35XX-P2C-INPUT-FRONTEND-EVIDENCE-PHYSICAL-PASS-20261004.zip
EVIDENCE_SNAPSHOT_SHA256=D8D129951579CA9CC0053E2CD1FA8D1216C13702A91532B27B419594AEF02535
```

The package identity recorded on the device binds the run to:

```text
PACKAGE=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1
P2C_PLATFORM_JAR_RAW_SHA256=b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117
P2C_PLATFORM_JAR_SEMANTIC_SHA256=55e41d65b7f548e4189985bfa3771442001c956c7db4a9982e073ce0092a07da
EXERCISER_SHA256=ba4874f4ca2bf23f54624dc2489b2c2318fe9b8ff7da6f9f0d4f019afc7cd0b4
P2C_INPUT_NATIVE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
P2C_FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
P2C_VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
P2C_AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
RUNTIME_SEMANTIC_DELTA_FROM_HOST_CHECKPOINT=NONE
```

## Programmatic device evidence

The final run log records:

```text
P2C_RUNTIME_HASH_GATE_BEFORE=PASS
P2C_EXERCISER_RESULT=PASS PHASE=1
P2C_EXERCISER_RESULT=PASS PHASE=2
P2C_EXERCISER_RESULT=PASS PHASE=3
P2C_PROTECTED_HASHES=PASS
P2C_DEVICE_PROGRAMMATIC_RESULT=PASS
```

Phase 2 specifically passed the custom keymap, all four phone-mode hotkeys, pointer press/release at `6,6`, pointer enable/disable, and rotation sequence `1 -> 2 -> 0`.

The package-generated `MANUAL-OBSERVATION.txt` remains a pre-run template with `NOT_TESTED`. The final physical result is based on the user’s direct report that all three phases passed on the original RG35XX together with the programmatic device log.

## Acceptance boundary

This evidence establishes:

```text
P2C_HOST_MODULE_GATE=PASS
P2C_PHYSICAL_TEST=PASS
P2C_INPUT_FRONTEND_MODULE_PHYSICAL_ACCEPTANCE=PASS
```

It does not establish:

```text
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=YES
STABLE=YES
```

The next legal work unit is P3 runtime-service module reconstruction/acceptance. P2C input/frontend code is now a physically accepted module and must remain protected while P3 is investigated.
