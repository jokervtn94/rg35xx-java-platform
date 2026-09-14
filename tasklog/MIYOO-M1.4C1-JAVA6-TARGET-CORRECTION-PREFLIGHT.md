# MIYOO M1.4C.1 JAVA6 TARGET CORRECTION — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4C baseline compiler oracle was intentionally run with `-source 1.5 -target 1.5` and exposed modern syntax blockers. Historical From-Zero evidence was then re-read and shows the device-proven RG35XX runtime is explicitly gated to Java classfile major 50 (Java 6), not major 49.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed `docs/FROM-ZERO-DEVICE-PROVEN-MANIFEST-v1.md` and `.github/workflows/from-zero-rebuild-v1.yml` on branch `rg35xx-from-zero-rebuild-v1`.
Historical workflow checks every class and fails unless `major == 50`, printing `FROM_ZERO_JAVA_MAJOR=50`. That runtime was staged against the same pinned JamVM/glibj family.

## COMPARE_WITH_PREVIOUS OCCURRENCES
The new Miyoo strategy must not invent a stricter Java5 bytecode requirement than the proven platform. Source-level Java7/8 constructs still need removal, but the bytecode target should preserve the historical Java6 contract.

## CHECK_PREVIOUS FIX AND DEVICE EVIDENCE
- Java major 50 runtime contract: historical BUILD gate and part of device-proven From-Zero foundation lineage.
- JamVM/glibj hashes remain locked and unchanged.
- M1.4C Java5 compile was only an oracle; it produced no runtime and no device evidence.

## CLASSIFY CURRENT STATE
CURRENT_SYMPTOM = M1_4C_TARGET_TOO_STRICT_VS_DEVICE_PROVEN_HISTORY
HISTORY_FOUND = YES
PREVIOUS_FIX = FROM_ZERO_RUNTIME_GATED_TO_JAVA_MAJOR_50
PREVIOUS_EVIDENCE_LEVEL = HISTORICAL_DEVICE_PROVEN_PLATFORM_CONTRACT
REGRESSION_RISK = LOW_IF_ONLY_BUILD_TARGET_AND_SOURCE_SET_ARE_CORRECTED

## CHOOSE MINIMAL CHANGE
MINIMAL_PROPOSED_CHANGE = keep the exact pinned Miyoo source and compiler-oracle approach, but change the compatibility target to Java 6 (`-source 1.6 -target 1.6`, classfile major 50) and correct the initial 2D source exclusion list so optional `ru/woesss/j2me/micro3d` does not enter the boot checkpoint.

Do not patch Java source in this correction checkpoint. Re-run the compiler to obtain the precise Java6 blocker set. This isolates target/source-set correction from later source backports.

## FORBIDDEN CHANGES
No JVM/glibj replacement, no Java source compatibility patch yet, no native/audio/video/input changes, no device install, no 3D enablement.

## ACCEPTANCE
- exact source pin matches;
- corrected 2D source list excludes LWJGL, M3G and ru/woesss micro3d;
- compiler is JDK8 emitting Java6-compatible output if source compiles;
- any compile failure is recorded as source evidence only;
- no DEVICE-PASS/STABLE claim.
