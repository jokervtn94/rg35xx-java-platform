# MIYOO M1.4A.1 JAVA-5 SYNTAX BACKPORT — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Parent checkpoint: M1.4A run 34914899837 / job 104210309723
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A now executes on GitHub Actions. The bounded Java-5 compile gate fails closed with JAVAC_RC=1 and 20 first-pass syntax errors: diamond operators, try-with-resources, and lambdas. Optional ru/woesss/j2me/micro3d sources also entered the nominal 2D slice and must be excluded rather than backported.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed before implementation:
- MIYOO-M1.4-JVM-STRATEGY-PREFLIGHT.md
- MIYOO-M1.4-JVM-SOURCE-COMPAT-AUDIT.md
- MIYOO-M1.4A-JAVA5-BOOT-SLICE-PREFLIGHT.md
- M1.4A GitHub Actions run 34914899837 compiler evidence

Historical/device evidence remains unchanged:
- JamVM L SHA256 eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34 = DEVICE-PROVEN
- GNU Classpath SHA256 d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea = DEVICE-PROVEN
- M1.2A SDL1/fbcon video = DEVICE-PASS
- M1.3A raw js0 = DEVICE-PASS
- M1.3C exact semantic keymap = DEVICE-PASS

## COMPARE_WITH_PREVIOUS OCCURRENCES
M1.4A expected a fail-closed source compatibility measurement before any JVM replacement. That is exactly what occurred. This is not a recurrence of a device JVM failure and not a reason to replace JamVM.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
No previous Java-5 source backport is DEVICE-PROVEN. Existing JamVM/glibj are device-proven and must remain untouched. M1.4A CI infrastructure is now working on ubuntu-22.04; the remaining failure is source syntax compatibility.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = JAVA7_8_SYNTAX_PRESENT_IN_MINIMAL_2D_COMPILE_SET
HISTORY_FOUND = YES
PREVIOUS_FIX = M1.4A_FAIL_CLOSED_MEASUREMENT
PREVIOUS_EVIDENCE_LEVEL = CI_COMPILER_EVIDENCE_ONLY
REGRESSION_RISK = LOW_FOR_SOURCE_ONLY_MECHANICAL_BACKPORT; HIGH_FOR_JVM_REPLACEMENT

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = keep the same pinned source and Java-5 compile gate; exclude ru/woesss/j2me/micro3d as optional 3D, then mechanically backport only the exact Java 7/8 syntax families reported by M1.4A in the remaining 2D/core compile set. Do not change behavior intentionally. Re-run the compile gate and expose the next blocker fail-closed.

Allowed transformations are narrowly scoped: explicit generic constructor types for reported diamond operators; anonymous Comparator replacements for reported lambdas; ordinary try/finally close handling for reported try-with-resources. MIDletLoader java.nio.file semantic replacement is NOT broadened in this checkpoint unless reached as the next compiler blocker after syntax parsing.

## PRIMARY VARIABLE
JAVA5_SYNTAX_COMPATIBILITY_OF_THE_SAME_MINIMAL_2D_BOOT_SLICE

## FORBIDDEN
- no JamVM replacement or patch
- no glibj replacement or patch
- no device installer
- no SDL video/input changes
- no audio/media implementation
- no font/transparency work
- no R2.3 modification
- no LWJGL/M3G/MascotCapsule/micro3d backport
- no broad compatibility shim
- no claim of DEVICE-PASS from CI

## ACCEPTANCE
PASS only if the bounded slice compiles under explicit -source 5 -target 5 and every generated class has major version 49. Any unresolved API/dependency or compiler incompatibility must FAIL CLOSED with evidence.

BUILD-PASS = pending
DEVICE-PASS = NO
STABLE = NO
