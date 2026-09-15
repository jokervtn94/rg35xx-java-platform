# MIYOO M1.4A.4 MIDletLoader Java5 Resource Loader — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.3 reached the intended dependency-boundary diagnostic and FAIL_CLOSED. After Java5 syntax cleanup, MIDletLoader still requires Java 7 java.nio.file / ZIP FileSystem APIs: FileSystem, Path, Files, FileSystems, StandardOpenOption and resource Path returns. Other errors are coupled optional/deferred boundaries and must not be mixed into this checkpoint.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4A.3 preflight and M1.4A.x history before implementation. M1.4A.3 explicitly forbade MIDletLoader semantic backport and required it to remain visible as a core blocker. CI confirmed that blocker. Existing DEVICE-PROVEN JamVM L + glibj remain unchanged.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
Earlier failures were syntax and overly broad source-slice problems. M1.4A.3 now proves java.nio.file is not merely an optional-source artifact: MIDletLoader itself uses it for manifest/resource lookup and stream creation. This is a new isolated core API compatibility checkpoint, not a JVM replacement checkpoint.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
No previous Java5 MIDletLoader backport is DEVICE-PROVEN on this Miyoo branch. Therefore this work can reach BUILD-PASS only in CI. JamVM L, glibj, SDL1/fbcon video, raw js0 and exact keymap retain their previous device evidence but do not transfer DEVICE-PASS to this Java change.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = MIDLETLOADER_JAVA7_NIO_RESOURCE_ACCESS_BLOCKS_JAVA5
HISTORY_FOUND = YES
PREVIOUS_FIX = NONE_DEVICE_PROVEN
CURRENT_EVIDENCE = CI_FAIL_CLOSED

## CHOOSE_MINIMAL_CHANGE
Replace only MIDletLoader's ZIP FileSystem/Path/Files resource access with Java5-compatible java.util.jar.JarFile + JarEntry + InputStream semantics. Preserve resource-name normalization and existing manifest/resource lookup behavior as closely as possible. Do not solve audio, RMS, M3G, MyMethodVisitor or native platform issues in this checkpoint.

## PRIMARY VARIABLE
MIDLETLOADER_RESOURCE_ACCESS_JAVA7_NIO_TO_JAVA5_JARFILE

## FORBIDDEN
- no JamVM/JVM replacement
- no GNU Classpath patch
- no SDL/native change
- no audio/media implementation
- no RMS fix
- no M3G/Micro3D/LWJGL fix
- no MyMethodVisitor fix
- no R2.3 change
- no device installer

## ACCEPTANCE
1. MIDletLoader contains no active java.nio.file dependency.
2. Constructor can open the game JAR through JarFile when a filesystem JAR path is supplied.
3. Manifest and resource streams use JarEntry/JarFile InputStream.
4. Resource names with or without leading slash normalize to JAR entry names.
5. CI compiler no longer reports Path/FileSystem/Files errors from MIDletLoader.
6. Any remaining compile errors are recorded fail-closed and belong to other dependency boundaries.

BUILD-PASS = NO until compile evidence.
DEVICE-PASS = NO.
STABLE = NO.
