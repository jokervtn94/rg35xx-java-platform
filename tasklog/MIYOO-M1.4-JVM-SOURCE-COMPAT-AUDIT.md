# MIYOO M1.4 JVM SOURCE COMPATIBILITY AUDIT

Date: 2026-09-15
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Target device runtime: JamVM 2.0.0 / Java 1.5.0 + GNU Classpath

## BUILD CONTRACT
Pinned upstream `build.xml` invokes Ant `<javac>` without `source`, `target`, or `release`. Therefore its output bytecode level follows the JDK used for the build; the current upstream build is not constrained to Java 5 bytecode.

## DIRECT CORE/BOOT COMPATIBILITY FINDINGS
The current source is not directly runnable on the locked Java 1.5 runtime.

Known boot/core-adjacent Java 7+ usage:
- `src/org/recompile/freej2me/SDLConfig.java`: imports `java.nio.file.Files` and `java.nio.file.Paths`; uses `Files.createDirectories(Paths.get(...))`.
- `src/org/recompile/mobile/MIDletLoader.java`: imports `java.nio.file.Path`, `Paths`, `Files`, and `FileSystem`.
- `src/org/recompile/mobile/PlatformPlayer.java`: imports `java.nio.file.Files` and `Paths`; this is media/audio path and should be excluded from the first boot-only experiment where possible.

These APIs do not exist in Java 1.5/GNU Classpath baseline and must be backported to `java.io.File`/stream equivalents or excluded before JamVM L can load the affected classes.

## OPTIONAL / 3D DEPENDENCY SURFACE
Bundled `src/org/lwjgl/**` contains extensive Java 8+ dependencies including `java.util.function.*`, `java.util.stream.*`, and additional `java.nio.file.*` usage. This is a broad incompatibility surface and must NOT be backported wholesale as part of M1 boot.

Examples found at the pinned commit include:
- `org/lwjgl/system/APIUtil.java`: java.nio.file.*, java.util.function.*, java.util.stream.*
- `org/lwjgl/system/Library.java`: java.nio.file.*, java.util.function.*
- `org/lwjgl/system/LibraryResource.java`: java.nio.file.*, java.util.function.*
- `org/lwjgl/system/SharedLibraryLoader.java`: java.nio.file.*, java.util.function.*
- `org/lwjgl/system/Platform.java`: java.util.function.*
- `org/lwjgl/system/StructBuffer.java`: java.util.function.*, java.util.stream.*
- many generated platform/struct classes also expose java.util.function types.

Classification: OPTIONAL_3D/LWJGL for the first M1 Java boot checkpoint unless static references from the boot path prove otherwise.

## STRATEGY DECISION
Do NOT replace the device-proven JamVM L yet.
Do NOT attempt to make all current Miyoo/LWJGL source Java-5-compatible in one patch.

Recommended M1.4A single-variable checkpoint:
**Java-5 boot-slice compile audit**.

Create a pinned source worktree and compile only the minimal 2D FreeJ2ME boot slice with Java 5 source/target constraints after narrowly replacing core boot `java.nio.file` calls with `java.io.File` equivalents and excluding optional LWJGL/3D and audio implementation classes. The purpose is to determine whether the 2D launcher/MIDlet boot path can be made Java-5-compatible without JVM replacement.

M1.4A acceptance:
- source pin unchanged;
- no device files modified;
- no JVM/glibj replacement;
- compile gate explicitly targets Java 5-compatible bytecode/toolchain semantics;
- every exclusion is enumerated;
- if unresolved Java 6/7/8+ dependency reaches the boot slice, FAIL CLOSED and report it rather than adding broad shims.

## CLASSIFICATION
M1.4_SOURCE_AUDIT = PASS
BUILD-PASS = N/A (audit only)
DEVICE-EVIDENCE = existing JamVM/device facts only; no new runtime evidence
DEVICE-PASS = NO
STABLE = NO
FULL_MIYOO_PLATFORM_DEVICE_PASS = NO

## NEXT
M1.4A = isolated Java-5 boot-slice compile feasibility checkpoint. Only after that result should we decide between retaining JamVM L and opening a newer-JVM A/B.
