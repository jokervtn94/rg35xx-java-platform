# Master Tasklog — RG35XX FreeJ2ME Platform Port

Last updated: **2026-10-04**

This is the canonical progress ledger for new ChatGPT/Codex sessions. Read `AGENTS.md` and `CURRENT-CHECKPOINT.md` first. Locked rule files override this log if any historical text conflicts.

## 0. Project identity

```text
PROJECT=Port_FreeJ2ME_Miyoo_Aweigit_to_Original_RG35XX
REPOSITORY=jokervtn94/rg35xx-java-platform
TARGET=ORIGINAL_ANBERNIC_RG35XX_GARLICOS
CANONICAL_SOURCE=aweigit/freej2me-miyoomini
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
PORT_MODEL=MIYOO_FIRST_PLATFORM_FIRST
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

## 1. Official accepted baseline vs current work

Official accepted runtime is still P2B:

```text
OFFICIAL_BRANCH=main
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2B_FONT_TEXT
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
```

Current work is P2C Input/Frontend:

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
P2=PARTIAL
P2C_RUNTIME_CANDIDATE=0738281012b83d748cfb88ba063d21248a3f9c97
P2C_HOST_MODULE_GATE=PASS
P2C_PHYSICAL_PACKAGE_GATE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED
```

Do not confuse a package-ready P2C branch with accepted `main` lineage.

## 2. Phase status

| Phase / module | Status | Current authority |
|---|---|---|
| P0 — Exact Golden authority | `PASS` | Golden A8/protected evidence retained. |
| P1 / P1A — Core 2D Graphics | `PASS` | Host/module + original RG35XX physical module acceptance. |
| P2A — Image Decode | `PASS` | 450/450 physical decode cases; normal exit. |
| P2B — Font/Text | `PASS` | 360/360 physical cases; green PASS; normal GarlicOS return. |
| P2C — Input/Frontend | `PARTIAL` | Hardware audit, runtime host/module gate and physical package gate PASS; physical module test `NOT_TESTED`. |
| P3 — Runtime services | `NOT_TESTED` | Do not begin before P2 closes. |
| P4 — Deferred capabilities | `NOT_TESTED` | M3G/Mascot/LWJGL/OpenGL capability decisions. |
| P5 — Generic installer/platform | `NOT_TESTED` | Generic installer/launcher required. |
| P6 — Full platform exerciser | `NOT_TESTED` | Full declared platform suite required. |
| P7 — Tier-0 regression | `NOT_TESTED` | Vua Cướp Biển + God of War including audible GoW audio. |
| P8 — Baseline promotion | `NOT_TESTED` | Only after P0-P7 PASS. |
| P9 — Compatibility updates | `NOT_TESTED` | Forbidden before P8. |

