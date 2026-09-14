# MIYOO M1.3C ONSCREEN EXACT RG35XX KEYMAP — DEVICE RESULT

Date reviewed: 2026-09-14
Branch: rg35xx-miyoo-platform-v1
Device: original RG35XX (2022)
Probe SHA256: 01e1aeef8c54dc26c1203412f3d6eba6d35f793a46c83c77525151d94397bc7b

## Real-device result
- SDL1_DLOPEN=PASS
- SDL1_VIDEO_DRIVER=fbcon
- SDL1_SET_VIDEO_MODE=PASS w=640 h=480
- JS0_OPEN=PASS
- BASELINE_LOCKED=YES
- KEYMAP_COUNT=12
- M1_3C_RESULT=PASS
- PROBE_EXIT_CODE=0
- DEVICE_TEST=PASS_ONSCREEN_EXACT_RAW_KEYMAP

## Device-proven exact mapping
- UP = axis 7, press -32767, release 0
- DOWN = axis 7, press +32767, release 0
- LEFT = axis 6, press -32767, release 0
- RIGHT = axis 6, press +32767, release 0
- A = button 0, press 1, release 0
- B = button 1, press 1, release 0
- X = button 2, press 1, release 0
- Y = button 3, press 1, release 0
- START = button 8, press 1, release 0
- SELECT = button 7, press 1, release 0
- L = button 5, press 1, release 0
- R = button 6, press 1, release 0

## Locked fallback hashes before/after
Identical before and after device test:
- runtime: 2cf28cd1832ba964c5db5e67c57e07ec5716bbc0aca88d8365c6188812f5d65b
- core: 8939ea7f1ad368f315da8e4ce863270d89e9c51385257d6d58e0a9147e00d29a
- JamVM: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

## Classification
- M1.3C exact semantic raw keymap: DEVICE-PASS
- SDL1/fbcon path: remains DEVICE-PASS scope-specific
- raw /dev/input/js0 transport: remains DEVICE-PASS scope-specific
- Full Miyoo-derived platform: DEVICE-PASS NO
- STABLE: NO

The wrapper's literal DEVICE_PASS=NO is a pre-human-evaluation guard and is superseded for this scope by the reviewed real-device evidence above.
