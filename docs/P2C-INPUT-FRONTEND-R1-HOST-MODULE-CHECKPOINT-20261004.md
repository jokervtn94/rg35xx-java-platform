# P2C Input / Frontend R1 — Host/Module Checkpoint

Date: 2026-10-04

## Scope

This checkpoint records the completed **host/module gate** for the P2C Input / Frontend module. It does not constitute original-RG35XX physical acceptance, does not promote P2 to complete, and does not mark the generic platform stable.

```text
PROJECT=RG35XX-AWEIGIT-R1
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_OFFICIAL_PARENT=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
P2B_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2C_RUNTIME_CANDIDATE_COMMIT=0738281012b83d748cfb88ba063d21248a3f9c97
HOST_GATE_HEAD=0851cfde1da41c955997a693ac6df34557d76093
P2C_HOST_MODULE_GATE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED
P2=PARTIAL
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

## Hardware prerequisite

The P2C hardware capability diagnostic on the original RG35XX established the complete 14-control inventory before the runtime candidate was opened. In particular:

```text
P2C_HARDWARE_EVIDENCE=PASS_14_CONTROL_CALIBRATION
L2=/dev/input/js0 axis 2 baseline -32767 press 32767 release -32767
R2=/dev/input/js0 axis 5 baseline -32767 press 32767 release -32767
```

The native owner correction permits the evidence-driven `rg35xx_input.c` delta only for the measured hardware capability. The candidate does not introduce a second Java `/dev/input/js0` reader.

## Runtime owner scope

The semantic runtime commit is `0738281012b83d748cfb88ba063d21248a3f9c97`. Relative to the exact official P2B parent, the P2C runtime scope is limited to:

```text
adapter/native/rg35xx_input.c
adapter/java/org/recompile/rg35xx/RG35XXFrontendPolicy.java
adapter/java/org/recompile/rg35xx/RG35XXKeyDispatcher.java
adapter/java/org/recompile/rg35xx/RG35XXLauncher.java
```

All commits after the runtime commit through `HOST_GATE_HEAD` are test/build/workflow infrastructure only. They do not change the four runtime owner files.

The candidate preserves the established 12 input bits and adds only:

```text
BIT12=L2_FROM_JS0_AXIS2
BIT13=R2_FROM_JS0_AXIS5
```

At the Java/frontend boundary it implements the pinned Miyoo platform contract without modifying canonical MIDP classes:

- Miyoo default physical roles for D-pad, A/B/X/Y, Select/Start, L1/R1/L2/R2;
- `keymap.cfg` role remapping with default fallback;
- phone modes `p -> n -> e -> s -> m -> p`, default `p`, persisted per app;
- Select+Start phone-mode switching;
- Select+Y virtual pointer mode, D-pad movement and X pointer confirm through `MobilePlatform.pointerPressed/Released`;
- Select+B frontend rotation with corresponding D-pad remapping;
- launch-time logical width/height retained as the P2 resolution contract;
- no `resizeLCD` import into P2C; dynamic resize remains P3.

Canonical `Canvas`, `GameCanvas`, and `MobilePlatform` event semantics remain unchanged.

## Accepted P2B reconstruction authority

P2C reconstructs the accepted P2B parent in an isolated exact-parent worktree. Raw JAR/ZIP container SHA is not used as a rebuild identity because archive timestamps are non-semantic. The stable accepted P2B semantic authority is:

```text
ACCEPTED_P2B_PHYSICAL_PACKAGE_JAR_SHA256=6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4
ACCEPTED_P2B_SEMANTIC_SHA256=4a9419720837c58ff3d3a5ce928e791318eb3c800b452fdd7c2411b536f7348f
ACCEPTED_P2B_FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
ACCEPTED_P2B_VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
```

This distinction was required because independently rebuilt P2B JARs had stable semantic content but different raw archive hashes.

## Final host/module CI

```text
WORKFLOW=P2C Input Frontend Candidate R1
RUN_ID=37141905525
JOB_ID=111257926132
HOST_GATE_HEAD=0851cfde1da41c955997a693ac6df34557d76093
ARTIFACT_ID=11280473640
ARTIFACT_NAME=RG35XX-P2C-INPUT-FRONTEND-R1-0851cfde1da41c955997a693ac6df34557d76093
ARTIFACT_ZIP_SHA256=d0e8677bb5c73e08a540b0cea6c66dfa21efe53d855b90cea6f38fa504e35ee0
WORKFLOW_RESULT=PASS
```

The final artifact was independently unpacked and its `SHA256SUMS.txt` verified after all wrapper-owned identity additions.

## Candidate artifact identity

```text
P2C_PLATFORM_JAR_SHA256=533442c7e67965c8ac095898bfb32c9fcdd233471cd19e64ca2012ceaca00c60
P2C_INPUT_NATIVE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
P2C_PARENT_INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
P2C_FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
P2C_VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
```

The input native hash is intentionally different from the accepted P2B parent and is the evidence-driven P2C owner delta. Font and video native hashes remain byte-identical to accepted P2B.

## Gate results

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
P2C_FRONTEND_HOST_GATE=PASS
P2C_NATIVE_EXISTING_12_CONTROL_GATE=PASS
P2C_NATIVE_L2_AXIS2_GATE=PASS
P2C_NATIVE_R2_AXIS5_GATE=PASS
P2C_NATIVE_14_CONTROL_HOST_GATE=PASS
P2C_ARM_INPUT_NATIVE_BUILD=PASS
P2C_PARENT_ACCEPTED_CLASS_IDENTITY=PASS
P2C_VIDEO_PARENT_IDENTITY=PASS
P2C_FONT_PARENT_IDENTITY=PASS
P2C_LAUNCH_RESOLUTION_CONTRACT_GATE=PASS
P2C_FINAL_OUTPUT_HASH_GATE=PASS
P2C_HOST_MODULE_GATE=PASS
```

The generated JAR delta is restricted to the RG35XX frontend owner classes. Parent accepted non-P2C classes are byte-identical.

## Physical boundary

Host/module PASS authorizes construction of a P2C module-level physical package only. It does not authorize a `main` promotion.

The physical exerciser must remain platform-generic and use public MIDP behavior to verify at least:

1. original-RG35XX default 14-control delivery, including L2/R2;
2. frontend phone-mode hotkey behavior;
3. virtual pointer pressed/released delivery;
4. rotation behavior including direction remap plus human presentation observation;
5. non-default launch-time logical resolution;
6. normal exit back to GarlicOS;
7. runtime/package hash evidence before and after execution.

No commercial game is part of this module acceptance surface.

```text
NEXT_LEGAL_ACTION=P2C_BUILD_MODULE_PHYSICAL_PACKAGE
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
```
