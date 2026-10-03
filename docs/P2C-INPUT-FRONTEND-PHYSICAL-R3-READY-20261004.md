# P2C Input/Frontend Physical R3 READY Checkpoint — 2026-10-04

## Purpose

This checkpoint freezes the exact P2C Input/Frontend physical-test handoff after the R3 host/module, public-MIDP exerciser, fail-closed package, and artifact-upload gates passed in GitHub Actions.

This is **READY for physical test** only. It is not P2C physical acceptance and it does not promote any runtime to `main`.

## Locked lineage

```text
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2C_INPUT_FRONTEND
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_PARENT_IDENTITY=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
P2B_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
HOST_MODULE_CHECKPOINT=7f8b3bdeadd7b1cd2201f1bf62d8c29ecfb54eac
RUNTIME_CANDIDATE_COMMIT=0738281012b83d748cfb88ba063d21248a3f9c97
PHYSICAL_R3_SOURCE_HEAD=ceca509b39f95f2d172c4b20119ab644522be55b
PHYSICAL_BRANCH=physical-test/p2c-input-frontend-20261003-r3
RUNTIME_SEMANTIC_DELTA=NONE
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
```

The R2 -> R3 change is harness/workflow semantic-JAR identity gating only. The packaged runtime/native candidate is unchanged from the host/module candidate.

## R3 CI gate

```text
WORKFLOW_RUN=37145570672
WORKFLOW_JOB=111268672854
P2C_PHYSICAL_R3_EXACT_CHECKPOINT=PASS
P2C_PHYSICAL_R3_REPOSITORY_SCOPE=PASS
P2C_PHYSICAL_R3_PROTECTED_PARENT_CHAIN=PASS
P2C_PHYSICAL_R3_PINNED_TOOLCHAIN=PASS
P2C_PHYSICAL_R3_HOST_MODULE_REBUILD=PASS
P2C_PHYSICAL_R3_PROTECTED_AUDIO_DEPENDENCY_GATE=PASS
P2C_EXERCISER_PLATFORM_SEMANTIC_GATE=PASS
P2C_EXERCISER_BUILD=PASS
P2C_EXERCISER_JAVA6_GATE=PASS
P2C_EXERCISER_PUBLIC_MIDP_ONLY=YES
P2C_EXERCISER_DIRECT_BACKEND_CALL=NO
P2C_PHYSICAL_R3_EXERCISER_GATE=PASS
P2C_PHYSICAL_R3_EXACT_PACKAGE_RAW_JAR_GATE=PASS
P2C_PHYSICAL_R3_ONE_PACKAGE_GATE=PASS
P2C_PHYSICAL_PACKAGE_GATE=PASS
```

No device result is implied by these CI gates.

## Exact GitHub Actions artifact

```text
ARTIFACT_NAME=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R3-ceca509b39f95f2d172c4b20119ab644522be55b
ARTIFACT_ID=11281889195
ARTIFACT_SIZE_BYTES=6432986
ARTIFACT_ZIP_SHA256=f6215e37a3c07bf218f7b3db1243f14ae37fb5146d860e2b6c9b675b238689df
```

The Actions artifact contains the exact raw physical package plus the package identity and CI gate logs.

## Exact raw physical package

```text
RAW_PACKAGE_FILENAME=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip
RAW_PACKAGE_SHA256=014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36
PACKAGE_ROOT=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1/
```

The package's own identity records the same physical source head, host/module checkpoint, runtime candidate, and raw package SHA-256.

## Exact runtime and payload identities

```text
P2C_PLATFORM_JAR_RAW_SHA256=471152544509fe0e4822e782b53fdcbda3288a57ac2fb29a2efe7032e283d9a9
P2C_PLATFORM_JAR_SEMANTIC_SHA256=0a4f197bdbf39b7102c69bb2e560c6e469c32c20ae58c8fb688fadbcecf1c6c6
P2C_INPUT_NATIVE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
P2C_FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
P2C_VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
P2C_AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXERCISER_SHA256=baed252f0d68736867b3a6d4f50f3a30199f7705050e5ac898403218bc9784ac
FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724
```

Device launcher preconditions additionally require the protected accepted runtime files already installed on the original RG35XX:

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

The launcher checks all required files and hashes before executing the exerciser and fails closed on a mismatch.

## Public-MIDP physical exerciser contract

