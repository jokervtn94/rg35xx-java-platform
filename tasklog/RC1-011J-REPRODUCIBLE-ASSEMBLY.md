# RGJ-RC1-011J — Reproducible Source Assembly

Action: ADD / AUDIT
Status: STATIC-AUDIT-PASS

Governance reload completed before mutation: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, native manifest and current patch/native trees.

Added `scripts/rc1_assemble.sh` as the single deterministic disposable-tree assembly driver. It verifies FreeJ2ME pin `13ec186903087156c145268f8706eecfaf9f1e50`, requires the existing build-ready external-input gate, overlays registered RG35XX Java sources, copies the 011I native graph and TML/TSF vendor inputs, applies active integration contracts in fixed order, and emits `rc1_sources.mk` for the native Makefile stage.

Correction performed inside this stage: initial script aliases for patches 0004/0006/0016/0018/0019 did not match the repository tree. Exact patch-tree identities were reloaded and the script was corrected before closure. Historical 0009 and 0012/0013 are deliberately excluded because 0021 and 0020 respectively own their pinned RC1 responsibilities.

0022 remains separate because it targets GNU Classpath 0.99 rather than the FreeJ2ME tree.

Acceptance: assembly policy/source driver is statically coherent and fail-closed on patch divergence. No actual assembly execution is claimed because the connector environment does not materialize the required external binary/source inputs or execute the target toolchain.

Not claimed: BUILD-READY, BUILD-PASS, DEVICE-TEST-PASS.

Audit: `docs/RC1-REPRODUCIBLE-ASSEMBLY-AUDIT.md`.