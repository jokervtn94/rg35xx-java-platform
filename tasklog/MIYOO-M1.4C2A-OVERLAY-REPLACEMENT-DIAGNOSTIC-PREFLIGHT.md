# MIYOO M1.4C.2A OVERLAY REPLACEMENT DIAGNOSTIC — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4C.2 run 34871566717 stopped before compilation because the fail-closed overlay reported `src/org/recompile/mobile/MIDletLoader.java expected=1 actual=4`, without identifying which exact replacement pattern produced the count mismatch.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4C.2 preflight, M1.4C.1 compiler evidence, and the full failed workflow log. Exact upstream pin matched and no compiler/device stage was reached. Prior M1.4A/M1.3B incidents establish that measurement/overlay harness defects must not be classified as platform/source failures.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
This is the same harness-family problem: a safety assertion is too opaque to select a justified source change. The fail-closed behavior itself is correct and must remain.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
No Java candidate was built, no JVM/device files were touched, and no new source incompatibility evidence was produced. Existing native DEVICE-PASS and JamVM fallback evidence remain unchanged.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = OPAQUE_EXACT_REPLACEMENT_COUNT_MISMATCH
HISTORY_FOUND = YES
PREVIOUS_FIX = FAIL_CLOSED_OVERLAY_ABORTED_SAFELY
PREVIOUS_EVIDENCE_LEVEL = TEST_HARNESS_FAILURE_ONLY
REGRESSION_RISK = LOW

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = change only overlay diagnostic text so a replacement-count failure prints a bounded representation of the exact expected source fragment. Do not change replacement counts, source transformations, or build gates yet.

## EXPECTED_RESULT
A rerun identifies the specific MIDletLoader replacement that over-matches. Only after that evidence may the overlay logic be corrected.
