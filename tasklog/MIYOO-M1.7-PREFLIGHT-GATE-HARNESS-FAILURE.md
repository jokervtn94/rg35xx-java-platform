# M1.7 PREFLIGHT GATE HARNESS FAILURE

CURRENT_SYMPTOM = CI_STOPS_AT_PREFLIGHT_GREP_BEFORE_ANY_BUILD_STEP
HISTORY_FOUND = YES
PREVIOUS_SAME_FAMILY = M1.5_WORKFLOW_PARSE/HARNESS_FAILURE_AND_M1.4A.6/A.8_HARNESS_FAILURES
PREVIOUS_EVIDENCE_LEVEL = INVALID_HARNESS_NOT_SOURCE_FAILURE
CURRENT_CLASSIFICATION = INVALID_WORKFLOW_GATE_NOT_JAVA_OR_NATIVE_SOURCE_FAILURE
REGRESSION_RISK = LOW
PRIMARY_VARIABLE = REPAIR_PREFLIGHT_EXPECTED_STRING_ONLY

Run 34934879829 / job 104270547941 checked out head eb0c34a2481bb68dab4f2088fc5b781ec117071f successfully and failed only at the second fixed-string grep in Preflight gate. All compiler, toolchain, Java, JNI, ABI, mapping and packaging steps were skipped.

The tasklog itself contains HISTORY_FOUND = YES and locks PRIMARY_VARIABLE as CONNECT_JAVA_TO_RAW_/dev/input/js0_INPUT_ONLY_WHILE_PRESERVING_M1.6_DISPLAY. The workflow incorrectly expected a different phrase: ADD_JAVA_TO_RAW_JS0_INPUT_BRIDGE_USING_EXACT_M1_3C_MAPPING.

Minimal repair: change only the workflow grep expectation to the exact already-locked PRIMARY_VARIABLE string. Do not modify Java probe, JNI bridge, mapping, JamVM/glibj hashes, watchdog or package behavior.

DEVICE_PASS = NO
STABLE = NO
