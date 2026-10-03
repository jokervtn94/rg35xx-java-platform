# P2A Image Decode — Original RG35XX Physical Acceptance

Date: 2026-10-03

## Scope

This record accepts only the **P2A Image Decode module** on original RG35XX. It is not a full-platform promotion and does not mark the generic RG35XX Java platform stable.

```text
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2A_IMAGE_DECODE
PHYSICAL_TEST_LEVEL=MODULE
CANDIDATE_HEAD=77a36526e0f6d875c57c7e9a973e0c1a05573721
EXACT_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
NEXT_PHASE=P2B_FONT_TEXT
```

## Evidence identity

User-returned evidence archive:

```text
FILE=RG35XX-P2A-IMAGE-DECODE-EVIDENCE-CMD-270828930.zip
SHA256=7117d8c86cebb8689aa52bb0f87fc0122bf4e723618b4e166060cde382bda3e5
INSTALL_METHOD=CMD_HELPER
```

The evidence binds to the CI-produced physical package identity:

```text
PACKAGE=RG35XX-P2A-IMAGE-DECODE-PHYSICAL-R1
CANDIDATE_PLATFORM_JAR_SHA256=11a524c67edc631c2391573add4bcc21ea0e4d95d187fb4b34bffde01cf46b9b
EXERCISER_SHA256=801dc34bd7dda2f0aa639006d1fab4e007a24223ec7c746a3a50832ef0f846ce
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

Protected Java runtime hashes observed on the SD card:

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

## Programmatic device evidence

The device run log records:

```text
P2A_EXERCISER_BOOT=PASS
P2A_EXERCISER_EXPECTED_TABLE=PASS
P2A_EXERCISER_FIXTURE_COUNT=150
P2A_EXERCISER_FRONTEND_COUNT=3
P2A_EXERCISER_DECODE_COUNT=450
P2A_EXERCISER_FAILURE_COUNT=0
P2A_EXERCISER_RESULT=PASS
P2A_EXERCISER_EXIT_REQUEST=PASS
P2A_RUNTIME_EXIT_CODE=0
P2A_PROTECTED_HASHES=PASS
P2A_NORMAL_EXIT=PASS
P2A_DEVICE_PROGRAMMATIC_RESULT=PASS
```

All 150 fixtures were present and each produced PASS through all three public image frontends:

- byte-array;
- input stream;
- resource name.

That gives **450/450 decode cases PASS** with no missing fixture/frontend combination.

The runtime hashes logged before and after execution were identical for JamVM, glibj, the candidate platform JAR, the exerciser JAR, input native, video native and protected audio native.

The launcher also recorded the expected physical backend path:

```text
RG35XX_A3_SDL_DRIVER=fbcon
RG35XX_A3_SURFACE=640x480 PITCH=2560
RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER
```

## Human physical observation

Human observation supplied with the returned evidence:

- screen displayed a green background and `PASS`;
- no physical failure was reported;
- after exit, the device returned normally to the GarlicOS menu.

This satisfies the required human physical observation for the P2A module exerciser and agrees with the programmatic log.

## Review note

The captured console log contains one opaque line after the exerciser exit request containing the text `SDL2_mixer`. This does **not** alter the acceptance result: the packaged protected `libaudio.so` matches the locked SHA256 above, the runtime explicitly reports `BACKEND=SDL1_MIXER`, and package inspection found no SDL2 string in the packaged payload. No runtime artifact changed before/after the physical run.

## Acceptance boundary

This evidence establishes:

```text
P2A_IMAGE_DECODE_HOST_MODULE_GATE=PASS
P2A_IMAGE_DECODE_PHYSICAL_MODULE_GATE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
```

It does **not** establish:

```text
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=YES
STABLE=YES
```

Per the locked platform-first phase order, P2 remains incomplete until the Font/Text and Input/Frontend/Resolution portions are completed and physically accepted at their module boundaries. Full baseline promotion remains gated by later P3–P7 work and Tier-0 physical regression.
