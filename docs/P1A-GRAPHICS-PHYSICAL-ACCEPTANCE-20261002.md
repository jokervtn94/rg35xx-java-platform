# P1A Graphics Physical Acceptance — 2026-10-02

## Scope

This record captures the one original-RG35XX physical module acceptance run for `P1A_GRAPHICS`.

- Candidate head: `7c0ae595fa05dd3c23157c241cc641e8d43411d5`
- Physical package identity: `RG35XX-P1A-GRAPHICS-PHYSICAL-R2`
- Evidence ZIP filename: `RG35XX-P1A-GRAPHICS-EVIDENCE-20261002-224016.zip`
- Evidence ZIP SHA256: `1110aaf5eb6288d18b422bcd639c954c00c695fd4ea86bc5b1d7ff3442345ed2`
- Device: original RG35XX
- Physical test level: module
- Acceptance surface: one P1A graphics exerciser

## Exact runtime identities observed

- JamVM SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj.zip SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- Platform JAR SHA256: `08e5db36f8b3cd7f5677538d4ecfc56ba0c4a1593f69c73a714b3918c8409f5e`
- P1A exerciser SHA256: `95defae7a0713d106eaf465c1788d47c20617435cccc17fb8b6b8e3a4cb71888`
- Input native SHA256: `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`
- Video native SHA256: `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d`
- Protected audio native SHA256: `4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`

All seven identities matched before and after the device run.

## Programmatic evidence

The device evidence log contains:

- `P1A_EXERCISER_BOOT=PASS`
- `P1A_EXERCISER_CLEAR_COPY_OVERLAP=PASS`
- `P1A_EXERCISER_MIDP_SHAPES=PASS`
- `P1A_EXERCISER_DG_SHAPES_ALPHA=PASS`
- `P1A_EXERCISER_DG_IMAGE_MANIP=PASS`
- `P1A_EXERCISER_DG_PIXELS_INT=PASS`
- `P1A_EXERCISER_DG_PIXELS_SHORT=PASS`
- `P1A_EXERCISER_DG_PIXELS_BYTE=PASS`
- `P1A_EXERCISER_DG_GETPIXELS_INT=PASS`
- `P1A_EXERCISER_DG_GETPIXELS_SHORT=PASS`
- `P1A_EXERCISER_DG_GETPIXELS_BYTE_STUB=PASS`
- `P1A_EXERCISER_CLIP_TRANSLATE=PASS`
- `P1A_EXERCISER_ANCHOR_MATRIX=PASS`
- `P1A_EXERCISER_DEGENERATE_BOUNDS=PASS`
- `P1A_EXERCISER_ALPHA_MATRIX=PASS`
- `P1A_EXERCISER_RESULT=PASS`
- `P1A_EXERCISER_CHECKSUM=96dd9082`
- `RG35XX_A3_SDL_DRIVER=fbcon`
- `RG35XX_A3_SURFACE=640x480 PITCH=2560`
- `RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER`
- `P1A_PROTECTED_HASHES=PASS`
- `P1A_NORMAL_EXIT=PASS`
- `P1A_DEVICE_PROGRAMMATIC_RESULT=PASS`
- runtime exit code `0`

## Human physical observation

The user reported after the original-RG35XX run:

- screen displayed `P1A GRAPHICS PASS`;
- execution returned normally to the GarlicOS menu.

This satisfies the human-observation part of the locked P1A module acceptance contract when combined with the 14/14 PASS device log and protected-hash preservation above.

## Acceptance decision

```text
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P1A_GRAPHICS_HOST_MODULE_GATE=PASS
P1A_GRAPHICS_PROTECTED_HASHES=PASS
P1A_GRAPHICS_NORMAL_EXIT=PASS
P1A_GRAPHICS_RUNTIME_DELTA_AFTER_TEST=NONE
P1A_GRAPHICS_A9_PARENT=NO
P1A_GRAPHICS_GAME_SPECIFIC_CODE=NO
```

This is a **module acceptance checkpoint**, not full platform baseline promotion.

Per the locked platform-first phase order:

```text
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
NEXT_PHASE=P2_IMAGE_FONT_FRONTEND_CONTRACT
P7_TIER0_REGRESSION=NOT_YET_RUN_FOR_BASELINE_PROMOTION
P8_BASELINE_PROMOTION=NOT_YET_REACHED
```

No runtime or protected artifact is modified by this evidence record.
