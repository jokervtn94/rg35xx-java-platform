# P2B Font/Text R1 — Host/Module Checkpoint

Date: 2026-10-03

## Scope

This checkpoint records completion of the **P2B Font/Text host and module gates** only. It does not establish physical acceptance on original RG35XX and does not promote the platform baseline.

```text
PROJECT=RG35XX-AWEIGIT-R1
PHASE=P2
MODULE=P2B_FONT_TEXT
CANDIDATE_BRANCH=module/p2b-font-text-candidate-r1
CANDIDATE_HEAD=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
EXACT_ACCEPTED_P2A_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

## CI evidence

```text
WORKFLOW=P2B Font Text Candidate R1 V2
RUN_ID=37123356422
RUN_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
RUN_RESULT=PASS
ARTIFACT_NAME=RG35XX-P2B-FONT-TEXT-R1-V2-DIAG-2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
ARTIFACT_ID=11274023262
ARTIFACT_ZIP_SHA256=db8a5ed5282a2f6f697f265d35d410ef5616865c365aad5cf5f39ceefe2dea14
ARTIFACT_SIZE_BYTES=982476
```

## Exact candidate identity gates

```text
P2B_R1_EXACT_PARENT=PASS
P2B_R1_REPOSITORY_SCOPE=PASS
P2B_R1_PROTECTED_PARENT_CHAIN=PASS
P2B_R1_PINNED_TOOLCHAIN=PASS
P2B_P2A_PARENT_REBUILD=PASS
P2B_FONT_ASSET_IDENTITY=PASS
P2B_JDK8_SOURCE_PROVENANCE=PASS
P2B_JDK_SCRIPT_MARK_DATA=PASS
P2B_HOST_FONT_NATIVE_BUILD=PASS
P2B_ARM_FONT_NATIVE_BUILD=PASS
P2B_FONT_TEXT_STAGE=PASS
```

Exact pinned font asset used by the differential:

```text
P2B_FONT_ENTRY=JAVA/font.ttf
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2B_FONT_SIZE=8092724
P2B_JDK8_SOURCE_COMMIT=4efe36434f44bafb854e602ccbbe1b5696fce1a2
P2B_JDK8_FREETYPE=2.14.3
P2B_SCRIPT_DATA_PAIR_COUNT=720
P2B_MARK_RANGE_COUNT=204
```

The ARM font owner built as an ELF32 ARM EABI5 soft-float shared object for the pinned uClibC runtime.

## Minimum owner-scoped runtime delta

The accepted P2A parent already carries the canonical Miyoo baseline method semantics in `Font.class`. P2B therefore keeps that class byte-identical and changes only the backing owner and whole-string renderer entries required by the locked minimum-delta contract.

```text
P2B_FONT_CLASS_PARENT_IDENTITY=PASS
P2B_CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class,org/recompile/rg35xx/RG35XXCore2D$RawImage.class,org/recompile/rg35xx/RG35XXCore2D.class
P2B_OWNER_SCOPE_VERIFIED=PASS
P2B_CLASS_MAJORS=50
P2B_JAVA6_GATE=PASS
P2B_FONT_TEXT_NONOWNER_NATIVE_CHANGE=NO
P2B_FONT_TEXT_GAME_SPECIFIC_CODE=NO
P2B_FONT_TEXT_A9_PARENT=NO
```

MIDP anchor, clip and color ownership remains in `PlatformGraphics`; the native/JDK8-derived font backend owns metrics, shaping/layout and whole-string raster only.

## Host differential results

```text
P2B_HOST_METRIC_CASES=24
P2B_HOST_SIMPLE_RASTER_CASES=144
P2B_HOST_COMPLEX_RASTER_CASES=192
P2B_HOST_FAILURE_COUNT=0
P2B_HOST_FONT_METRICS_GATE=PASS
P2B_HOST_SIMPLE_RASTER_GATE=PASS
P2B_HOST_COMPLEX_LAYOUT_GATE=PASS
P2B_HOST_FONT_TEXT_GATE=PASS
```

## Module integration results

The integration gate runs through the actual staged MIDP `Font` and `PlatformGraphics` Raw2D path.

```text
P2B_MODULE_INTEGRATION_CASES=360
P2B_MODULE_INTEGRATION_FAILURE_COUNT=0
P2B_FONT_BASELINE_CANONICAL_GATE=PASS
P2B_PLATFORMGRAPHICS_ANCHOR_GATE=PASS
P2B_WHOLE_STRING_RAW_RASTER_GATE=PASS
P2B_MODULE_GATE=PASS
```

## Protected parent regressions

```text
P1A_GRAPHICS_PARENT_REGRESSION=PASS
P2A_IMAGE_PARENT_REGRESSION=PASS
```

## Required P2B host/module gate summary

```text
P2B_CANONICAL_DIFF_VERIFIED=PASS
P2B_OWNER_SCOPE_VERIFIED=PASS
P2B_JAVA6_GATE=PASS
P2B_HOST_FONT_METRICS_GATE=PASS
P2B_HOST_SIMPLE_RASTER_GATE=PASS
P2B_HOST_COMPLEX_LAYOUT_GATE=PASS
P1A_GRAPHICS_PARENT_REGRESSION=PASS
P2A_IMAGE_PARENT_REGRESSION=PASS
P2B_MODULE_GATE=PASS
P2B_FONT_TEXT_BUILD=PASS
```

## Acceptance boundary

This checkpoint authorizes preparation of the P2B module physical package. It is **not** device evidence.

```text
P2B_HOST_MODULE_GATE=PASS
P2B_RUNTIME_CANDIDATE=PASS
P2B_PHYSICAL_PACKAGE_AUTHORIZED=YES
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
NEW_TIER1_FIX=FORBIDDEN
```

The physical package must embed the exact hash-locked MiSans asset as an internal runtime component, include the official Xiaomi MiSans license copy and a notice stating that MiSans is used, and fail closed on font identity mismatch. The repository must not commit the font bytes.

## Next legal action

```text
NEXT_LEGAL_ACTION=P2B_FONT_TEXT_PHYSICAL_PACKAGE_R1
PHYSICAL_TEST_LEVEL=MODULE
PHYSICAL_PACKAGE_COUNT=ONE
PHYSICAL_RESULT_BEFORE_DEVICE=NOT_TESTED
```

Only returned programmatic evidence plus human observation from an original RG35XX may change `P2B_PHYSICAL_TEST` to `PASS`. Full-platform baseline and `STABLE` remain `NO` regardless of this module checkpoint.
