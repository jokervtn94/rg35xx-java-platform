# RG35XX Clean R1 Collector R1.1 — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r1`

## Incident

Original collector failed on the real SD with:

```
The property 'Count' cannot be found on this object.
PropertyNotFoundStrict
```

Root cause:
Windows PowerShell + StrictMode scalar-unrolled `Get-Content` / `Select-String` results when only one line or one match existed. Direct `.Count` access was therefore unsafe.

## Fix

- normalize log content with:
  - `$lines=@(Get-Content ...)`
  - `$elines=@(Get-Content ...)`
- replace all direct `Select-String(...).Count` expressions with:
  - `Count-Matches()`
- helper returns:
  - 0 matches -> 0
  - 1 match -> 1
  - N matches -> N
- no runtime files are modified by this collector hotfix.

## CI

- Workflow: `RG35XX Clean R1 Collector R1.1`
- Run ID: `35683976662`
- Job ID: `106606782423`
- Result: **SUCCESS**
- PowerShell parse: PASS
- StrictMode zero-match test: PASS
- StrictMode singleton-match test: PASS
- StrictMode multi-match test: PASS
- single-content-line test: PASS
- static unsafe-count audit: PASS
- artifact ID: `10675887838`
- artifact: `rg35xx-clean-r1-collector-r1-1`
- ZIP SHA256:
  `d4ba782093ab9037a1231b160da9606be7254d7af6157f716195b067d57a636a`
- independent downloaded ZIP verification: PASS
- every internal `SHA256SUMS.txt` entry: PASS

## Classification

- original R1 collector: SUPERSEDED
- Collector R1.1 hotfix: TOOL-BUILD-PASS
- installed runtime: unchanged
- device evidence collection: pending rerun
- STABLE: NO
