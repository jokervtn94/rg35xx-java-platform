# MIYOO M1.4 JVM SOURCE COMPATIBILITY AUDIT — RESULT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1
Pinned Miyoo source: ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Successful audit run: 34870131462
Job: 104063682456
Artifact ID: 10358138783
Artifact ZIP SHA256: c6d34548ed7d328178be7af0af0cb5eeaba3005f7585be406627037ec02e03bc
Report SHA256: c37a50bcf2d9def6c7d4ae7101a3573df8f6176ef6ce64a252a448ffcb0b23cf

## Harness history
Initial run 34870009727 failed because zero-match grep count pipelines were fatal under `set -euo pipefail`. M1.4A classified this as TEST-HARNESS FAIL and fixed only zero-match counting. No JVM/source runtime evidence was inferred from the failed run.

## Reproducible audit result
- PIN_MATCH=YES
- JAVA_FILES_TOTAL=921
- JAVA_FILES_CORE2D=148
- JAVA_FILES_LWJGL_3D=633

Modern API references by file count:
- java.nio.file: total 7, core2d 3, lwjgl3d 4
- java.util.function: total 20, core2d 0, lwjgl3d 20
- java.util.stream: total 3, core2d 0, lwjgl3d 3
- java.time: 0
- Optional: 0
- Base64: 0
- StandardCharsets: 0
- java.util.Objects: total 1, core2d 0, lwjgl3d 1

Java-7+ syntax heuristic file counts:
- diamond: total 22, core2d 8
- lambda heuristic: total 14, core2d 3
- try-with-resources heuristic: total 30, core2d 4

Core2D files using java.nio.file:
1. src/org/recompile/freej2me/SDLConfig.java
2. src/org/recompile/mobile/MIDletLoader.java
3. src/org/recompile/mobile/PlatformPlayer.java

Core2D java.util.function/stream files: 0

Core2D diamond files:
- src/javax/microedition/lcdui/event/CommandActionEvent.java
- src/javax/microedition/lcdui/event/EventQueue.java
- src/javax/microedition/rms/impl/AndroidRecordStoreManager.java
- src/javax/microedition/rms/impl/RecordEnumerationImpl.java
- src/javax/microedition/rms/impl/RecordStoreImpl.java
- src/javax/microedition/util/LinkedList.java
- src/org/recompile/mobile/MIDletLoader.java
- src/org/recompile/mobile/MyMethodVisitor.java

## Classification
- CORE2D_JAVA5_COMPAT_RISK=CONFIRMED
- JAMVM_DROP_IN_AS_IS=NO
- MODERN_JVM_DEVICE_EVIDENCE=NO
- AUDIT_ONLY=YES
- DEVICE_PASS=NOT_APPLICABLE
- STABLE=NO

## Strategy decision after M1.4
Do NOT replace the device-proven JamVM yet. The mandatory 2D path does not show broad java.util.function/stream coupling; modern API use is concentrated enough to justify one further bounded feasibility checkpoint before considering a modern JVM.

Next checkpoint: M1.4B must enumerate and validate the exact Java-7+ language constructs in core2D, distinguish true code from comments/heuristic false positives, and define a minimal Java-5 backport set. No source backport is admitted until that list is precise.
