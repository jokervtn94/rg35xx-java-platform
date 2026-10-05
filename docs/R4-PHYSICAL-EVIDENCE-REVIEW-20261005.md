# R4 Physical Evidence Review — 2026-10-05

Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Evidence reviewed

- `RG35XX-FULL-PORT-R1-EVIDENCE.zip`
  - SHA256: `6b29188dc2b8c52087e6516b963d5dad68efa6b2846a080810050a2dc9f94d95`
- `RG35XX-R1-AUDIO-ROUTE-PRIME.log`
  - SHA256: `c9b55fc75665362cc526712adb7e7d5ea8b3fcc30c12752fec42cc53f58898cd`
- `RG35XX-R1-RUNTIME-BOOTSTRAP.log`
  - SHA256: `bc72acda84af85aac34ac8419bb144f9ce4cdcf37b7a51f256e9a058c96016ba`

## Programmatic results

- `FULL_PORT_R1_PROGRAMMATIC=PASS`
- P1 graphics = PASS
- P2A image = PASS
- P2B font/text = PASS
- P2C phase 1 = PASS
- P2C phase 2 = PASS
- P2C phase 3 = PASS
- P3 RMS/FileConnection = PASS
- P3 MMAPI WAV start/pause/resume = PASS
- P3 MMAPI MIDI start/end-of-media = PASS
- `RG35XX_A7_AUDIO_SHUTDOWN=PASS VIDEO_SDL_OWNER_PRESERVED=YES`
- Audio-route prime repeatedly reports:
  - `A1P5_AUDIO_ROUTE_PRIME_EXIT_CODE=0`
  - `A1P5_AUDIO_ROUTE_PRIME=PASS`
- Runtime bootstrap reports `R1_RUNTIME_BOOTSTRAP=PASS:EXISTING_EXACT`.

## Physical/manual status

The supplied R4 evidence does not contain a positive manual observation for audible WAV/MIDI, visual rotation, or normal return to GarlicOS. `MANUAL-OBSERVATION.txt` remains:

```text
FULL_PORT_R1_AUDIO_AUDIBLE=NOT_TESTED
FULL_PORT_R1_P2C_ROTATION_VISUAL=NOT_TESTED
FULL_PORT_R1_NORMAL_RETURN_TO_GARLICOS=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
```

Therefore programmatic API/mixer PASS must not be promoted to audible physical PASS.

## Classification

```text
R4_AUDIO_ROUTE_PRIME_PROGRAMMATIC=PASS
R4_RUNTIME_BOOTSTRAP=PASS
P6_FULL_PLATFORM_PROGRAMMATIC=PASS
P6_AUDIO_AUDIBLE_DEVICE=NOT_TESTED
P6_ROTATION_VISUAL=NOT_TESTED
P6_NORMAL_RETURN_TO_GARLICOS=NOT_TESTED
P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
P7_TIER0_REGRESSION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
```

No code change is justified by this evidence. The next required evidence is manual R4 confirmation of audible WAV/MIDI, rotation `0 -> 1 -> 2 -> 0`, and normal GarlicOS return. If those pass, proceed to P7 Vua Cướp Biển + God of War and require God of War audible audio continuity into gameplay before P8 promotion.
