# MIYOO M1.4A.2 JAVA-5 SYNTAX TAIL — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.1 reduced the Java-5 syntax compile failures from 20 to exactly 2. Both remaining failures are diamond operators in RecordStoreImpl and javax.microedition.util.LinkedList.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4A preflight and M1.4A.1 compiler evidence before this change. M1.4A originally failed with 20 Java 7/8 syntax errors. M1.4A.1 removed/excluded only the bounded syntax/optional surfaces and now fails closed on two remaining diamond operators. JamVM L and GNU Classpath remain device-proven and unchanged.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
This is the same Java-5 source-syntax compatibility family as M1.4A/M1.4A.1, not a new JVM/device runtime failure. The prior bounded approach materially reduced the blocker set and did not expose a reason to replace JamVM.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
M1.4A.1 = CI evidence only, BUILD-PASS NO. JamVM L + GNU Classpath = DEVICE-PROVEN. SDL1/fbcon video, raw js0 and exact semantic keymap remain DEVICE-PASS. No device component is changed here.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = TWO_REMAINING_JAVA7_DIAMOND_OPERATORS
HISTORY_FOUND = YES
PREVIOUS_FIX = BOUNDED_JAVA5_SYNTAX_BACKPORT
PREVIOUS_EVIDENCE_LEVEL = CI_FAIL_CLOSED_WITH_EXACT_TWO_ERRORS
REGRESSION_RISK = LOW; CI source transformation only

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = add only the two explicit generic type arguments reported by M1.4A.1, then rerun the same Java-5 boot-slice gate. Do not alter MIDletLoader java.nio.file semantics in this checkpoint; if those become the next compiler blocker they must be classified separately.

## PRIMARY VARIABLE
REMOVE_FINAL_TWO_JAVA7_DIAMOND_OPERATORS_ONLY

## FORBIDDEN
- no JVM/JamVM change
- no GNU Classpath change
- no device installer
- no SDL video/input/audio change
- no R2.3 change
- no MIDletLoader semantic backport in this checkpoint
- no broad compatibility shim

## ACCEPTANCE
PASS only if the same bounded slice progresses beyond these two exact syntax errors. Full M1.4A BUILD-PASS still requires complete compile plus class-major 49 gate. DEVICE-PASS remains NO.

BUILD-PASS = pending
DEVICE-PASS = NO
STABLE = NO
