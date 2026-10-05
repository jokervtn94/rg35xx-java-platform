# R5 Full Port R1 physical retest

**Date:** 2026-10-05  
**Branch:** `physical-test/rg35xx-r5-audio-owner-20261005`  
**Status:** `PASS (scoped P6 retest)`

## Payload identity

The Full Port R1 test used the R5 owner-aware native audio candidate:

```text
AUDIO_NATIVE_SHA256=bf6fbdd24fb6ef37dba60438be9992441e4ce8567313f7df3fdebdbea8cd32e5
PLATFORM_JAR_SHA256=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
INPUT_NATIVE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
```

The device log also reported:

```text
FULL_PORT_R1_PROGRAMMATIC=PASS
RG35XX_R5_AUDIO_OWNER_BIND=PASS
RG35XX_A7_AUDIO_SHUTDOWN=PASS VIDEO_SDL_OWNER_PRESERVED=YES
```

## Manual device observations

The user confirmed:

```text
WAV_AUDIBLE=PASS
MIDI_AUDIBLE=PASS
NORMAL_RETURN_TO_GARLICOS=PASS
```

This completes the scoped P6 retest for the R5 native audio change.

## Next gate

P7 remains required. Run the exact Tier-0 package on the same R5 payload:

```text
Vua Cướp Biển: display/input/gameplay/no-hang/exit
God of War: display/input/gameplay/no-hang/exit and audible gameplay audio
```

Until both Tier-0 regressions pass:

```text
P7_RETEST=REQUIRED
P8=BLOCKED
DEVICE-PASS=NO
STABLE=NO
```
