# RG35XX R1 R3 physical audio failure classification

**Date:** 2026-10-05
**Candidate:** `RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R3.zip`
**Candidate SHA256:** `93dab9974944b41b4153775aea1a7670ea0b269f55a121680f42ff47032643b3`

## Exact physical result

Original RG35XX observation supplied by the device tester:

- P6 programmatic full-platform campaign: PASS.
- P6 rotation `0 -> 1 -> 2 -> 0`: PASS.
- P6 normal return to GarlicOS: PASS.
- P6 WAV/MIDI physically audible: **FAIL** (no audible WAV/MIDI).
- Tier-0 Vua Cuop Bien display/input/gameplay/no-hang/exit: PASS.
- Tier-0 God of War display/input/gameplay/no-hang/exit: PASS.
- God of War audio: **PARTIAL** — background audio audible in the menu, but no audio during gameplay.

Programmatic P3 audio markers still report mixer init/load/play/shutdown PASS. This evidence therefore must not be converted into audible DEVICE-PASS.

## Owner classification

```text
P6_PROGRAMMATIC=PASS
P6_AUDIO_AUDIBLE_DEVICE=FAIL
P7_VUA_PHYSICAL=PASS
P7_GOW_GAMEPLAY=PASS
P7_GOW_MENU_AUDIO=PASS
P7_GOW_GAMEPLAY_AUDIO=FAIL
P6_PHYSICAL_ACCEPTANCE=FAIL_AUDIO
P7_TIER0_REGRESSION=FAIL_AUDIO
FAILURE_OWNER=RG35XX_AUDIO_ROUTE_LAUNCHER_BOUNDARY
DEVICE_PASS=NO
STABLE=NO
```

## Authority comparison

The current R3 already uses the exact protected `libaudio.so` identity:

`4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`

The A8 Golden reconstruction contract additionally requires the accepted A1P5 pre-Java audio route prime:

- file: `a7-a1p5-rw-silence-prime.s32le`
- size: `123480` zero bytes
- SHA256: `8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e`
- environment: `SDL_AUDIODRIVER=alsa`
- command before Java: `aplay -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 <prime>`

R3 does not carry or invoke this protected A1P5 route-prime boundary. Therefore the smallest authorized next candidate is launcher/package-only restoration of the exact A1P5 route prime. No canonical MMAPI, PlatformPlayer, SdlMixerManager, JamVM, glibj, platform JAR, video, input, font, or native audio semantics are authorized to change.

## R4 acceptance gates

R4 must preserve all R3 protected identities and add only the exact route-prime payload/launcher invocation. Original-device acceptance requires:

1. P6 full programmatic campaign remains PASS.
2. P6 WAV and MIDI are physically audible.
3. P2C rotation and normal GarlicOS return remain PASS.
4. Vua remains display/input/gameplay/no-hang/exit PASS.
5. God of War remains display/input/gameplay/no-hang/exit PASS.
6. God of War audio remains audible beyond the menu and during gameplay.

Until all gates pass:

```text
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
```
