# MIYOO M1.4B JAVA 5 BACKPORT FEASIBILITY — RESULT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1
Pinned Miyoo source: ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Workflow run: 34870475350
Job: 104064838348
Artifact ID: 10358860809
Artifact ZIP SHA256: f1b21f68b6a0dbe7c8dcf4b42630c04215329cf7edd4e96fc003b9e0145fd349
Report SHA256: 645baec945d3966480b0e9289d7420b6cb43565e0d7fb47ffe7fcdc3f0cda1ea

## Reproducible findings
- NIO_FILE_FILES=3
- UTIL_FUNCTION_FILES=0
- UTIL_STREAM_FILES=0
- DIAMOND_FILES=8
- TRY_WITH_RESOURCES_FILES=4 by heuristic file count
- LAMBDA_OR_METHODREF_FILES=3 by heuristic file count
- BOUNDED_JAVA5_BACKPORT_CANDIDATE=YES

## Manual exact-code review after heuristic report
The heuristic report intentionally over-captures comments/text. Direct source review refined the mandatory 2D set:

### True Java 8 lambda
`src/javax/microedition/rms/impl/RecordEnumerationImpl.java`
- one real lambda in `Collections.sort(...)` at the comparator path.
- replaceable with an explicit anonymous `Comparator<EnumerationRecord>` implementation on Java 5.

### True try-with-resources
`src/javax/microedition/rms/impl/AndroidRecordStoreManager.java`
- multiple real DataInputStream/DataOutputStream try-with-resources blocks.
- this class is mandatory in this fork because `javax.microedition.rms.RecordStore` directly instantiates `new AndroidRecordStoreManager()`.
- bounded replacement: explicit close/finally preserving existing exception behavior.

`src/org/recompile/mobile/MIDletLoader.java`
- the reported DirectoryStream try-with-resources occurrence is inside a commented-out helper block and is not an active compile blocker.

### False-positive lambda/method-reference candidates
- arrow text in `PlatformPlayer.java` documentation/comment.
- arrow text in commented debug strings in `MyMethodVisitor.java`.
These are not Java language constructs.

### NIO API backport set
1. `SDLConfig.java`: `Files.createDirectories(Paths.get(...))` -> `new File(...).mkdirs()`.
2. `PlatformPlayer.java`: same directory creation replacement.
3. `MIDletLoader.java`: active NIO ZIP filesystem / Path resource access must be replaced with Java 5-compatible `java.util.jar.JarFile`/`java.util.zip.ZipFile` plus `java.io` streams or equivalent bounded resource abstraction.

### Diamond syntax
8 core2D files; mechanical replacement with explicit generic arguments.

## Classification
- Mandatory 2D path has no `java.util.function` or `java.util.stream` dependency.
- Mandatory 2D Java-7+/8 usage is bounded but includes RMS and MIDlet resource loading.
- BOUNDED_JAVA5_BACKPORT_CANDIDATE=YES.
- JamVM remains preferred for the next BUILD A/B because it is already device-proven; this does not yet prove the Miyoo source on JamVM.
- Modern JVM remains unverified and is not selected.
- DEVICE_PASS=NOT_APPLICABLE for this source-only audit.
- STABLE=NO.

## Next checkpoint
M1.4C = isolated Core2D Java5 backport BUILD A/B from exact pinned Miyoo source. The checkpoint must patch only the bounded language/API incompatibilities above, exclude optional LWJGL/3D from the initial boot target where possible, and prove Java-5-compatible bytecode/build before any device installation.
