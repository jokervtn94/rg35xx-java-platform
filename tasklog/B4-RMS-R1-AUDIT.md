# B4-RMS-R1-AUDIT — Read-only RMS metadata audit

Status: AUDIT-TOOL-BUILD-PASS / DEVICE-AUDIT-PENDING / STABLE=NO
Primary variable: NONE — READ-ONLY EVIDENCE COLLECTION

## Preflight

### CURRENT_SYMPTOM

After fully rolling back B4-SCREENSHOT-R1 to the protected baseline core:
- dragon-mania-s40v6 still freezes visually after Run;
- screenshot strip defect returns, as expected when the Screenshot-R1 core is removed.

Rollback hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- B4-HOTPATH-R2 runtime: 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c
- protected B4 core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c

Dragon Java log after rollback:
- 4679 lines in the dragon session
- StringIndexOutOfBoundsException: 246
- RecordStore.loadRecordStore: 246
- RecordStore.openRecordStore: 246
- RG35XX-VIDEO JAVA errors: 0

This disproves Screenshot-R1 as the cause of the dragon freeze.

### HISTORY_FOUND

Pinned FreeJ2ME source is:
TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50

The exact RecordStore.loadRecordStore implementation reads the .rms metadata text and then immediately executes:

jsonString = jsonString.substring(1, jsonString.length() - 1).trim();

There is no prior length check before removing the presumed outer JSON braces.

Historical RMS work exists:
- RC1 pinned RMS safe baseline: STATIC-AUDIT-PASS only
- VC7R22-R1.3J RMS dependency trace: BUILD-PASS / device trace not admitted
- historical async/atomic RMS design was explicitly superseded for the pinned multi-file RMS format

No historical RMS fix is DEVICE-PASS for the current clean B4 foundation.

### PREVIOUS_EVIDENCE_LEVEL

- screenshot R1 causing dragon freeze: disproven by rollback A/B
- RMS failure stack: DEVICE-EVIDENCE
- exact source vulnerability to short metadata: SOURCE-AUDIT
- actual on-SD offending .rms file: NOT YET COLLECTED

### REGRESSION_RISK

Do not patch RecordStore yet.

First determine whether on-SD metadata is:
- zero length;
- shorter than two bytes;
- missing expected outer braces;
- or structurally normal, implying a different load/parser issue.

### MINIMAL_PROPOSED_CHANGE

No platform change.

Run a read-only PC-side audit of all freej2me/rms directories on the selected SD.

For every .rms metadata file record:
- path
- size
- SHA256
- first byte
- last non-whitespace byte
- outer-brace validity
- sibling payload-file count

Do not copy RMS contents.
Do not rename/delete/repair any save.
Do not modify SD files.

### EXPECTED DEVICE AUDIT

If one or more .rms files are zero-length/too-short/unbraced, correlate them with the dragon suite directory before designing a repair or runtime guard.

If all metadata files are structurally normal, do not assume corruption; proceed to a trace-only RecordStore checkpoint.

STABLE remains NO.


## Audit tool build result — 2026-09-21

- source commit: 121e83b25b6a213c57e85bfe5f051dd048bd2de4
- workflow/run: 35564341657
- artifact: 10622879884
- artifact SHA256: ab21cc0ad0353a5b6d0eb9b02e5256a7fdec9d9b051166ac5acd12c40a971c33
- mode: READ_ONLY
- platform files installed: NONE
- SD mutation: NONE
- STABLE: NO
