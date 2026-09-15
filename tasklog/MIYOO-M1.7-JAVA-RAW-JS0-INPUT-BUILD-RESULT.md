# MIYOO M1.7 — JAVA -> RAW JS0 INPUT BUILD RESULT

## Classification

BUILD-PASS = YES
DEVICE-EVIDENCE = NO_FOR_M1.7_INTEGRATED_JAVA_INPUT
DEVICE-PASS = NO
FULL_PLATFORM_STABLE = NO

## Mandatory history context

Tasklog-first preflight remains authoritative. M1.3A raw `/dev/input/js0` and M1.3C exact semantic keymap have historical real-device evidence. M1.6 Java -> JNI -> SDL1/fbcon display is DEVICE-PASS. M1.7 adds only the Java/JNI raw-js0 input bridge and does not alter those proven foundations.

The first M1.7 run 34934879829 failed only at an invalid workflow preflight string gate. No compiler/JNI/input step executed. That harness-only mismatch was recorded separately and repaired without changing the M1.7 implementation variable.

## Successful build identity

- Branch: rg35xx-miyoo-platform-v1
- Head SHA: 9fbe5793a7c26c580740640ffe042d5703fd2c2f
- Workflow run: 34935119599
- Job: 104271267153
- Conclusion: success
- Artifact ID: 10382803809
- Artifact name: rg35xx-miyoo-m1.7-java-js0-input
- Artifact size: 7917 bytes
- Artifact digest: sha256:5799b7940212182bb185ccc11f0fafd6b9494d75f85284df902e68caceb6b44f

## Build gates

- Preflight gate = PASS
- Java5 input probe compile = PASS
- Java class major = 49
- ARM uClibc JNI bridge build = PASS
- ELF32 = PASS
- Machine ARM = PASS
- Version5 EABI = PASS
- soft-float ABI = PASS
- `/dev/input/js0` source gate = PASS
- locked M1.3C mapping source gates = PASS
- SDL/audio/mixer/fbcon exclusion gate = PASS
- flat GarlicOS package checksum verification = PASS

Expected Java compiler warnings about obsolete source/target 1.5 were present. Cross compiler warned that host JDK JNI header paths are unsafe paths for cross-compilation; these were header-path warnings only and the ARM/uClibc binary and ABI gates passed. No change is admitted from these warnings without a future tasklog-first reason.

## Built hashes

- libm1_7_input.so SHA256: 1715759353dd61eb446e2ab1902d52b71ee4f8800780f24aa1e7c37ba5f7c88e
- m1.7-input-probe.jar SHA256: f813b193f556ba999c06c004e39233d4ed5788f20c6f118a2f78ca181d1caff8

## Device test contract

Install/merge `Roms` at the SD root and run `M1.7-DEVICE-TEST.sh` from GarlicOS Apps. Press controls in exact order:

UP -> DOWN -> LEFT -> RIGHT -> A -> B -> X -> Y -> START -> SELECT -> L -> R

Expected result files:
- `/mnt/mmc/RG35XX-MIYOO-M1.7-DEVICE-RESULT.txt`
- `/mnt/mmc/RG35XX-MIYOO-M1.7-JAMVM.log`

M1.7 cannot be classified DEVICE-PASS until the real RG35XX recognizes all 12 controls through Java/JNI/raw-js0, exits normally without hard hang, and protected JamVM/glibj hashes remain unchanged.
