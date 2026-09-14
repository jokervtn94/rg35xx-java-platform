# MIYOO M1.4B JAVA 5 BACKPORT FEASIBILITY — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4 proves the pinned Miyoo source cannot run unchanged on the device-proven JamVM/GNU Classpath Java 1.5 baseline. However, modern API use in the mandatory 2D path is concentrated: java.nio.file appears in only 3 core2D files, while java.util.function and java.util.stream appear only in optional LWJGL/3D code.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.1 JVM strategy, M1.4 audit result and M1.4A harness-fix history before implementation. JamVM remains device-proven only for the existing Java platform. No modern JVM has device evidence on original RG35XX.

## COMPARE_WITH_PREVIOUS OCCURRENCES
Previous broad patch accumulation caused regressions. Therefore do not start a large Java source rewrite. First verify whether Java-7+ syntax/API usage in the 2D path is small and mechanically replaceable.

## CHECK_PREVIOUS FIX AND DEVICE EVIDENCE
- JamVM L / GNU Classpath baseline: DEVICE-PROVEN for existing platform.
- M1 native SDL1/fbcon + raw-js0 foundation: DEVICE-PASS scope-specific.
- Miyoo Java source on Java 1.5: not drop-in compatible.
- Modern JVM on RG35XX: no DEVICE-EVIDENCE.

## CLASSIFY CURRENT STATE
CURRENT_SYMPTOM = NEED_EXACT_BOUNDED_JAVA5_BACKPORT_SET
HISTORY_FOUND = YES
PREVIOUS_FIX = SOURCE_ONLY_AUDIT_IDENTIFIED_CONCENTRATED_CORE2D_MODERN_USAGE
PREVIOUS_EVIDENCE_LEVEL = BUILD_AUDIT_ONLY
REGRESSION_RISK = LOW_FOR_SOURCE_ONLY_FEASIBILITY_AUDIT

## CHOOSE MINIMAL CHANGE
MINIMAL_PROPOSED_CHANGE = source-only M1.4B audit that enumerates exact non-comment occurrences in the core2D path for:
- diamond operator `<>`;
- try-with-resources;
- lambda/method-reference syntax;
- java.nio.file imports and calls;
- Java-7+ utility APIs already identified.

The report must identify each file and line, then classify replacements as:
A. mechanical syntax-only backport;
B. bounded API substitution using java.io / java.util available in Java 5;
C. coupled/unsafe and therefore a blocker.

## DECISION GATE
Proceed to an actual Java-5 source backport only if mandatory 2D occurrences are bounded and no core2D dependency requires java.util.function/stream or broad LWJGL inclusion. Otherwise stop and evaluate a modern JVM as a separate checkpoint.

## FORBIDDEN CHANGES
No source patching in this checkpoint, no JVM/JamVM/glibj changes, no Java runtime installation, no device modification, no audio/video/input changes, no game launch.

## EXPECTED RESULT
A reproducible exact-line feasibility report from pinned source ca11dfe8ea1cc273d92460f9a83bbf192023fa63. BUILD/AUDIT evidence only; DEVICE-PASS not applicable.
