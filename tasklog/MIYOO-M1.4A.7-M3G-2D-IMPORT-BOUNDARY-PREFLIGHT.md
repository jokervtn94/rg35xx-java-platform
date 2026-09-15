# MIYOO M1.4A.7 M3G 2D Import Boundary — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.6 passed MIDLETLOADER_NIO_GATE, SDLMIXER_BOOT_GATE and MIDLET_RMS_IMPORT_GATE. Java5 no-audio 2D compile is now FAIL_CLOSED with 3 errors: two missing javax.microedition.m3g.Graphics3D imports in Mobile.java/MobilePlatform.java and one MyMethodVisitor dependency in MyClassVisitor.java.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4A.6 tasklog and CI evidence before change. M1.4A.6 explicitly required M3G and MyMethodVisitor blockers to remain visible. Earlier M1.4A scope explicitly excluded M3G/3D from the first 2D boot slice; no M3G implementation has DEVICE-PASS on this Miyoo branch.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
M3G was intentionally excluded from the boot-slice source list from the initial M1.4A experiment. The current compiler errors are therefore dependency leakage from core 2D classes, analogous to the previously isolated unused RMS import, not a newly discovered requirement to implement 3D.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
No M3G fix/backport is DEVICE-PROVEN on this Miyoo branch. Existing SDL1/fbcon video and raw js0 input DEVICE-PASS are unrelated. JamVM L/glibj and R2.3 fallback remain unchanged.

## SOURCE CHECK
Pinned Mobile.java imports Graphics3D, but its only Graphics3D field/getter/setter block is commented out. Pinned MobilePlatform.java imports Graphics3D, but the only constructor use `Mobile.setGraphics3D(Graphics3D.getInstance())` is commented out. There is no active Graphics3D symbol use in either class. Therefore both compile errors are inactive imports for the 2D path.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = INACTIVE_M3G_IMPORTS_BLOCK_2D_NO_M3G_BOOT_SLICE
HISTORY_FOUND = YES
PREVIOUS_FIX = NONE
CURRENT_EVIDENCE = CI_FAIL_CLOSED
REGRESSION_RISK = VERY_LOW; CI source-audit transformation only

## CHOOSE_MINIMAL_CHANGE
Remove only `import javax.microedition.m3g.Graphics3D;` from Mobile.java and MobilePlatform.java in the CI boot-slice transformation. Do not alter commented M3G code, add stubs, include M3G sources, or implement 3D.

## PRIMARY VARIABLE
REMOVE_INACTIVE_GRAPHICS3D_IMPORTS_FROM_2D_BOOT_SLICE_ONLY

## FORBIDDEN
- no M3G implementation/backport/stub
- no active 2D rendering semantic change
- no MyMethodVisitor/ASM change
- no audio/RMS change
- no JamVM/glibj change
- no native/device installer change
- no R2.3 change

## ACCEPTANCE
1. Compiler no longer reports `package javax.microedition.m3g does not exist` from Mobile.java or MobilePlatform.java.
2. MIDLETLOADER_NIO_GATE remains PASS.
3. SDLMIXER_BOOT_GATE remains PASS.
4. MIDLET_RMS_IMPORT_GATE remains PASS.
5. MyMethodVisitor remains visible as the separate final blocker.
6. This checkpoint does not claim M3G/3D support.

BUILD-PASS = NO until complete compile evidence.
DEVICE-PASS = NO.
STABLE = NO.
