# MIYOO M1.4C CORE2D JAVA5 BACKPORT BUILD A/B — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4/M1.4B prove the pinned Miyoo Java source cannot compile unchanged for the device-proven Java 1.5/JamVM baseline, but the mandatory 2D incompatibility set is bounded: three active java.nio.file users, eight files with diamond syntax, one true lambda in RecordEnumerationImpl, and real try-with-resources blocks in AndroidRecordStoreManager. java.util.function/stream usage is absent from the mandatory 2D path.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.1 JVM strategy, M1.4 source audit, M1.4A harness failure/fix, and M1.4B feasibility result before implementation. Historical project regressions show broad rewrites and premature runtime replacement are high risk. JamVM remains the only device-proven JVM on original RG35XX.

## COMPARE_WITH_PREVIOUS OCCURRENCES
Do not replace JamVM and do not port all LWJGL/3D. The next isolated variable is only whether the pinned Miyoo 2D Java source can be mechanically/boundedly converted to Java-5-compatible source/bytecode.

## CHECK_PREVIOUS FIX AND DEVICE EVIDENCE
- JamVM/GNU Classpath: DEVICE-PROVEN for existing platform, not yet for Miyoo source.
- M1.2A/M1.3A/M1.3C native video/input foundation: DEVICE-PASS scope-specific.
- M1.4B: BUILD/AUDIT evidence that bounded Java5 backport is plausible.
- Modern JVM: no DEVICE-EVIDENCE.

## CLASSIFY CURRENT STATE
CURRENT_SYMPTOM = PINNED_MIYOO_CORE2D_NEEDS_BOUNDED_JAVA5_BACKPORT
HISTORY_FOUND = YES
PREVIOUS_FIX = NO_SOURCE_PATCH_YET
PREVIOUS_EVIDENCE_LEVEL = AUDIT_ONLY
REGRESSION_RISK = MEDIUM_IF_PATCH_IS_BOUNDED_HIGH_IF_BROAD

## CHOOSE MINIMAL CHANGE
MINIMAL_PROPOSED_CHANGE = create an overlay applied to a fresh checkout of pinned source ca11dfe8ea1cc273d92460f9a83bbf192023fa63 that changes only Java-version compatibility constructs needed by the initial 2D target:
1. replace active `java.nio.file` usage in SDLConfig/PlatformPlayer with Java5 `java.io.File` operations;
2. replace MIDletLoader NIO zip filesystem/path resource access with a bounded Java5-compatible JAR/ZIP resource abstraction;
3. expand diamond operators in mandatory source files;
4. replace the single true lambda with an anonymous Comparator;
5. replace true try-with-resources in mandatory RMS code with explicit close/finally;
6. compile the initial 2D source set with Java 5 source/target and exclude optional LWJGL/M3G/micro3d code only where not required for 2D boot.

## ACCEPTANCE GATE
- fresh exact source pin verified before overlay;
- before/after source inventory recorded;
- no edits to native video/input/audio/JVM binaries;
- compiler must use a toolchain that can emit Java 5 classfile version 49;
- resulting main JAR classes must be classfile major 49;
- main class remains org.recompile.freej2me.Anbu or a narrowly documented 2D bootstrap equivalent;
- build failures must be treated as evidence to refine the bounded source set, not as device failures.

## FORBIDDEN CHANGES
No JamVM/glibj modification, no modern JVM install, no audio implementation, no SDL changes, no input changes, no font/transparency changes, no real-device install in this checkpoint, no 3D enablement, and no STABLE claim.

## EXPECTED RESULT
A BUILD-PASS Java5-compatible 2D Miyoo candidate JAR or a precise compiler blocker report. DEVICE-PASS remains NO until later real-device execution.
