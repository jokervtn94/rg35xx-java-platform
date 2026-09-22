# RG35XX-CLEAN-CONSOLIDATED-R1 — Build Result

Date: 2026-09-22
Source branch: `rg35xx-clean-consolidated-r1`
Source commit built: `c9a51d7c2a91101e93a73e48ab31a731200e2824`
Base commit: `1cfce475cbede7bd995bb436926718ca1565702d`
FreeJ2ME pin: `13ec186903087156c145268f8706eecfaf9f1e50`

## CI identity

- Workflow: `RG35XX Clean Consolidated R1`
- Run ID: `35680325494`
- Job ID: `106595712870`
- Conclusion: **SUCCESS**
- Artifact ID: `10675056859`
- Artifact name: `rg35xx-clean-consolidated-r1`
- Artifact/ZIP SHA256:
  `543d13c5dc5980138c0d1efeb0001e646e2ae39003448d69c84f8d8ed0c00530`
- Runtime SHA256:
  `eca358e2deb39e9ac64b291ec9d8b7c0a5b4b04527de54f89f560b4906e1e2b7`
- Required protected core SHA256:
  `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`

## Build gates passed

- exact upstream pin: PASS
- clean B4 source reconstruction: PASS
- production ownership / legacy helper source gate: PASS
- Java compilation: PASS
- Java class count: 1334
- every class major 50: PASS
- legacy helper bytecode gate: PASS
- PNG iCCP source contract: PASS
- Video Mask R2 source contract: PASS
- Hotpath R2 source contract: PASS
- dynamic logical view contract: PASS
- canonical framebuffer binding contract: PASS
- stale cached-lcdData transport call: ABSENT
- Lazy Media Boot preserved: PASS
- PowerShell installer/restore/collector parse: PASS
- package SHA256 manifest: PASS
- native core packaged: NO

## Local post-download verification

Downloaded artifact:
`RG35XX-CLEAN-CONSOLIDATED-R1.zip`

Independent local SHA256:
`543d13c5dc5980138c0d1efeb0001e646e2ae39003448d69c84f8d8ed0c00530`

This exactly matches the GitHub Actions artifact digest.

`sha256sum -c SHA256SUMS.txt`:
all packaged files PASS.

Payload runtime independently verified:
`eca358e2deb39e9ac64b291ec9d8b7c0a5b4b04527de54f89f560b4906e1e2b7`

## Candidate contents

Admitted:
- clean verified base
- Lazy Media Boot
- Golden async RGB565 transport
- protected native Golden core precondition
- Video Mask R2
- Hotpath R2
- PNG iCCP compatibility
- VC7R2 dynamic logical view
- canonical framebuffer binding

Not admitted:
- legacy frame scheduler
- image cache
- transform cache
- old broad lifecycle
- old bitmap text renderer
- RMS coordinator/atomic helper graph
- experimental reconstructed font
- source-reconstructed audio
- 3D

## Current classification

- BUILD-PASS: **YES**
- PACKAGE-INTEGRITY: **PASS**
- INSTALL-PRECONDITION-GATES: **BUILT**
- DEVICE-PASS: **NO — real-device test pending**
- STABLE: **NO**

## Real-device next step

Install with:
`INSTALL-RG35XX-CLEAN-R1.cmd`

Recommended game order:
1. Real Football 2015
2. KDTT 320x240 filename build
3. Dragon Mania S40v6
4. optional NinjaSchool1

Then run:
`COLLECT-RG35XX-CLEAN-R1.cmd`

Upload:
`RG35XX-CLEAN-R1-EVIDENCE-*.zip`

If a hard reset is required at any point, classify that game/session FAIL and collect evidence before running another Java game when possible.
