# MIYOO M1.4A.3 JAVA5 BOOT DEPENDENCY BOUNDARY — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.2 removed the final two known Java-7 diamond syntax blockers. The next CI gate now fails with 28 errors spanning dependency boundaries: MIDletLoader java.nio.file, media classes requiring PlatformPlayer, Android RMS manager, M3G references, android.opengl Matrix Nonnull annotation, and one Java-7 string switch in MyMethodVisitor.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4A/M1.4A.1/M1.4A.2 history before this change. The established strategy is to preserve the DEVICE-PROVEN JamVM L + GNU Classpath baseline, avoid whole-source backports, exclude optional 3D/audio from the first 2D boot slice, and fail closed when a core dependency requires a semantic backport.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
This is the expected next layer after syntax cleanup, not evidence that JamVM failed. M1.4A.2 proves the bounded syntax approach progressed the compiler beyond the prior two errors. Several current errors are self-created compile-boundary errors because optional implementations were excluded while their callers remained in the source list.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
JamVM L and glibj remain DEVICE-PROVEN and unchanged. SDL1/fbcon video, raw /dev/input/js0, and exact semantic keymap remain DEVICE-PASS. M1.4A.x is CI-only and has no DEVICE-PASS. R2.3 fallback remains unchanged.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = BOOT_SLICE_DEPENDENCY_BOUNDARY_NOT_YET_CLOSED
HISTORY_FOUND = YES
PREVIOUS_EVIDENCE_LEVEL = CI_FAIL_CLOSED
REGRESSION_RISK = LOW if this checkpoint changes only the CI source boundary

## CHOOSE_MINIMAL_CHANGE
First prune dependency groups that are explicitly outside M1 2D boot: media/audio callers paired with excluded PlatformPlayer, Android-specific RMS path, optional M3G/Matrix surface. Convert the isolated MyMethodVisitor string switch only if MyMethodVisitor remains in the required 2D core. Do NOT backport MIDletLoader java.nio.file in the same checkpoint. The acceptance signal is that the compiler error set collapses to the true core boot blockers, expected to include MIDletLoader if it is unavoidable.

## PRIMARY VARIABLE
CLOSE_2D_BOOT_COMPILE_BOUNDARY_WITHOUT_CORE_API_BACKPORT

## FORBIDDEN
- no JamVM/JVM replacement
- no GNU Classpath patch
- no device installer
- no SDL video/input/audio behavior change
- no R2.3 change
- no MIDletLoader java.nio.file semantic backport
- no PlatformPlayer/audio implementation
- no M3G/LWJGL/Micro3D backport
- no broad compatibility shim

## ACCEPTANCE
PASS for this diagnostic boundary checkpoint if optional/deferred dependency errors are removed and remaining errors identify the unavoidable 2D core API boundary. Full Java5 boot-slice BUILD-PASS still requires a later complete compile and class-major 49 gate. DEVICE-PASS remains NO.

BUILD-PASS = NO
DEVICE-PASS = NO
STABLE = NO
