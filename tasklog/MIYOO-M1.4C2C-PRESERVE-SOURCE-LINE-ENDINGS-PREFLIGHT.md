# MIYOO M1.4C.2C PRESERVE SOURCE LINE ENDINGS — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4C.2B run 34872163257 successfully patched the MIDlet multipath harness and the bounded source overlay itself reported `M1_4C2_OVERLAY=PASS`. The run then failed at `git diff --check` because PlatformPlayer.java appeared to have many added lines with pre-existing trailing whitespace.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4C.2B preflight, M1.4C.2A diagnostics, before/after hashes, and full run 34872163257 log before changing the overlay harness.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
The overlay helper uses Python `Path.read_text()` / `write_text()`. On the Linux CI runner this normalizes upstream CRLF line endings to LF when a file is rewritten. That makes untouched upstream lines appear changed and causes `git diff --check` to flag pre-existing trailing whitespace as newly introduced whitespace. This is a harness/source-serialization problem, not a Java compatibility or runtime failure.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
- M1.4C.2B MIDlet measured-path harness patch: PASS.
- Bounded overlay application: PASS.
- Compile stage: NOT REACHED.
- JVM/device/native platform: NOT MODIFIED.
- No new source incompatibility category was observed.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = OVERLAY_TEXT_IO_NORMALIZES_UPSTREAM_LINE_ENDINGS
HISTORY_FOUND = YES
PREVIOUS_FIX = BOUNDED_OVERLAY_APPLIED_BUT_DIFF_GATE_CORRECTLY_REJECTED_CHURN
PREVIOUS_EVIDENCE_LEVEL = CI_HARNESS_ONLY
REGRESSION_RISK = LOW

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = change only overlay file I/O to byte-preserving UTF-8 decode/encode so existing CRLF/LF sequences are retained. Apply the same byte-preserving rule to the direct MIDletLoader comment-block rewrite. Keep `git diff --check` enabled and unchanged.

## FORBIDDEN CHANGES
No Java transform logic changes, no relaxed diff gate, no JVM/glibj/native/audio/video/input changes, no device install.

## EXPECTED_RESULT
The same logical overlay produces a minimal diff containing only intended source edits. `git diff --check` must pass before source inventory/compile can proceed. Any later failure is classified separately.
