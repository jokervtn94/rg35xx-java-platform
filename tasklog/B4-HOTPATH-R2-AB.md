# B4-HOTPATH-R2-AB — Bound RG35XX Java frame diagnostics

Status: SOURCE-CREATED / BUILD-PENDING / DEVICE-TEST-PENDING / STABLE=NO
Primary variable: UNBOUNDED_FRAME_TRANSPORT_DIAGNOSTICS_ONLY

## Preflight

### CURRENT_SYMPTOM

After B4-VIDEO-MASK-R2-AB, the physical RG35XX LCD no longer shows the previous global green-screen / green-tint symptom.

The same R2 device evidence still contains excessive Java hot-path diagnostics:
- Java log lines: 25918
- RG35XX-JAVA-DIAG lines: 25840

This is an observability/timing problem, not evidence that video transport is broken. Real Football and KDTT both continued producing frame requests and reached native CORE_DEINIT in the captured sessions.

### HISTORY_FOUND

VC7R22 previously isolated this exact class of overhead:
- per-request/per-frame RG35XX-JAVA-DIAG writes in RG35XXGoldenFrameTransport;
- diagnostic image/fullscreen/color probes in later experimental branches.

The historical VC7R22 cleanup reached BUILD-PASS but was bundled in a larger audio-era checkpoint and was never admitted as a DEVICE-PASS hotpath fix for the current clean B4 foundation.

### PREVIOUS_FIX

Historical VC7R22 removed executable RG35XX-JAVA-DIAG frame writes and kept real RG35XX-VIDEO JAVA error diagnostics.

### PREVIOUS_EVIDENCE_LEVEL

- Historical VC7R22 hotpath cleanup: BUILD-PASS.
- B4-VIDEO-MASK-R2 green-tint fix: DEVICE-PASS for the green-tint symptom.
- Current B4 core/JamVM/glibj hashes: protected.

### REGRESSION_RISK

Current B4 is cleaner than the old VC7R22 branch. The historical script also expects VC7R5/VC7R9/VC7R13 probe helpers which are not admitted in current B4.

Therefore this checkpoint must not replay the entire VC7R22 script.

The only file changed by this checkpoint is:
src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java
inside the disposable B4+R2 assembly.

Preserve unchanged:
- B4-VIDEO-MASK-R2 software LCD-mask bypass;
- JamVM L;
- GNU Classpath;
- B4 native core;
- B4 native early/video observability;
- Lazy Media;
- RGB565 transport protocol and byte order;
- worker synchronization;
- Smart-Fit;
- audio;
- font;
- resolution;
- game JARs.

### MINIMAL_PROPOSED_CHANGE

Remove only unbounded frame/request stderr diagnostics:
- requestFrame ENTER/REJECTED/SIGNALED
- sendControlFrame ENTER/REJECTED
- FrameWorker WAKE
- sendFrame START
- snapshot LOCK/COPIED
- RGB565 ENCODED
- IPC WRITE header/payload
- IPC FLUSH PASS

Preserve bounded lifecycle diagnostics:
- FrameTransport constructor ENTER
- LUT READY
- FrameWorker STARTED
- FrameTransport shutdown
- FrameWorker ENTER
- FrameWorker STOP
- FrameWorker EXIT

Preserve error diagnostics:
- control-frame error
- worker error
- invalid snapshot

No audio/core/font/video-semantics change is allowed.

### EXPECTED_DEVICE_TEST

Use Real Football 2015 first.

Acceptance:
1. Installer accepts only exact B4-VIDEO-MASK-R2 runtime + protected B4 core/JamVM/glibj.
2. Physical LCD keeps the R2 normal-color result; green tint must not return.
3. Input remains usable.
4. Game exits normally; no hard reset.
5. Java log volume drops sharply and per-frame RG35XX-JAVA-DIAG markers are absent.
6. Bounded lifecycle/error markers remain available.
7. Core/JamVM/glibj hashes remain unchanged.
8. Existing unrelated audio errors may remain and do not by themselves fail this checkpoint.

BUILD-PASS does not imply DEVICE-PASS.
STABLE remains NO.
