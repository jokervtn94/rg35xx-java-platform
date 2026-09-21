# B4-RMS-R2-DATA-QUARANTINE-AB

Status: TOOL-BUILD-PENDING / DEVICE-TEST-PENDING / STABLE=NO
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
