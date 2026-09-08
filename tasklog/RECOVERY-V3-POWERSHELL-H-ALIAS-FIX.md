# Recovery v3 — PowerShell H/Get-History alias fix

Date: 2026-09-08
Status: SCRIPT-FIXED / DEVICE-RUN-PENDING

## Failure in v2

`RECOVER-AUTO-SCAN-V2.ps1` defined a helper named `H` for SHA-256 calculation and invoked it as `H $path`.

On Windows PowerShell, `h`/`H` is a built-in alias for `Get-History`. The alias took precedence, so the JamVM path was incorrectly parsed as `Get-History -Id`, causing:

`Cannot bind parameter 'Id'. Cannot convert value '<path>\\jamvm' to type System.Int64.`

## Fix

Recovery v3 removes the ambiguous `H` helper entirely and uses the explicit function name `Get-Sha256Value` for all SHA-256 calls.

The v3 package keeps the v2 recovery policy unchanged:

- auto-scan runtime/core aliases on live SD and backups;
- prefer known CN core + CQ runtime fingerprints;
- accept Golden baseline as fallback;
- reject the M1 core/runtime hashes that produced the PNG ICC green-screen regression;
- reinstall the proven JamVM L production binary;
- snapshot current canonical files before recovery;
- write a scan/result report on the SD.

## Required device validation

Do not mark v3 DEVICE-PASS until the Windows CMD launches successfully, the SD scan completes, recovery reports PASS, and KDTT is run again on RG35XX.
