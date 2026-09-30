# A8 Compatibility Corpus Manifest

This manifest is the controlled list of J2ME games used to extend A8 compatibility testing.
It records test inputs and evidence status only. It does not change the production runtime.

## Rules

- Commercial/game JARs remain external test inputs.
- Never invent or infer a JAR SHA256.
- A game result is valid only when tied to an exact JAR identity.
- `DEVICE-PASS` evidence requires an original RG35XX test.
- A game failure does not by itself justify a runtime change.

## Accepted parent corpus

| ID | Game | JAR SHA256 | Device result | Evidence |
|---|---|---|---|---|
| A8-PARENT-01 | Vua Cướp Biển | Recorded in the accepted A8 regression evidence | PASS | Display/input/gameplay/no hang |
| A8-PARENT-02 | God of War | Recorded in the accepted A8 regression evidence | PASS | Display/input/gameplay/audio/no hang |

The exact hashes above are intentionally not duplicated here because this manifest must not become a second source of truth for values already maintained by the accepted regression evidence.

## New-game queue

| ID | Game | JAR filename | JAR SHA256 | Test status | Notes |
|---|---|---|---|---|---|
| A8-COMP-01 | TBD | TBD | TBD | NOT_TESTED | Chinese J2ME candidate |
| A8-COMP-02 | TBD | TBD | TBD | NOT_TESTED | Different API/profile preferred |
| A8-COMP-03 | TBD | TBD | TBD | NOT_TESTED | Different graphics/audio path preferred |
| A8-COMP-04 | TBD | TBD | TBD | NOT_TESTED | Different lifecycle/RMS behavior preferred |
| A8-COMP-05 | TBD | TBD | TBD | NOT_TESTED | Different media/API behavior preferred |

## Per-game evidence

Use `docs/A8-COMPATIBILITY-REGRESSION-MATRIX.md` for the complete test record.

For every candidate, preserve:

```text
GAME
JAR filename
JAR SHA256
source
device/OS context
launch result
display result
input result
gameplay result
audio/media result
RMS/lifecycle result when exercised
hang/crash result
exit result
log/evidence
failure owner
final result
```

## Corpus expansion policy

Prefer diversity of exercised APIs over a large number of games that follow the same execution path.

Suggested order:

1. A game with a different graphics path.
2. A game with different audio/media behavior.
3. A game exercising RMS/save-load.
4. A game with a different lifecycle pattern.
5. A game exercising an optional API.

Optional APIs remain exploratory until they have direct device evidence.

## Promotion boundary

This manifest is documentation/test inventory only.

A compatibility result may become an A9 engineering task only after reproducible evidence identifies a runtime or adapter owner and the proposed change preserves the accepted A8 parent regression.

Until then:

```text
A8 stable runtime = unchanged
new game = external test input
failure = investigate first
A9 change = evidence required
```