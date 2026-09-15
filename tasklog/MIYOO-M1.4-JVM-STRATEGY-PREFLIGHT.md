# MIYOO M1.4 JVM STRATEGY — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1

## IDENTIFY_CURRENT_SYMPTOM
M1 native foundation is now proven on original RG35XX for SDL1/fbcon video and raw /dev/input/js0 semantic input. The next blocker is launching the current pinned Miyoo FreeJ2ME Java source on the device's existing JamVM/GNU Classpath Java 1.5 runtime.

## SEARCH_TASKLOG_AND_HISTORY
History reviewed before implementation:
- JamVM L production binary is device-proven on original RG35XX; locked SHA256 eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34.
- GNU Classpath glibj.zip baseline is device-proven; locked SHA256 d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea.
- Device audit reports Java 1.5.0 / JamVM 2.0.0 and ~232 MiB visible RAM with no swap.
- M1.2A SDL1/fbcon video = DEVICE-PASS.
- M1.3A raw js0 input = DEVICE-PASS.
- M1.3C exact semantic keymap = DEVICE-PASS from real-device report: UP axis7-, DOWN axis7+, LEFT axis6-, RIGHT axis6+, A b0, B b1, X b2, Y b3, START b8, SELECT b7, L b5, R b6.
- Current pinned aweigit/freej2me-miyoomini source commit ca11dfe8ea1cc273d92460f9a83bbf192023fa63 is built without source/target constraints in build.xml and contains Java 7+ java.nio.file APIs plus Java 8 java.util.function/stream usage in bundled LWJGL code.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
Previous RG35XX platform work established that replacing a device-proven subsystem without device evidence creates regressions. JamVM L is already device-proven, while no Java 17 JVM has been proven on this original 256 MB/uClibc RG35XX. Therefore JVM replacement must not be the first M1.4 variable.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
Existing JamVM L + GNU Classpath: DEVICE-PROVEN for the current RG35XX Java platform.
Miyoo current Java source on JamVM L: NOT TESTED / source incompatibilities already visible.
Java 17 ARM32 JVM on original RG35XX: NO DEVICE EVIDENCE.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = CURRENT_MIYOO_SOURCE_REQUIRES_NEWER_JAVA_APIS_THAN_DEVICE_JAMVM_L
HISTORY_FOUND = YES
PREVIOUS_FIX = KEEP_DEVICE_PROVEN_JAMVM_L_UNTIL_A_MINIMAL_COMPATIBILITY_PATH_IS_MEASURED
PREVIOUS_EVIDENCE_LEVEL = JAMVM_L_DEVICE_PROVEN; MIYOO_JAVA_COMPATIBILITY_UNKNOWN
REGRESSION_RISK = HIGH_FOR_JVM_REPLACEMENT

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = source-only compatibility audit at the exact pinned Miyoo commit. Do not modify the device, JamVM, glibj, native video, native input, audio, or R2.3 fallback. Inventory Java APIs/language/library dependencies incompatible with Java 1.5 and classify each as CORE_BOOT_REQUIRED, OPTIONAL_3D/LWJGL, AUDIO_ONLY, or NON_BOOT.

The decision gate is:
1. If the M1 boot path can be reduced/backported to Java 1.5 with bounded changes while excluding optional 3D/audio, retain JamVM L for the first Java boot checkpoint.
2. If core boot intrinsically requires Java 7/8+ APIs or bytecode features across a broad dependency surface, stop and evaluate a separate newer-JVM A/B; do not silently replace JamVM L.

## FORBIDDEN CHANGES
No JVM binary replacement, no GNU Classpath patch, no Java runtime/core installation, no SDL/video/input changes, no audio work, no font/transparency work, no modification of R2.3 fallback.

## EXPECTED OUTPUT
A deterministic source audit report pinned to ca11dfe8ea1cc273d92460f9a83bbf192023fa63 containing:
- build source/target behavior;
- Java 7+ API file inventory;
- Java 8+ API/language inventory;
- boot-path vs optional subsystem classification;
- recommended M1.4A single-variable next checkpoint;
- BUILD-PASS/DEVICE-PASS/STABLE classification.

M1.4 is an audit checkpoint only. It cannot grant DEVICE-PASS or STABLE.
