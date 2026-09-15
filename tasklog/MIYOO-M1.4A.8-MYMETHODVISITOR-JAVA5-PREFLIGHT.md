# MIYOO M1.4A.8 MyMethodVisitor Java5 Backport — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.7 valid CI evidence reduced the Java5 no-audio 2D boot-slice compile to exactly one error: MyClassVisitor.java constructs MyMethodVisitor, but MyMethodVisitor is absent from the bounded source list. A.7 gates NIO/SDL mixer/RMS/M3G all PASS.

## SEARCH_TASKLOG_AND_HISTORY
Searched repository tasklog/code history for MyMethodVisitor/ASM. No previous Miyoo-branch checkpoint or DEVICE-PASS fix for this blocker was found. Earlier M1.4A work left MyMethodVisitor visible as a separate blocker rather than silently stubbing it. Therefore there is no historical stable fix to restore.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
Unlike RMS/M3G inactive imports, this is an active runtime dependency. Pinned MIDletLoader loads game classes and calls MyProducer.instrument(class bytes). MyProducer creates MyClassVisitor; MyClassVisitor creates MyMethodVisitor for every visited method. Removing/stubbing MyMethodVisitor would alter the class instrumentation pipeline and is not an acceptable compile-only shortcut.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
No MyMethodVisitor Java5 backport is DEVICE-PROVEN on original RG35XX. Current evidence is CI FAIL_CLOSED only. Existing JamVM L, SDL1/fbcon and raw-js0 device evidence does not prove this source backport.

## PINNED SOURCE AUDIT
MyMethodVisitor is required by the active ASM pipeline. Its Java5 source incompatibilities visible in the pinned file are bounded and syntactic:
1. diamond operator: `new ArrayList<>()`
2. Java 7 string-switch: `switch (owner)` with String case labels

The visitor's semantic rewrites include Class.getResourceAsStream redirection, Thread.yield->sleep, default charset injection, Siemens listener compatibility, java.util.Timer/TimerTask remapping, Runtime redirection, and descriptor/type/field rewrites. These semantics must be preserved.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = ACTIVE_ASM_METHOD_VISITOR_EXCLUDED_DUE_TO_JAVA7_SOURCE_SYNTAX
HISTORY_FOUND = YES; blocker intentionally preserved, no prior fix
PREVIOUS_FIX = NONE_DEVICE_PROVEN
CURRENT_EVIDENCE = CI_FAIL_CLOSED
REGRESSION_RISK = MEDIUM; active class instrumentation path

## CHOOSE_MINIMAL_CHANGE
Backport MyMethodVisitor source syntax to Java5 in the CI source transformation and include that exact class in the bounded 2D boot-slice compile. Preserve behavior. Do not remove MyClassVisitor/MyProducer instrumentation and do not replace MyMethodVisitor with a no-op visitor.

Allowed syntax-only transformations:
- `new ArrayList<Label>()` instead of diamond syntax
- replace `switch(owner)` String dispatch with Java5-compatible `if/else if (owner.equals(...))` while preserving the same owner/name/opcode/descriptor actions and final fall-through behavior

## PRIMARY VARIABLE
BACKPORT_ACTIVE_MYMETHODVISITOR_SYNTAX_TO_JAVA5_PRESERVING_ASM_SEMANTICS

## FORBIDDEN
- no no-op/stub MyMethodVisitor
- no removal/bypass of MyProducer.instrument
- no removal/bypass of MyClassVisitor
- no change to rewrite targets or descriptors
- no ASM version/library change in this checkpoint
- no audio/RMS/M3G change
- no JamVM/glibj/native/R2.3 change

## ACCEPTANCE
1. MyMethodVisitor is included in the bounded compile.
2. Java5 compiler accepts MyMethodVisitor without diamond/String-switch errors.
3. Existing NIO, SDL mixer, RMS and M3G gates remain PASS.
4. Full bounded compile reaches JAVAC_RC=0 only if no new dependency/API blocker appears.
5. If JAVAC_RC=0, classify only BUILD-PASS for this bounded source slice; DEVICE-PASS remains NO until real RG35XX execution.

DEVICE-PASS = NO.
STABLE = NO.
