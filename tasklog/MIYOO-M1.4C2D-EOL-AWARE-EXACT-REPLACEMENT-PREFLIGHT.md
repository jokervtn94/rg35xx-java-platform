# MIYOO M1.4C.2D EOL-AWARE EXACT REPLACEMENT — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
After M1.4C.2C enabled byte-preserving file I/O, run 34872276288 stopped in the bounded overlay at `PlatformPlayer.java expected=1 actual=0` before diff/compile. The prior run had proven PlatformPlayer uses CRLF upstream while overlay match fragments are authored with LF.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4C.2B/C preflights and runs 34872163257 and 34872276288. C2C correctly removed whole-file newline churn, but exact replacement still compares LF-authored fragments literally against CRLF files.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
This is the second half of the same line-ending harness issue: byte-preserving reads prevent churn, but matching must adapt only the newline bytes of the expected fragment to each file's existing EOL convention.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
- MIDlet multipath counts: proven by C2A.
- Byte-preserving source I/O: active in C2C.
- Compile stage: still NOT REACHED.
- No Java/JVM/device behavior evidence changed.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = EXACT_FRAGMENT_MATCH_IS_NOT_EOL_AWARE
HISTORY_FOUND = YES
PREVIOUS_FIX = BYTE_PRESERVING_IO_ONLY
PREVIOUS_EVIDENCE_LEVEL = CI_HARNESS_ONLY
REGRESSION_RISK = LOW

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = in the overlay helper `rep()`, detect whether the target file uses CRLF or LF, translate only `\n` separators in the expected/replacement fragments to that existing EOL, and then keep the exact-count assertion unchanged. The direct MIDlet commented-helper boundary search must use the same file EOL convention.

## FORBIDDEN CHANGES
No Java semantic transform changes, no count relaxation, no disabled diff/static/compiler gate, no JVM/native/device changes.

## EXPECTED_RESULT
Overlay applies to mixed-EOL pinned source without normalizing untouched bytes; `git diff --check` then evaluates only intended edits and the workflow can proceed to the Java6 compiler gate.
