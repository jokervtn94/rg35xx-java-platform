# MIYOO M1.4A JAVA-5 BOOT-SLICE — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4 audit established that current Miyoo source cannot be used directly with the original RG35XX JamVM/GNU Classpath Java 1.5 runtime because boot/core-adjacent source contains java.nio.file and bundled LWJGL contains a broad Java 8+ API surface.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed before implementation:
- MIYOO-M1.4-JVM-STRATEGY-PREFLIGHT.md
- MIYOO-M1.4-JVM-SOURCE-COMPAT-AUDIT.md
- device-proven JamVM L SHA256 eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- device-proven GNU Classpath SHA256 d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- M1.2A SDL1/fbcon video DEVICE-PASS
- M1.3A raw js0 DEVICE-PASS
- M1.3C exact keymap DEVICE-PASS

## COMPARE_WITH_PREVIOUS_OCCURRENCES
Historical rule: retain device-proven runtime components until a minimal alternative is proven. No newer JVM is device-proven on original RG35XX. M1.4 therefore selected source compatibility measurement before JVM replacement.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
JamVM L + GNU Classpath = DEVICE-PROVEN.
Miyoo Java source compatibility = audit only; not yet compile-proven for Java 5.
Newer JVM = no device evidence.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = JAVA5_BOOT_SLICE_FEASIBILITY_UNKNOWN
HISTORY_FOUND = YES
PREVIOUS_FIX = RETAIN_JAMVM_L_AND_MEASURE_MINIMAL_SOURCE_BACKPORT
PREVIOUS_EVIDENCE_LEVEL = JAMVM_L_DEVICE_PROVEN; SOURCE_BACKPORT_NOT_PROVEN
REGRESSION_RISK = LOW_FOR_SOURCE_ONLY_CI_AUDIT; HIGH_FOR_DEVICE_JVM_REPLACEMENT

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = CI-only pinned-source experiment that attempts a Java-5-compatible 2D boot slice. Only core boot java.nio.file usages may be mechanically backported to java.io.File equivalents. Optional LWJGL/3D and media/audio implementations are excluded from this checkpoint.

The workflow must fail closed and produce an audit artifact containing the exact source pin, patch diff, compile command, exclusions, compiler errors, and resulting class major versions if compilation succeeds.

## PRIMARY VARIABLE
JAVA5_SOURCE_COMPATIBILITY_OF_MINIMAL_2D_BOOT_SLICE_ONLY

## FORBIDDEN
- no JamVM replacement
- no glibj patch/replacement
- no device installer
- no SDL video/input change
- no audio implementation
- no font/transparency work
- no R2.3 modification
- no broad Java compatibility shim layer
- no LWJGL/3D backport

## ACCEPTANCE
PASS only if the bounded boot slice compiles with explicit Java 5 source/target semantics and generated classes are major version 49, with all exclusions enumerated. If compiler/toolchain cannot emit Java 5 or unresolved Java 6/7/8+ dependencies enter the slice, FAIL CLOSED and report the blocker.

BUILD-PASS = pending
DEVICE-PASS = NO
STABLE = NO
