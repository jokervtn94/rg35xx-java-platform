# R5 MIDI player ownership — physical acceptance

**Date:** 2026-10-05  
**Branch:** `physical-test/rg35xx-r5-audio-owner-20261005`  
**Status:** `PASS (scoped R5 owner discriminator)`

## Device package and identity

The device ran `RG35XX-Midi-Ownership-R5.jar` from the R5 package. The log
reported the owner-aware native bind and a clean launcher/JVM exit:

```text
RG35XX_R5_AUDIO_OWNER_BIND=PASS
MIDI_OWNER_PROGRAMMATIC_RESULT=PASS
RG35XX_A7_AUDIO_SHUTDOWN=PASS VIDEO_SDL_OWNER_PRESERVED=YES
FREEJ2ME_R1_JVM_EXIT=0
```

The installed native audio hash matched the R5 host candidate:

```text
R5_AUDIO_SHA256=bf6fbdd24fb6ef37dba60438be9992441e4ce8567313f7df3fdebdbea8cd32e5
```

## Audible discriminator

The user confirmed the required physical sequence:

```text
A1 LOW tone          = AUDIBLE PASS
B HIGH tone          = AUDIBLE PASS
A2 LOW tone returns  = AUDIBLE PASS
```

This proves the scoped `A -> B -> A` MIDI ownership boundary works on the
original RG35XX with the R5 native candidate.

## Scope lock

The result does not promote the whole platform. The canonical Java
`PlatformPlayer`/MMAPI and candidate runtime remain unchanged. Because native
audio changed, the exact R5 package must still run:

```text
P6_RETEST=REQUIRED
P7_RETEST=REQUIRED
P8=BLOCKED
DEVICE-PASS=NO
STABLE=NO
```

Required next tests are the Full Port R1 programmatic/physical review, then
Vua Cướp Biển and God of War Tier-0 regression with mandatory GoW gameplay
audio continuity.