```text
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

## 3. Accepted lineage history

### P1A Graphics

```text
P1A_CANDIDATE=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P1A_ACCEPTANCE_COMMIT=f502ea692518fa1e3b529718f44aaf459f90f49c
P1A_HOST_MODULE_GATE=PASS
P1A_PHYSICAL_MODULE_ACCEPTANCE=PASS
```

### P2A Image Decode

```text
P2A_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P2A_CANDIDATE=77a36526e0f6d875c57c7e9a973e0c1a05573721
P2A_ACCEPTANCE_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2A_FIXTURES=150
P2A_PUBLIC_FRONTENDS=3
P2A_DEVICE_CASES=450
P2A_FAILURES=0
P2A_PHYSICAL_MODULE_ACCEPTANCE=PASS
```

### P2B Font/Text

```text
P2B_RUNTIME_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2B_RUNTIME_CANDIDATE=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_HOST_MODULE_CHECKPOINT=121ca5904b7d442161ed4639f30c5fe9f1c5772d
P2B_PHYSICAL_SOURCE_HEAD=5a8e29dd368bf99b22e81d256691b2a7ec8f1adf
P2B_PHYSICAL_ACCEPTANCE_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
P2B_ACCEPTED_BRANCH_HEAD=6cc7461897dedeafa3d71848854341d41c533b5d
P2B_DEVICE_CASES=360
P2B_FAILURES=0
P2B_PHYSICAL_TEST=PASS
P2B_NORMAL_EXIT=PASS
```

P2B Windows installer R2 was helper-only; CI proved the `SD/` runtime tree byte-identical to the physically accepted R1 payload:

```text
P2B_R2_RUNTIME_SEMANTIC_DELTA=NONE
P2B_R2_SD_RUNTIME_PAYLOAD_DELTA=NONE
P2B_R2_HYGIENE_RUN=37133242055
P2B_R2_PACKAGE_SHA256=7df059c07a3867eef5e6a00348b19b18ee6901cffd4bf7b53caefbbebb34de38
```

## 4. P2C chronology — audit to physical-ready

### 4.1 Contract audit

P2C scope is one module:

```text
complete physical input mapping
keymap/frontend policy
logical resolution configuration
pointer/touch policy
rotation policy if supported
```

Dynamic resize remains P3.

Historical M1.3 evidence only covered 12 controls and did not prove L2/R2 identity, so runtime patching remained forbidden until a diagnostic was run.

### 4.2 Diagnostic-only hardware capability probe

A diagnostic-only package was derived from the prior device-proven raw-input probe. It did not become a production parent and did not modify production runtime.

Original RG35XX result closed the missing hardware contract:

```text
KEYMAP_COUNT=14
L2=JS0_AXIS2_BASELINE_-32767_PRESS_32767_BIT12
R2=JS0_AXIS5_BASELINE_-32767_PRESS_32767_BIT13
PROBE_EXIT=0
PROTECTED_RUNTIME_HASHES_BEFORE_AFTER=PASS
```

This evidence authorized only the minimum owner-scoped P2C input/frontend candidate.

### 4.3 P2C runtime candidate

Candidate branch:

```text
module/p2c-input-frontend-candidate-r1
```

Production ancestry begins from the exact official accepted main/P2B parent; the diagnostic branch is evidence only, not runtime ancestry.

```text
P2C_RUNTIME_CANDIDATE_COMMIT=0738281012b83d748cfb88ba063d21248a3f9c97
```

Owner scope:

- native `/dev/input/js0` owner: add measured L2 axis2 + R2 axis5 bits while preserving existing 12 bits;
- RG35XX Java frontend owner: canonical Miyoo physical roles, phone-mode `p/n/e/s/m`, keymap policy, hotkeys, pointer mode, rotation and launch-time logical resolution wiring;
- canonical MIDP `Canvas`/`GameCanvas`/`MobilePlatform` semantics remain owned by canonical code;
- protected video/audio/font owners are not reimplemented.

### 4.4 P2C host/module gate

Final host authority:

```text
P2C_HOST_GATE_HEAD=0851cfde1da41c955997a693ac6df34557d76093
P2C_HOST_MODULE_CHECKPOINT=7f8b3bdeadd7b1cd2201f1bf62d8c29ecfb54eac
RUN_ID=37141905525
JOB_ID=111257926132
P2C_HOST_MODULE_GATE=PASS
```

Passed gates include:

```text
P2C_CANONICAL_DIFF_VERIFIED=PASS
P2C_OWNER_SCOPE_VERIFIED=PASS
P2C_JAVA6_GATE=PASS
P2C_HOST_DEFAULT_MAPPING_GATE=PASS
P2C_HOST_PHONE_MODE_GATE=PASS
P2C_HOST_KEYMAP_CFG_GATE=PASS
P2C_HOST_HOTKEY_GATE=PASS
P2C_HOST_POINTER_GATE=PASS
P2C_HOST_ROTATION_GATE=PASS
P2C_NATIVE_EXISTING_12_CONTROL_GATE=PASS
P2C_NATIVE_L2_AXIS2_GATE=PASS
P2C_NATIVE_R2_AXIS5_GATE=PASS
P2C_NATIVE_14_CONTROL_HOST_GATE=PASS
P2C_ARM_INPUT_NATIVE_BUILD=PASS
P2C_VIDEO_PARENT_IDENTITY=PASS
P2C_FONT_PARENT_IDENTITY=PASS
P2C_LAUNCH_RESOLUTION_CONTRACT_GATE=PASS
P2C_FINAL_OUTPUT_HASH_GATE=PASS
```

### 4.5 P2C physical package R1/R2/R3

R1 physical workflow initially failed at candidate reconstruction orchestration. R2 corrected semantic-JAR reconstruction but exerciser still used stale raw-JAR identity. R3 replaced that stale exerciser raw-container identity gate with the existing semantic-JAR digest gate. These R2/R3 changes are harness/workflow only and do not change runtime candidate semantics.

Exact successful package source:

```text
PHYSICAL_BRANCH=physical-test/p2c-input-frontend-20261003-r3
PHYSICAL_R3_SOURCE_HEAD=ceca509b39f95f2d172c4b20119ab644522be55b
P2C_READY_DOC_COMMIT=286e4ebbea850a56db27165aec3e40d1ddf97380
RUNTIME_CANDIDATE_COMMIT=0738281012b83d748cfb88ba063d21248a3f9c97
RUNTIME_SEMANTIC_DELTA=NONE
```

Successful R3 CI:

```text
WORKFLOW_RUN=37145570672
WORKFLOW_JOB=111268672854
P2C_PHYSICAL_R3_HOST_MODULE_REBUILD=PASS
P2C_PHYSICAL_R3_PROTECTED_AUDIO_DEPENDENCY_GATE=PASS
P2C_EXERCISER_PLATFORM_SEMANTIC_GATE=PASS
P2C_EXERCISER_BUILD=PASS
P2C_EXERCISER_JAVA6_GATE=PASS
P2C_EXERCISER_PUBLIC_MIDP_ONLY=YES
P2C_EXERCISER_DIRECT_BACKEND_CALL=NO
P2C_PHYSICAL_R3_EXERCISER_GATE=PASS
P2C_PHYSICAL_R3_ONE_PACKAGE_GATE=PASS
P2C_PHYSICAL_PACKAGE_GATE=PASS
```

Physical artifact identity:

```text
ACTIONS_ARTIFACT_ID=11281889195
ACTIONS_ARTIFACT_NAME=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R3-ceca509b39f95f2d172c4b20119ab644522be55b
ACTIONS_ARTIFACT_SHA256=f6215e37a3c07bf218f7b3db1243f14ae37fb5146d860e2b6c9b675b238689df
RAW_PACKAGE=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip
RAW_PACKAGE_SHA256=014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36
```

Device exerciser:

```text
LOGICAL_RESOLUTION=176x208
PHASE_COUNT=3
PHASE1=DEFAULT_14_CONTROLS+PHONE_MODE_CYCLE+PERSIST_N
PHASE2=PERSISTENCE+CUSTOM_KEYMAP+POINTER+ROTATION
PHASE3=INVALID_KEYMAP_FAILSAFE
POINTER_EXPECTED_COORDINATE=6,6
ROTATION_SEQUENCE=0,1,2,0
PUBLIC_MIDP_ONLY=YES
GAME_SPECIFIC_CODE=NO
```

### 4.6 Current P2C state

```text
P2C_HOST_MODULE_GATE=PASS
P2C_PHYSICAL_PACKAGE_GATE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED
P2C_INPUT_FRONTEND_MODULE_PHYSICAL_ACCEPTANCE=NOT_TESTED
P2=PARTIAL
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

