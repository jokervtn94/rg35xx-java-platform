# MIYOO M1.4C.2 BOUNDED JAVA6 SOURCE OVERLAY — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4C.1 corrected the compatibility target to the historically device-proven Java 6 classfile contract (major 50) and excluded optional LWJGL/M3G/micro3d code. The unmodified pinned Miyoo 2D source still fails Java 6 source compilation with 15 known language-level errors: diamond operators, two true lambdas, and try-with-resources in RMS, JSR-75 file connection, and bundled ASM. Separately, active java.nio.file usage remains in SDLConfig, PlatformPlayer, and MIDletLoader and must be removed because JDK8 compilation can hide runtime incompatibility with GNU Classpath.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed before implementation:
- M1.4 source compatibility audit and M1.4A harness fix;
- M1.4B exact feasibility result;
- M1.4C Java5 compiler-oracle result;
- M1.4C.1 Java6 target correction;
- historical From-Zero manifest/workflow proving classfile major 50 is the established RG35XX Java contract;
- historical pinned FreeJ2ME+ tree was checked for FileSystemFileConnection and did not contain a directly reusable implementation;
- pinned Miyoo `lib/` contains no ASM JAR, so bundled ASM cannot simply be dropped in favor of an existing binary dependency.

## COMPARE_WITH_PREVIOUS OCCURRENCES
Previous project regressions came from broad patch accumulation and from treating build success as device success. Therefore this checkpoint must apply one bounded compatibility overlay to a fresh exact source pin and must not alter JVM/native/runtime behavior. Optional 3D remains excluded. Build success is only BUILD-PASS.

## CHECK_PREVIOUS FIX_AND_DEVICE_EVIDENCE
- JamVM/glibj: DEVICE-PROVEN in the existing RG35XX platform.
- Java classfile major 50: historical established build/runtime contract.
- Miyoo SDL1/fbcon video and raw-js0 input foundation: scope DEVICE-PASS.
- Miyoo Java source on JamVM: NOT DEVICE-TESTED.
- Modern JVM on original RG35XX: no DEVICE-EVIDENCE.
- Current 15 Java6 source blockers: compiler evidence only, no device failure.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = BOUNDED_CORE2D_JAVA6_SOURCE_INCOMPATIBILITIES
HISTORY_FOUND = YES
PREVIOUS_FIX = NONE_ADMITTED_FOR_MIYOO_SOURCE_YET
PREVIOUS_EVIDENCE_LEVEL = SOURCE_AUDIT_AND_COMPILER_EVIDENCE
REGRESSION_RISK = MEDIUM_IF_BOUNDED_HIGH_IF_SCOPE_EXPANDS

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = apply only Java6 compatibility rewrites to the selected 2D source set from exact pin ca11dfe8ea1cc273d92460f9a83bbf192023fa63:
1. diamond operators -> explicit generic type arguments;
2. RecordEnumerationImpl and FileSystemFileConnection lambdas -> anonymous Comparator implementations;
3. true try-with-resources in AndroidRecordStoreManager, FileSystemFileConnection, ASM ClassReader/Constants -> explicit close/finally while preserving behavior;
4. SDLConfig and PlatformPlayer `Files.createDirectories(Paths.get(...))` -> `java.io.File.mkdirs()` equivalent;
5. MIDletLoader active java.nio.file ZIP/resource path -> bounded Java6 `JarFile`/`ZipFile` + java.io implementation;
6. do not touch comments-only false positives.

## SOURCE-SET LOCK
Initial boot source set MUST exclude:
- src/org/lwjgl/**
- src/javax/microedition/m3g/**
- src/ru/woesss/j2me/micro3d/**
No optional 3D code may be pulled back in to resolve unrelated compile errors.

## BUILD / FAIL-CLOSED GATES
- verify source pin before overlay;
- record before/after hashes for every changed source file;
- compile with JDK8 `-source 1.6 -target 1.6`;
- every emitted class must be major 50;
- selected source and compiled class constant pools must contain no `java/nio/file` reference;
- selected source must contain no active Java7/8 diamond/lambda/try-with-resources constructs after overlay;
- no `java/util/function` or `java/util/stream` in selected 2D source/classes;
- main/bootstrap classes must compile without optional 3D sources;
- if a new incompatibility category appears, STOP and create a new history/preflight classification before expanding the overlay.

## FORBIDDEN CHANGES
No JamVM/glibj changes, no modern JVM, no native video/input/audio changes, no device install, no font/transparency changes, no 3D enablement, no STABLE or DEVICE-PASS claim from CI.

## EXPECTED_RESULT
Either:
A. a Java6/major50 core2D candidate JAR/source package that passes all static gates and is classified BUILD-PASS only; or
B. a precise bounded compiler/static blocker report with no scope expansion.
