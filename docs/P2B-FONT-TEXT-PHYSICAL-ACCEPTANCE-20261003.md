# P2B Font/Text — Original RG35XX Physical Acceptance

Date: 2026-10-03

## Scope

This record accepts only the **P2B Font/Text module** on original RG35XX. It is not a full-platform promotion and does not mark the generic RG35XX Java platform stable.

```text
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2B_FONT_TEXT
PHYSICAL_TEST_LEVEL=MODULE
RUNTIME_CANDIDATE_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
PHYSICAL_SOURCE_HEAD=5a8e29dd368bf99b22e81d256691b2a7ec8f1adf
HOST_MODULE_CHECKPOINT=121ca5904b7d442161ed4639f30c5fe9f1c5772d
EXACT_ACCEPTED_P2A_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
P2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
```

## Evidence identity

User-returned evidence archive:

```text
FILE=RG35XX-P2B-FONT-TEXT-EVIDENCE.zip
SHA256=e8751e17d23fa7e13045d3a3ec0bf4ba13c149e50963a5f59502ec1c7d7a22eb
```

The physical package was built from the accepted physical source head and installed through an orchestration-only Windows installer fix. The installer fix did not alter the `SD/` runtime payload.

```text
ORIGINAL_PACKAGE_FILE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R1.zip
ORIGINAL_PACKAGE_SHA256=1e78c30c166f2ce4988478d44c476b0bfdf8c6795e433cf8f21ed934796037da
WINDOWS_INSTALLER_FIX_FILE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R1-WINDOWS-INSTALLER-FIX.zip
WINDOWS_INSTALLER_FIX_SHA256=9122f9bab33e99dd2bf36ff7534ee3cf2554512d3742605f6c913bcdfe5f3d71
SD_RUNTIME_PAYLOAD_DELTA=NONE
RUNTIME_SEMANTIC_DELTA=NONE
```

The evidence binds to the packaged runtime identity:

```text
PACKAGE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R1
PHYSICAL_BRANCH_HEAD=5a8e29dd368bf99b22e81d256691b2a7ec8f1adf
CANDIDATE_PLATFORM_JAR_SHA256=6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4
EXERCISER_SHA256=c0e3df5e1ab01c99932af19116183990b1b382383397e655ba49f06f070f479e
FONT_NATIVE_SHA256=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724
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
P2B_RUNTIME_HASH_GATE_BEFORE=PASS
RG35XX_A3_SDL_DRIVER=fbcon
RG35XX_A3_SURFACE=640x480 PITCH=2560
P2B_EXERCISER_BOOT=PASS
P2B_EXERCISER_EXPECTED_TABLE=PASS
P2B_EXERCISER_CASE_COUNT=360
P2B_EXERCISER_FAILURE_COUNT=0
P2B_EXERCISER_RESULT=PASS
P2B_EXERCISER_EXIT_REQUEST=PASS
P2B_RUNTIME_EXIT_CODE=0
P2B_PROTECTED_HASHES=PASS
P2B_NORMAL_EXIT=PASS
P2B_DEVICE_PROGRAMMATIC_RESULT=PASS
```

The run contains exactly **360 case markers**, with **360 PASS** and **0 FAIL**. The exercised surface is the independent public-MIDP Font/Text exerciser; it does not directly call `RG35XXCore2D`.

The runtime hashes logged before execution match the package identity and the locked protected values for JamVM, glibj, input native, video native and protected audio native.

## Human physical observation

Human observation supplied after the device run:

- screen displayed a green background and `PASS`;
- after exit, the device returned normally to GarlicOS.

This satisfies the required human physical authority for the P2B module exerciser and agrees with the programmatic log.

## Review note

`MANUAL-OBSERVATION.txt` in the evidence archive remains the package-generated pre-run template with `NOT_TESTED`. That file is intentionally not treated as the post-run authority. The physical acceptance combines the immutable programmatic evidence above with the explicit human observation supplied after the run.

The Windows installer fix is also not a runtime semantic change: the tested `SD/` payload remains byte-for-byte the P2B physical R1 payload bound to `PHYSICAL_BRANCH_HEAD=5a8e29dd368bf99b22e81d256691b2a7ec8f1adf`.

## Acceptance boundary

This evidence establishes:

```text
P2B_HOST_MODULE_GATE=PASS
P2B_PHYSICAL_PACKAGE_GATE=PASS
P2B_PHYSICAL_TEST=PASS
P2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS
```

It does **not** establish:

```text
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=YES
STABLE=YES
```

Per the locked platform-first phase order, P2 remains incomplete until the remaining P2 platform/frontend/input-resolution scope is completed at its required boundaries. Full baseline promotion remains gated by later P3–P7 work and Tier-0 physical regression before P8 baseline promotion.
