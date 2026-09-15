# MIYOO M1.4A.6 RMS Import Boundary — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.5 passed both MIDLETLOADER_NIO_GATE and SDLMIXER_BOOT_GATE, reducing the Java5 no-audio 2D compile failure to 4 errors. One is MIDlet.java importing javax.microedition.rms.* while the RMS package is intentionally excluded from this first boot-boundary diagnostic.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4A.5 preflight and its CI result before change. M1.4A.5 explicitly forbade RMS changes and required remaining RMS/M3G/MyMethodVisitor errors to stay visible. That checkpoint succeeded: SdlMixerManager errors are gone and the RMS import is now isolated.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
This RMS error was already predicted by M1.4A.3/M1.4A.5 dependency-boundary work. It has not been fixed previously on this Miyoo branch. Current evidence is CI-only; there is no RMS DEVICE-PASS on the new branch.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
No prior Miyoo-branch RMS fix has DEVICE-PASS. JamVM L/glibj and native video/input evidence are unrelated and remain unchanged. R2.3 fallback remains untouched.

## SOURCE CHECK
Pinned upstream MIDlet.java imports javax.microedition.rms.* but contains no RMS type, method, field, constructor, or symbol use anywhere in the class. Therefore this compile error is an unused wildcard import, not proof that MIDlet lifecycle itself requires RMS.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = UNUSED_RMS_WILDCARD_IMPORT_BLOCKS_NO_RMS_BOOT_SLICE
HISTORY_FOUND = YES
PREVIOUS_FIX = NONE
CURRENT_EVIDENCE = CI_FAIL_CLOSED
REGRESSION_RISK = VERY_LOW; source-audit transformation only

## CHOOSE_MINIMAL_CHANGE
Remove only `import javax.microedition.rms.*;` from MIDlet.java in the CI boot-slice transformation. Do not alter the RMS implementation, RecordStore behavior, MIDlet lifecycle, or source-list RMS exclusion.

## PRIMARY VARIABLE
REMOVE_UNUSED_MIDLET_RMS_IMPORT_ONLY

## FORBIDDEN
- no RMS implementation/backport/stub
- no MIDlet lifecycle semantic change
- no JamVM/glibj change
- no audio change
- no M3G change
- no MyMethodVisitor change
- no native/device installer change
- no R2.3 change

## ACCEPTANCE
1. Compiler no longer reports `package javax.microedition.rms does not exist` from MIDlet.java.
2. MIDLETLOADER_NIO_GATE remains PASS.
3. SDLMIXER_BOOT_GATE remains PASS.
4. M3G and MyMethodVisitor blockers remain visible and fail closed.
5. This checkpoint does not claim RMS support.

BUILD-PASS = NO until complete compile evidence.
DEVICE-PASS = NO.
STABLE = NO.
