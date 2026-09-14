# MIYOO M1.4 JVM STRATEGY — SOURCE COMPATIBILITY AUDIT PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
Native standalone foundation is now proven on the original RG35XX for SDL1/fbcon video and raw /dev/input/js0 input, including an exact semantic keymap. The next blocker is Java runtime compatibility: the device-proven fallback JVM is JamVM 2.0.0 / Java 1.5 with GNU Classpath, while the pinned Miyoo FreeJ2ME source is documented to build with JDK 17 and contains APIs absent from Java 1.5.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed before implementation:
- M1.1 preflight explicitly recorded two later JVM candidates: (A) modern ARMv7/uClibc JVM within the <=256 MiB budget; (B) backport the minimum Miyoo Java source to the device-proven JamVM/GNU Classpath baseline.
- M1 device audit proves JamVM Java 1.5 and GNU Classpath are installed and the JamVM binary is device-proven in the existing platform.
- M1.2A, M1.3A and M1.3C prove the standalone native video/input foundation without changing the JVM.
- No historical DEVICE-PASS exists for a modern JVM on original RG35XX.

## COMPARE_WITH_PREVIOUS OCCURRENCES
Do not replace JamVM or glibj.zip yet. Do not install a modern JRE only because upstream Miyoo uses JDK17. The original RG35XX has about 232 MiB visible RAM and uClibc, so a modern JVM introduces ABI, footprint and memory risk. Conversely, a Java-1.5 backport may be large if modern APIs are spread across mandatory code paths.

Pinned upstream evidence already observed:
- build.xml has no source/target/release level and upstream README says to build with JDK17.
- SDLConfig.java imports java.nio.file.Files/Paths.
- MIDletLoader.java imports Path, Paths, Files, FileSystem, FileSystems, StandardOpenOption, DirectoryStream, StandardCopyOption and uses diamond syntax in at least one HashMap construction.
- PlatformPlayer.java imports java.nio.file.Files/Paths.
- bundled LWJGL system code imports java.nio.file, java.util.function and java.util.stream in multiple classes.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
- Existing JamVM/GNU Classpath baseline: DEVICE-PROVEN for the current Java platform, not yet for Miyoo source.
- Modern JVM on original RG35XX: no DEVICE-EVIDENCE.
- Current Miyoo source on Java 1.5: incompatible as-is by source/API inspection.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = MIYOO_JAVA_SOURCE_NOT_DROP_IN_COMPATIBLE_WITH_DEVICE_PROVEN_JAVA_1_5
HISTORY_FOUND = YES
PREVIOUS_FIX = KEEP_DEVICE_PROVEN_JAMVM_UNTIL_A_JVM_STRATEGY_IS_EVIDENCE_BASED
PREVIOUS_EVIDENCE_LEVEL = JAMVM_DEVICE_PROVEN_MODERN_JVM_UNVERIFIED
REGRESSION_RISK = HIGH_IF_JVM_REPLACED_PREMATURELY

## CHOOSE_MINIMAL CHANGE
MINIMAL_PROPOSED_CHANGE = source-only reproducible compatibility audit at the pinned Miyoo commit ca11dfe8ea1cc273d92460f9a83bbf192023fa63. The audit must not build or install a JVM and must not modify device artifacts. It will classify modern-Java dependencies into:
1. mandatory 2D boot/game path (Anbu, SDLConfig, MobilePlatform/MIDletLoader, core javax.microedition implementation),
2. audio path (PlatformPlayer/SdlMixerManager),
3. optional 3D/LWJGL path.

The audit must report file counts for java.nio.file, java.util.function, java.util.stream, diamond syntax and selected Java-7+ constructs, and separately list occurrences in the mandatory 2D path versus optional 3D/LWJGL code.

## DECISION GATE
- If mandatory 2D path requires only a small bounded set of Java-7+ APIs/syntax, next checkpoint may backport only that bounded subset while keeping JamVM.
- If mandatory 2D path is deeply coupled to modern Java/LWJGL, do not start a broad backport; evaluate a modern JVM candidate separately with strict memory/ABI gates.
- Optional 3D code must not force the M1 boot checkpoint to a modern JVM if it can be excluded from the initial 2D build.

## FORBIDDEN CHANGES
No JamVM/glibj replacement, no Java runtime installation, no game launch, no audio work, no SDL/video/input changes, no font/transparency changes, no fallback-platform changes, and no STABLE claim from CI.

## EXPECTED RESULT
Produce a machine-generated M1.4 compatibility report and source inventory from the exact pinned Miyoo commit. This checkpoint is BUILD/AUDIT evidence only; DEVICE-PASS is not applicable until a JVM/runtime candidate is actually exercised on real RG35XX.
