# Removal / Disable / Replacement Register

No code or behavior is removed without a Task ID, reason, replacement/impact analysis and rollback point.

| Task | Stage | Removed / disabled / replaced | Replacement | Reason | Rollback |
|---|---|---|---|---|---|
| RGJ-LEGACY-007 | legacy | Manager.prepareMediaEngine() on libretro path | native MIDI/PCM architecture | GNU Classpath/JavaSound incompatibility and prior instability | only after replacing media backend |
| RGJ-B1-005 | Beta 1 | release-triggered scan that repeated all held keys | RG35XXInputEngine | incorrect repeat semantics / input anomalies | restore legacy Libretro block |
| RGJ-B1-007 | Beta 1 | old WAV/raw/JavaSound-oriented assumptions | RG35XXWavDecoder -> PCM16 -> native bridge | unified support for PCM/IMA/A-law/mu-law | restore previous wavPlayer path |

## Mandatory fields for future removals

1. exact old symbol/behavior
2. reason for removal
3. replacement or explicit no-replacement decision
4. affected dependencies
5. rollback procedure
6. regression test cases
