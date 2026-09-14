# MIYOO M1.4A SOURCE AUDIT HARNESS FIX — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4 workflow run 34870009727 failed at `Run source compatibility audit` immediately after the pinned upstream checkout succeeded. No compatibility report was emitted.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4 JVM strategy preflight and prior M1.3B/B.1 harness incidents before changing code. Project rule requires distinguishing test-harness failures from platform/source failures.

## COMPARE_WITH_PREVIOUS OCCURRENCES
This is the same failure class as prior probe-harness defects: the measurement tool can fail independently of the system being measured. In M1.4, `set -euo pipefail` causes grep-based count pipelines to terminate when a valid search has zero matches because grep returns status 1 for zero matches.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
No JVM or device runtime was exercised by failed run 34870009727. The pinned source checkout itself succeeded and matched ca11dfe8ea1cc273d92460f9a83bbf192023fa63. Therefore the failed run provides NO negative evidence against JamVM or the Miyoo source.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = AUDIT_SCRIPT_ZERO_MATCH_PIPEFAIL
HISTORY_FOUND = YES
PREVIOUS_FIX = NONE_FOR_M1_4_AUDIT_SCRIPT
PREVIOUS_EVIDENCE_LEVEL = TEST_HARNESS_FAILURE_ONLY
REGRESSION_RISK = LOW

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = keep the audit patterns and classifications unchanged, but make zero-match grep counts non-fatal. The audit must still fail on missing source tree, wrong pin, or workflow gate failure.

## FORBIDDEN CHANGES
No JVM/JamVM/glibj changes, no source backport, no Java build, no device changes, no SDL/input/audio/font changes.

## EXPECTED RESULT
M1.4 audit completes and emits a report where zero-match categories are represented as count 0 instead of aborting the script.
