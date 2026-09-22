# RG35XX-SD-PRECLEAN-R1 — Tool Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r1`
Source commit: `a027a4e062e55489c5cb317b7275995a58affe8a`

## CI

- Workflow: `RG35XX SD Preclean R1 Tool`
- Run: `35681585391`
- Job: `106599484469`
- Result: **SUCCESS**
- PowerShell parser: PASS
- Static safety gate: PASS
- Artifact ID: `10675073761`
- Artifact name: `rg35xx-sd-preclean-r1`
- Artifact / downloaded ZIP SHA256:
  `72e1e8c6be712ea2224fd549a10ade1620f62aca13d75fa2e1f65d1f3dbb4a0c`
- Internal SHA256SUMS verification: PASS

## Safety gates confirmed

- no recursive deletion;
- no direct mutation of `Roms\JAVA`;
- no direct mutation of `Saves`;
- exact JamVM L hash required before cleanup;
- exact glibj hash required before cleanup;
- exact protected B4 native core hash required before cleanup;
- rollback quarantine required;
- post-clean active scan must equal zero.

## Companion R1 installer rebuild

The R1 installer was updated so a pre-cleaned card is valid even when the old canonical runtime JAR is absent.

Updated R1 build:
- workflow run: `35681417728`
- artifact ID: `10674193194`
- artifact ZIP SHA256:
  `35ffd09ea7d343814305ceda340affad6ccec4b98e1b3fee9544817675abb179`
- runtime SHA256:
  `6053eb80f890c33a4ef2466e1c18c516178d3b4a0d1ad5130c91a532951d9921`
- BUILD-PASS: YES
- DEVICE-PASS: pending
- STABLE: NO

The earlier R1 device package whose installer required an existing `BIOS\freej2me-lr.jar` is superseded for the pre-clean workflow.