```text
LOGICAL_RESOLUTION=176x208
PHASE_COUNT=3
PHASE1=DEFAULT_14_CONTROLS+PHONE_MODE_CYCLE+PERSIST_N
PHASE2=PERSISTENCE+CUSTOM_KEYMAP+POINTER+ROTATION
PHASE3=INVALID_KEYMAP_FAILSAFE
DEFAULT_PHYSICAL_CONTROL_COUNT=14
PHONE_MODE_SET=p,n,e,s,m
POINTER_EXPECTED_COORDINATE=6,6
ROTATION_SEQUENCE=0,1,2,0
PUBLIC_MIDP_CANVAS_KEY_API=YES
PUBLIC_MIDP_POINTER_API=YES
DIRECT_RG35XX_BACKEND_CALL=NO
COMMERCIAL_GAME_CONTENT=NO
GAME_SPECIFIC_CODE=NO
```

The device test is module-level and human-driven. Each phase must reach its green PASS screen and the operator must press A to continue. Phase 2 additionally requires visual confirmation that orientation changes through `0 -> 1 -> 2 -> 0`.

## Exact physical procedure

1. Use the GitHub Actions artifact named exactly:
   `RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R3-ceca509b39f95f2d172c4b20119ab644522be55b`.
2. Verify the downloaded Actions ZIP SHA-256 is:
   `f6215e37a3c07bf218f7b3db1243f14ae37fb5146d860e2b6c9b675b238689df`.
3. Extract the Actions artifact and locate:
   `RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip`.
4. Verify that raw package SHA-256 is:
   `014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36`.
5. Extract the raw package.
6. Copy the **contents** of its `SD/` directory to the root of the **original RG35XX** SD card. The supplied PowerShell helper `INSTALL-RG35XX-P2C-INPUT-FRONTEND.ps1 -SdRoot <SD-root>` performs exactly this copy operation on Windows.
7. Boot the original RG35XX into GarlicOS and launch `RG35XX-P2C-INPUT-FRONTEND` from Apps.
8. Follow every on-screen prompt exactly:
   - phase 1: default 14 controls and phone-mode cycle; mode `n` is persisted,
   - phase 2: persisted `n`, custom keymap, public MIDP pointer at `6,6`, rotation `0 -> 1 -> 2 -> 0`; visually confirm each orientation change,
   - phase 3: invalid keymap fail-safe back to defaults.
9. Confirm every phase shows green PASS and exits normally to the next phase when A is pressed.
10. After phase 3, confirm a normal return to the GarlicOS menu.
11. Preserve the entire evidence directory:
    `/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE`.
    On Windows the supplied helper `COLLECT-RG35XX-P2C-INPUT-FRONTEND-EVIDENCE.ps1 -SdRoot <SD-root>` copies it out of the SD card.

## Required evidence before P2C physical PASS

Review all generated device evidence, including:

```text
P2C-INPUT-FRONTEND-RUN.log
P2C-INPUT-FRONTEND-DEVICE-SUMMARY.txt
PHASE1.log
PHASE2.log
PHASE3.log
MANUAL-OBSERVATION.txt
P2C-INPUT-FRONTEND-IDENTITY.txt
P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt
PHYSICAL-PACKAGE-IDENTITY.txt
PAYLOAD-SHA256SUMS.txt
```

Programmatic acceptance requires all three phase exit codes to be zero, all required phase PASS markers to be present, the public MIDP pointer event at `6,6` to pass, and protected before/after hashes to remain unchanged. The launcher records `P2C_DEVICE_PROGRAMMATIC_RESULT=PASS` only if those checks pass.

Human physical acceptance additionally requires both of these observations from the original RG35XX operator:

- visible rotation/orientation changes for `0 -> 1 -> 2 -> 0` during phase 2;
- normal return to the GarlicOS menu after phase 3.

The generated `MANUAL-OBSERVATION.txt` intentionally starts at `NOT_TESTED`; automation must not upgrade the human observation.

## Locked status at READY checkpoint

```text
P2C_HOST_MODULE_GATE=PASS
P2C_PHYSICAL_PACKAGE_GATE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
RUNTIME_SEMANTIC_DELTA=NONE
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

Do not promote P2C to `main`, do not start game regression, and do not begin compatibility fixes from this checkpoint. The next legal gate is physical module execution of the exact package above on an original RG35XX and review of the generated evidence plus the two required human observations.
