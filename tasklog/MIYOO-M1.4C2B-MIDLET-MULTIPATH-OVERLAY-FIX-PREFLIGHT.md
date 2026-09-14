# MIYOO M1.4C.2B MIDlet MULTIPATH OVERLAY FIX — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.4C.2 run 34871566717 stopped before compilation because the overlay expected one initialized `Path url = findJarResource(resource)` occurrence in MIDletLoader but the exact pinned source contains four.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4C.2, M1.4C.2A and run 34871695826 before implementation. M1.4C.2A measured exact fragment counts on source pin ca11dfe8ea1cc273d92460f9a83bbf192023fa63. Full MIDletLoader source review confirmed all four initialized resource paths and all four `Files.newInputStream` calls are active code paths: manifest/resource/class-byte/Siemens resource loading.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
This is an overlay harness scope mismatch, not a new Java compatibility category and not a device/platform failure. The previous fail-closed abort was correct and protected the source from a blind transform.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
- M1.4C.2A diagnostic: PASS.
- Exact counts: initialized Path declaration=4, stream newInputStream=4, repeated ByteArrayInputStream-return copy block=2.
- Existing JamVM/native fallback remains untouched.
- No Java candidate has been DEVICE-tested.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = MIDLET_ACTIVE_RESOURCE_PATHS_REPEAT_FOUR_TIMES
HISTORY_FOUND = YES
PREVIOUS_FIX = FAIL_CLOSED_ABORT_PLUS_EXACT_COUNT_DIAGNOSTIC
PREVIOUS_EVIDENCE_LEVEL = SOURCE_AND_CI_DIAGNOSTIC
REGRESSION_RISK = LOW_IF_ONLY_MEASURED_ACTIVE_PATHS_ARE_ADMITTED

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = adjust only the M1.4C.2 overlay harness for MIDletLoader to transform the four proven active `Path/Jar resource` branches consistently. Preserve fail-closed exact counts. Also close the two remaining resource streams before the byte-array and Siemens-stream returns so all four transformed input streams have bounded lifetime.

No other source transformation, JVM, native, audio, video or input behavior changes are admitted by this checkpoint.

## EXPECTED_RESULT
Re-run the full M1.4C.2 Java6/major50/forbidden-API gates. Any subsequent failure must be classified from its exact log before further changes.
