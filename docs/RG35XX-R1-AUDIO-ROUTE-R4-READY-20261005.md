# RG35XX R1 Audio Route R4 — Physical-ready checkpoint

**Date:** 2026-10-05
**Branch:** `physical-test/rg35xx-r1-p6-p7-20261005`
**Build source commit:** `c38bc78190e3b021ce4d2eb285ebd1c57e8132f1`
**Workflow run:** `37264599729`
**Workflow artifact:** `11325956934`

## Reason for R4

R3 physical evidence established:

```text
P6_PROGRAMMATIC=PASS
P6_ROTATION=PASS
P6_NORMAL_EXIT=PASS
P6_AUDIO_AUDIBLE_DEVICE=FAIL
P7_VUA_PHYSICAL=PASS
P7_GOW_DISPLAY_INPUT_GAMEPLAY_EXIT=PASS
P7_GOW_MENU_AUDIO=PASS
P7_GOW_GAMEPLAY_AUDIO=FAIL
```

The protected A8 Golden contract includes an RG35XX-owned A1P5 pre-Java audio-route prime in addition to the already-protected `libaudio.so`. R3 omitted that launcher boundary.

## R4 scope

R4 restores only the exact protected A1P5/A8 route behavior:

- `SDL_AUDIODRIVER=alsa`
- `a7-a1p5-rw-silence-prime.s32le`
- exact size: `123480` bytes
- exact SHA256: `8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e`
- exact pre-Java route command: `aplay -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100`

No canonical MMAPI, `PlatformPlayer`, `SdlMixerManager`, native audio, platform, runtime, input, video, or font semantic change is included.

## Protected identities retained

```text
PLATFORM_SHA256=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
JAMVM_SHA256=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
GLIBJ_SHA256=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
INPUT_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
VIDEO_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
AUDIO_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
```

## Host/CI gates

Run `37264599729` succeeded through every step: exact R3 parent identity, R4 builder, independent final-ZIP gate, host identity, and artifact upload.

Independent gate:

```text
R1_R4_INDEPENDENT_GATE=PASS
R1_R4_GOLDEN_A1P5_ROUTE_PRIME_GATE=PASS
R1_R4_PRIME_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
R1_R4_PLATFORM_HASH_GATE=PASS
R1_R4_RUNTIME_HASH_GATE=PASS
R1_R4_NATIVE_HASH_GATE=PASS
R1_R4_CANONICAL_MMAPI_DELTA=NONE
R1_R4_NATIVE_AUDIO_DELTA=NONE
R1_R4_GAME_SPECIFIC_CODE=NO
P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
P7_PHYSICAL_REGRESSION=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
```

## Device package

`RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4.zip`

SHA256:

`0e739da19b7f6078e8c9b1b2223cf3fb55a9f95e187830502320a1987282792d`

Actions wrapper digest:

`774ee963e5f00ffe03cda96aae24aba2992d7caf631c08bafe21704e47fc5c6c`

## Physical acceptance

R4 must be tested on original RG35XX. Acceptance requires all of the following:

1. P6 programmatic full-platform campaign remains PASS.
2. P6 WAV and MIDI are physically audible.
3. P2C rotation remains correct and normal return to GarlicOS remains PASS.
4. Vua Cuop Bien display/input/gameplay/no-hang/exit remains PASS.
5. God of War display/input/gameplay/no-hang/exit remains PASS.
6. God of War audio is audible in the menu and remains audible during gameplay/audio continuity.
7. Audio-route logs show `A1P5_AUDIO_ROUTE_PRIME=PASS` before the corresponding Java/game processes.

Until physical evidence satisfies all gates:

```text
P6_PHYSICAL_ACCEPTANCE=NOT_TESTED
P7_PHYSICAL_REGRESSION=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
```
