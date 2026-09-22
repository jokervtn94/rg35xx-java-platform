# RG35XX-SD-PRECLEAN-R1.2 — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r1`
Source commit: `e32f5869193e70032744baf1d76794d0e9bec64c`

## Fixed incident

R1.1 failed in SCAN ONLY when exactly one active candidate remained:

```
The property 'Count' cannot be found on this object.
PropertyNotFoundStrict
```

Root cause:
Windows PowerShell pipeline output was scalar-unrolled. A one-item `Scan-Candidates` result assigned to `$candidates` became one PSCustomObject instead of an array, so StrictMode rejected `$candidates.Count`.

R1.2 normalizes both primary and residual scans:

```
$candidates=@(Scan-Candidates)
$residual=@(Scan-Candidates)
```

This guarantees valid Count semantics for 0 / 1 / N candidates.

## CI

- Workflow: `RG35XX SD Preclean R1.2 Tool`
- Run ID: `35682941749`
- Job ID: `106603633271`
- Result: **SUCCESS**
- Windows PowerShell parse: PASS
- drive-root parent self-test: PASS
- nested parent self-test: PASS
- singleton-array self-test: PASS
- empty-array self-test: PASS
- static safety audit: PASS
- packaging: PASS
- artifact ID: `10675616429`
- artifact name: `rg35xx-sd-preclean-r1-2`
- artifact / downloaded ZIP SHA256:
  `fb8327b271110a40e3315e792a78f812356e07f84520c4ec8c3f04ed7f70ad62`

## Independent post-download verification

Downloaded:
`RG35XX-SD-PRECLEAN-R1.2-FIXED.zip`

Independent SHA256:
`fb8327b271110a40e3315e792a78f812356e07f84520c4ec8c3f04ed7f70ad62`

Internal `SHA256SUMS.txt` verification:
**PASS for every packaged file.**

## Current classification

- R1 cleaner: SUPERSEDED
- R1.1 cleaner: SUPERSEDED
- R1.2 cleaner: TOOL-BUILD-PASS
- real SD cleanup: pending user rerun
- R1 platform install: BLOCKED until R1.2 reports `READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES`
- STABLE: NO


---

## Real-device result — 2026-09-22

User reports on original RG35XX SD card:

- SD Pre-Clean R1.2: **SUCCESS**
- old/stray active Java platform files: cleaned successfully
- Clean Consolidated R1 pre-clean-compatible installer: **INSTALL SUCCESS**
- protected foundation preconditions passed during the successful workflow
- no installation failure reported

Current classification:
- PRE-CLEAN DEVICE RESULT: PASS
- INSTALL DEVICE RESULT: PASS
- RUNTIME DEVICE GAME PASS: PENDING
- MULTI-GAME REGRESSION: PENDING
- STABLE: NO

Next required evidence:
1. Real Football 2015
2. KDTT 320x240
3. Dragon Mania S40v6
4. run COLLECT-RG35XX-CLEAN-R1.cmd and archive evidence
