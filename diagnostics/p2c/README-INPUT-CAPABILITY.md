# P2C Original RG35XX Input Capability Diagnostic

Status: diagnostic-only. This is **not** P2C module physical acceptance and does not install or replace the production FreeJ2ME runtime.

## Purpose

The accepted historical M1.3C calibration measured 12 controls on original RG35XX but did not explicitly measure L2/R2. Pinned Miyoo exposes L1/L2/R1/R2 as separate frontend roles. This diagnostic closes only that hardware-evidence gap.

## Device procedure

Copy the artifact `Roms/APPS` contents to the matching `Roms/APPS` directory on the GarlicOS SD card, then launch `P2C-INPUT-CAPABILITY-DIAGNOSTIC.sh` from Apps.

Follow the control name displayed on screen and wait for `CONFIRMED` before the next control. The order is:

```text
UP DOWN LEFT RIGHT A B X Y START SELECT L1 L2 R1 R2
```

The probe uses text-safe labels for shoulder buttons:

```text
LONE = L1
LTWO = L2
RONE = R1
RTWO = R2
```

On successful completion it shows `DONE` and returns normally. The wrapper writes:

```text
/mnt/mmc/RG35XX-P2C-INPUT-CAPABILITY-DIAGNOSTIC-RESULT.txt
```

Return that exact report as evidence. A successful 14-control calibration closes hardware identity only; it does not set `P2C_PHYSICAL_TEST=PASS`.

## Safety / scope

```text
MODIFIES_PRODUCTION_RUNTIME=NO
RUNTIME_SEMANTIC_DELTA=NONE
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```