## 5. Exact protected identities

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
P2B_ACCEPTED_INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2C_INPUT_NATIVE_CANDIDATE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
```

The changed P2C input-native hash is candidate-specific and must not be retroactively described as the accepted P2B input hash before P2C physical acceptance.

## 6. Current legal task

```text
NEXT_LEGAL_ACTION=P2C_ORIGINAL_RG35XX_PHYSICAL_MODULE_TEST_AND_EVIDENCE_REVIEW
EVIDENCE_DIR=/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
```

Physical acceptance requires:

- all three phases exit zero and report required PASS markers;
- pointer event `6,6` passes through public MIDP callbacks;
- protected before/after hashes pass;
- `P2C_DEVICE_PROGRAMMATIC_RESULT=PASS`;
- human operator confirms visible `0 -> 1 -> 2 -> 0` rotation;
- human operator confirms normal return to GarlicOS.

Until then, do not promote P2C and do not move to P3/P7/P9.

## 7. What to do after a valid P2C physical PASS

Only after evidence review:

1. freeze evidence archive SHA and all observed runtime/package identities;
2. create a dedicated P2C physical-acceptance branch/record derived from the exact R3 lineage;
3. record that the tested package was built from `ceca509b...` and runtime candidate `07382810...`;
4. set only the **P2C module** physical acceptance to `PASS`;
5. keep whole-platform `RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO` and `STABLE=NO`;
6. promote P2C accepted lineage to `main` through an auditable merge mechanism;
7. update all handoff docs before beginning the next P2/P3 work unit.

## 8. Hard prohibitions still in force

```text
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
NO_NEW_TIER1_GAME_FIX=YES
NO_GAME_SPECIFIC_RUNTIME_PATCH=YES
NO_GAME_SPECIFIC_PRODUCTION_BRANCH=YES
NO_PHYSICAL_PASS_FROM_CI=YES
NO_STABLE_CLAIM_BEFORE_P8=YES
```
