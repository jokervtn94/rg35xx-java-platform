# P2C Input / Frontend Host-Module Checkpoint — 2026-10-03

## Status

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
P2C_HOST_MODULE_GATE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

This checkpoint records host/module evidence only. It does not promote P2C to physical acceptance, does not change `main`, and does not authorize game-specific compatibility work.

## Exact authority and lineage

```text
CANONICAL_SOURCE=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_ACCEPTED_PARENT=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
P2B_ACCEPTED_RUNTIME=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2C_RUNTIME_CANDIDATE_COMMIT=0738281012b83d748cfb88ba063d21248a3f9c97
P2C_HOST_GATE_HEAD=0851cfde1da41c955997a693ac6df34557d76093
RUNTIME_COMMITS_AFTER_07382810=NONE
```

Repository comparison from runtime candidate `0738281012b83d748cfb88ba063d21248a3f9c97` through host-gate head `0851cfde1da41c955997a693ac6df34557d76093` contains only build/workflow/test harness files. No Java/native runtime owner changed after the runtime candidate commit.

## Final CI authority

```text
WORKFLOW=P2C Input Frontend Candidate R1
RUN_ID=37141905525
JOB_ID=111257926132
RUN_HEAD=0851cfde1da41c955997a693ac6df34557d76093
RUN_RESULT=PASS
ARTIFACT_ID=11280473640
ARTIFACT_NAME=RG35XX-P2C-INPUT-FRONTEND-R1-0851cfde1da41c955997a693ac6df34557d76093
ARTIFACT_SIZE_BYTES=984545
ARTIFACT_DIGEST_SHA256=d0e8677bb5c73e08a540b0cea6c66dfa21efe53d855b90cea6f38fa504e35ee0
ARTIFACT_EXPIRES_AT=2027-01-01T17:49:11Z
```

The final artifact manifest was independently rechecked after download. Every entry in `SHA256SUMS.txt` verified successfully.

## Candidate identities

```text
P2C_PLATFORM_JAR_SHA256=533442c7e67965c8ac095898bfb32c9fcdd233471cd19e64ca2012ceaca00c60
P2C_INPUT_NATIVE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
P2C_PARENT_INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
P2C_FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
P2C_VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
ACCEPTED_P2B_PHYSICAL_PACKAGE_JAR_SHA256=6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4
ACCEPTED_P2B_SEMANTIC_SHA256=4a9419720837c58ff3d3a5ce928e791318eb3c800b452fdd7c2411b536f7348f
```

The P2B reconstruction gate uses the stable semantic JAR digest rather than the raw ZIP/JAR container digest. Raw rebuilt JAR bytes are not reproducible because ZIP entry timestamps vary; the accepted physical-package raw JAR hash remains historical evidence only.

## Runtime owner scope proven by the candidate

The changed P2C JAR entries are exactly:

```text
org/recompile/rg35xx/RG35XXFrontendPolicy.class
org/recompile/rg35xx/RG35XXKeyDispatcher.class
org/recompile/rg35xx/RG35XXLauncher$1.class
org/recompile/rg35xx/RG35XXLauncher$FramePresenter.class
org/recompile/rg35xx/RG35XXLauncher$InputPump.class
org/recompile/rg35xx/RG35XXLauncher.class
```

The native input owner changes only `librg35xx_input.so`, based on the original-RG35XX 14-control hardware evidence. Canonical MIDP `Canvas` / `GameCanvas` and `MobilePlatform` semantics remain unchanged. Protected video and font native identities remain unchanged.

## Host/module gates

```text
P2C_CANONICAL_DIFF_VERIFIED=PASS
P2C_OWNER_SCOPE_VERIFIED=PASS
P2C_JAVA6_GATE=PASS
P2C_FRONTEND_HOST_GATE=PASS
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
P2C_PARENT_ACCEPTED_CLASS_IDENTITY=PASS
P2C_VIDEO_PARENT_IDENTITY=PASS
P2C_FONT_PARENT_IDENTITY=PASS
P2C_LAUNCH_RESOLUTION_CONTRACT_GATE=PASS
P2C_FINAL_OUTPUT_HASH_GATE=PASS
P2C_HOST_MODULE_GATE=PASS
```

Original-RG35XX hardware ownership retained from the prerequisite capability diagnostic:

```text
KEYMAP_COUNT=14
L2=JS0_AXIS2_BASELINE_-32767_PRESS_32767_BIT12
R2=JS0_AXIS5_BASELINE_-32767_PRESS_32767_BIT13
```

## Launch resolution phase boundary

P2C launch-time logical resolution is complete at the Java/frontend boundary: `RG35XXLauncher` accepts arbitrary positive width/height and constructs `MobilePlatform(width,height)` with no owner-side call to `resizeLCD`.

Dynamic runtime resize remains deferred to P3 by the locked phase contract. The older production shell hardcoded `240x320`; replacing that hardcoded package policy belongs to the later generic package path and is not grounds for modifying the P2C runtime candidate.

## Physical gate boundary

Physical testing is now legal only at module level. It must use the exact host-gated runtime identities above and must not substitute a game corpus for the module exerciser.

The physical package must prove on an original RG35XX:

1. exact runtime/package hashes before execution;
2. all 14 physical controls, including L2/R2 hardware owners;
3. pinned Miyoo default physical role mapping at the `MobilePlatform` boundary;
4. p/n/e/s/m phone-mode cycle and persistence;
5. `keymap.cfg` remapping/fail-safe policy;
6. Select+Start phone-mode hotkey behavior without stuck key state;
7. Select+Y virtual pointer mode and X pointer confirm through public MIDP pointer events;
8. Select+B rotation plus logical D-pad remap/presentation behavior;
9. launch at a non-240x320 logical resolution to prove the launch-time resolution contract;
10. protected runtime hashes remain as required by the accepted parent lineage;
11. normal exit and return to GarlicOS.

No commercial game is part of this P2C physical acceptance gate.

## Locked next action

```text
NEXT_LEGAL_ACTION=P2C_BUILD_MODULE_LEVEL_PHYSICAL_PACKAGE_FROM_THIS_CHECKPOINT
PHYSICAL_TEST_LEVEL=MODULE
P2C_PHYSICAL_TEST=NOT_TESTED
P2=PARTIAL
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```
