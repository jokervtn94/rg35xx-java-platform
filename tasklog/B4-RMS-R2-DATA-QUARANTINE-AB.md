# B4-RMS-R2-DATA-QUARANTINE-AB

Status: TOOL-BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO
Primary variable: ONLY_TWO_ZERO_LENGTH_DRAGON_MANIA_STORES_QUARANTINED

## Preflight

CURRENT_SYMPTOM:
Dragon Mania still freezes visually after Screenshot-R1 rollback. Screenshot capture separately regressed to the known strip defect.

HISTORY_FOUND:
B4-RMS-R1-AUDIT found exactly 2 suspicious metadata files among 96 RMS metadata files. Both are in Dragon Mania, both are zero bytes, and both retain one payload sibling.

PREVIOUS_EVIDENCE_LEVEL:
- repeated RecordStore StringIndexOutOfBoundsException: DEVICE-EVIDENCE
- exact zero-length on-SD metadata in same suite: DEVICE-AUDIT-PASS
- pinned source unsafe substring on metadata text: SOURCE-AUDIT

REGRESSION_RISK:
Do not modify runtime yet. Preserve six structurally valid Dragon Mania metadata stores and every other suite.

MINIMAL_PROPOSED_CHANGE:
Reversibly quarantine only:
- ffffffff9c61314e09vhjlzvf1zxn0.rms + its one payload sibling
- ffffffff9c61314e14u2hvcf9vbmxvy2tozxc_.rms + its one payload sibling

The tool first copies and hash-verifies all four files into RG35XX-JAVA-BACKUP, writes a manifest, then removes those four active files from Dragon Mania RMS.

EXPECTED_DEVICE_TEST:
Run Dragon Mania only.
PASS signal:
- game progresses/animates beyond the previous freeze;
- repeated StringIndexOutOfBoundsException / RecordStore.loadRecordStore errors disappear or drop to zero;
- platform hashes remain unchanged.

Screenshot behavior is not a criterion in this RMS A/B because baseline core intentionally retains the known screenshot-strip defect.

STABLE remains NO.


## Tool package result — 2026-09-21

- commit: 91f8b01673ba135eca972977f6b97d0cb7e1f376
- workflow/run: 35564978623
- artifact: 10624295646
- artifact SHA256: a8daac0b599c1476d8b288fe91194794aa5242afd418426c56b10dcb9e252df7
- platform binary change: NONE
- save mutation scope: exactly two known zero-length Dragon Mania metadata stores plus one payload sibling each
- rollback: included
- DEVICE-PASS: pending
- STABLE: NO


## Device result — 2026-09-21 13:12

Evidence:
B4-RMS-R2-QUARANTINE-EVIDENCE-20260921-131214.zip

Quarantine result:
- RESULT=PASS
- 2 zero-length Dragon Mania metadata files quarantined
- 2 matching payload siblings quarantined
- 6 other Dragon Mania metadata stores preserved
- platform/runtime/core unchanged

Protected hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- baseline core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- B4-HOTPATH-R2 runtime: 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c

Java result after quarantine:
- total Java log lines: 5
- StringIndexOutOfBoundsException: 0
- RecordStore.loadRecordStore stack hits: 0
- RecordStore.openRecordStore stack hits: 0
- RG35XX-VIDEO JAVA errors: 0

Native early lifecycle:
- JAVA_READY
- LOAD_GAME dragon-mania-s40v6.jar
- IPC_LOAD_SENT
- IPC_RUN_SENT
- CORE_DEINIT

Direct device observation:
- Dragon Mania still freezes at the Gameloft logo.

Conclusion:
- the two zero-length RMS files were a real corruption/error source;
- quarantining them causally removes the repeated RecordStore exception storm;
- removing that RMS exception storm is NOT sufficient to resolve the Gameloft-logo freeze;
- therefore RMS corruption is one blocker but not the sole/root cause of the current visual freeze.

Checkpoint classification:
- DATA-QUARANTINE ACTION: PASS
- RMS exception storm removal: DEVICE-PASS for that symptom
- Dragon Mania logo freeze: FAIL / persists
- full checkpoint DEVICE-PASS for game compatibility: NO
- STABLE: NO

Next action:
Keep the corrupt stores quarantined so they no longer pollute diagnostics.
Do not modify more RMS behavior yet.
Use a bounded trace-only media lifecycle checkpoint, because historical device evidence shows this same Dragon Mania JAR previously progressed through thousands of frames while native media/audio PLAY/END events were active, whereas current clean B4 deliberately contains only lazy boot suppression and no admitted native media implementation.
