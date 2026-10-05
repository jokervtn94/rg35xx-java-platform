# RG35XX Miyoo Full Port R1 — Host Ready Checkpoint — 2026-10-05

## Status

```text
HOST_BUILD=PASS
INDEPENDENT_ZIP_GATE=PASS
P5_GENERIC_INSTALLER_HOST=PASS
P6_FULL_PLATFORM_HOST_BUILD=PASS
P6_ORIGINAL_RG35XX_PHYSICAL=NOT_TESTED
P7_TIER0_REGRESSION=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
```

This checkpoint records a host/CI-ready full-port integration candidate only. It is not a physical-device acceptance and is not a stable promotion.

## Lineage

```text
BRANCH=platform-integration/rg35xx-miyoo-full-port-r1
PRODUCTION_PARENT=8cd4f6b2b08d9fbc009719e4d6148f1726972b7b
PRODUCTION_PARENT_ROLE=P3_PHYSICAL_ACCEPTED_LINEAGE
BUILD_HEAD=5d22eb75d1cd397a5c35527cd78114974503a57c
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A9_PARENT=NO
```

The integration branch is directly based on the accepted P3 lineage. P4/capability diagnostics are evidence inputs only and are not production ancestry.

The code diff from P3 accepted parent through the CI build head adds integration/package/test infrastructure only; it does not modify existing accepted P1-P3 runtime/platform source files.

## CI evidence

```text
WORKFLOW=RG35XX Miyoo Full Port R1
WORKFLOW_RUN=37257377899
WORKFLOW_CONCLUSION=success
JOB=111597246111
ACTIONS_ARTIFACT_ID=11323306446
ACTIONS_ARTIFACT_NAME=RG35XX-MIYOO-FULL-PORT-R1-5d22eb75d1cd397a5c35527cd78114974503a57c
ACTIONS_ARTIFACT_SHA256=12a6d78cd8b3592d9df294a76db6fa33d1bf16fa82ca97c11b471ec112dc78f9
DEVICE_PACKAGE=RG35XX-MIYOO-FULL-PORT-R1.zip
DEVICE_PACKAGE_SHA256=d79f416538a32e43c8c4b666658a50dd367a176f712bbe6c74809833a9201d9b
```

The Actions artifact digest identifies the outer GitHub artifact wrapper. `DEVICE_PACKAGE_SHA256` identifies the inner SD package that is copied to the original RG35XX.

## Independent final-package gates

```text
FULL_PORT_R1_INDEPENDENT_HASH_GATE=PASS
FULL_PORT_R1_NO_CFW_JAVA_MUTATION=PASS
FULL_PORT_R1_DEFERRED_3D_GATE=PASS
FULL_PORT_R1_JAVA6_GATE=PASS
FULL_PORT_R1_GAME_SPECIFIC_CODE=NO
FULL_PORT_R1_DEVICE_PASS=NO
FULL_PORT_R1_STABLE=NO
```

Shell syntax for both final launchers was also checked after extracting the inner device ZIP.

## Final platform/runtime identities

```text
PLATFORM_JAR_SHA256=b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117
INPUT_NATIVE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
RUNTIME_JAMVM_SHA256=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
RUNTIME_GLIBJ_SHA256=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
RUNTIME_CLASSES_SHA256=ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86
```

The runtime candidate remains an integration/runtime input and is not promoted as the protected A8 Golden runtime.

## Installed SD layout

```text
/mnt/mmc/Roms/APPS/FreeJ2ME-RG35XX.sh
/mnt/mmc/Roms/APPS/FreeJ2ME-RG35XX/
/mnt/mmc/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh
/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime/
/mnt/mmc/Roms/JAVA/
```

The runtime is intentionally kept at the exact path used when it was built and physically exercised:

```text
/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime
```

R1 does not install or overwrite `/mnt/mmc/CFW/java`.

## P5 generic launch contract

For one JAR placed in `/mnt/mmc/Roms/JAVA`, the generic launcher can select it automatically. When more than one JAR is present, `selected.txt` may contain the selected filename on its first line. An explicit launch is also supported:

```text
/mnt/mmc/Roms/APPS/FreeJ2ME-RG35XX.sh /mnt/mmc/Roms/JAVA/example.jar 176 208
```

Per-JAR data and RMS storage are isolated under the R1 application directory.

## P6 physical campaign

After copying the `SD/` contents to the original RG35XX GarlicOS card, run:

```text
/mnt/mmc/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh
```

The campaign uses one evidence directory:

```text
/mnt/mmc/RG35XX-FULL-PORT-R1-EVIDENCE/
```

It runs the final integrated payload through:

1. identity/runtime/native hash gates;
2. P5 generic launcher + P6 lifecycle/resource/resolution integration exerciser;
3. accepted P1 graphics exerciser;
4. accepted P2A image decode exerciser;
5. accepted P2B font/text exerciser;
6. accepted P2C input/frontend phase 1;
7. accepted P2C input/frontend phase 2 with custom keymap, pointer and rotation;
8. accepted P2C input/frontend phase 3 invalid-keymap fallback;
9. accepted P3 RMS/FileConnection/MMAPI runtime-service exerciser.

The tester must additionally confirm:

```text
FULL_PORT_R1_AUDIO_AUDIBLE=PASS
FULL_PORT_R1_P2C_ROTATION_VISUAL=PASS
FULL_PORT_R1_NORMAL_RETURN_TO_GARLICOS=PASS
```

Programmatic PASS without these physical observations is not DEVICE-PASS.

## Deferred capability policy

```text
P4_DEFERRED_CAPABILITY_DECISION=PASS
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
BLUETOOTH_JSR82=DEFER_CAPABILITY
SENSOR_JSR256=DEFER_CAPABILITY
```

The earlier physical capability audit showed that the exact EGL default/GBM routes required by pinned Miyoo do not initialize on the measured original RG35XX. R1 therefore proceeds without blindly enabling these stacks.

## Promotion rule

If the P6 full-platform campaign passes on the original RG35XX, the next required gate is P7 Tier-0 regression with Vua Cướp Biển and God of War, including audible God of War audio. Only after P7 passes may P8 baseline promotion be considered.
