# P2 Image / Font / Frontend Contract Audit v1

Status: P2A CONTRACT LOCKED R1-R5 / P2B-P2C DIAGNOSTIC ONLY

Exact runtime parent: `7c0ae595fa05dd3c23157c241cc641e8d43411d5`
Pinned Miyoo authority: `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
P1A physical acceptance branch is evidence only, not runtime ancestry.
A9 parent: NO.

## Phase split

- P2A — Image Decode / Transform
- P2B — Font / Text
- P2C — Input / Frontend / Resolution policy

Host diagnostics may be granular; physical acceptance remains module-level.

## P2A — Image Decode / Transform

```text
PORT_UNIT=P2A_IMAGE_DECODE_TRANSFORM
MIYOO_SOURCE=PlatformImage + ImageIO + PlatformGraphics image/drawRegion/Sprite transforms
MIYOO_CURRENT_BEHAVIOR=ENCODED_BYTES/RESOURCES/STREAMS_DELEGATE_TO_JDK8_IMAGEIO; TRANSFORMS_FOLLOW_CANONICAL_SPRITE_SEMANTICS
FREEJ2ME_REFERENCE=PINNED_MIYOO_SOURCE_IS_AUTHORITY
JDK_OPENJDK_REFERENCE_IF_REQUIRED=YES_PINNED_JDK8_IMAGEIO_PIXEL_OUTPUT_LOCKED_BY_R1_R5
RG35XX_MEASURED_LIMITATION=RAW_PNG_BACKING_COVERS_ONLY_8BIT_NONINDEXED_PLUS_INDEXED_1_2_4; GRAY8_OUTPUT_DOES_NOT_MATCH_JDK8_GETRGB; ACCEPTED_ADAM7_HAS_SAME_DEPTH_LIMIT
EXACT_FAILURE_OR_MISSING_CONTRACT=RG35XX_RAW_PNG_BACKING_DOES_NOT_COVER_ALL_MIDP_REQUIRED_LEGAL_SAMPLE_DEPTHS_AND_JDK8_PIXEL_CONVERSION
FAILURE_OWNER=RG35XX_IMAGE_DECODE_BOUNDARY
WHY_MIYOO_AS_IS_CANNOT_WORK=ORIGINAL_RG35XX_RAW2D_RUNTIME_CANNOT_DEPEND_ON_DESKTOP_IMAGEIO
MINIMUM_REQUIRED_DELTA=OWNER_ONLY_EXTEND_RG35XXCORE2D_PNG_SAMPLE_UNPACK_ROW_ACCOUNTING_SCALING_AND_GRAY_CONVERSION_TO_MATCH_PINNED_JDK8; RETAIN_PINNED_JDK8_NONINDEXED_TRNS_OPAQUE_BEHAVIOR_FOR_ALL_LEGAL_GRAY_RGB_DEPTHS; NO_FONT_INPUT_VIDEO_AUDIO_LIFECYCLE_RMS_CHANGE
FILES_ALLOWED_TO_CHANGE=P2A_OWNER_RG35XXCORE2D_MATERIALIZATION_OR_STAGE+P2A_BUILD_TEST_WORKFLOW_DOC_ONLY
FILES_FORBIDDEN_TO_CHANGE=PLATFORMGRAPHICS_SEMANTICS,INPUT,VIDEO_NATIVE,AUDIO,LIFECYCLE,RMS,JAMVM,GLIBJ,FONT,FRONTEND,GAME_SPECIFIC_RUNTIME
PARENT_REGRESSION_GATES=P1A_COMPLETE_GRAPHICS+ACCEPTED_ADAM7+PROTECTED_NATIVE_HASHES
HOST_DIFFERENTIAL_GATE=FULL_150_CASE_LEGAL_PNG_MATRIX_30_TYPE_DEPTH_INTERLACE_X_FILTERS_0_TO_4_PIXEL_EXACT_AGAINST_PINNED_JDK8_IMAGEIO
MODULE_INTEGRATION_GATE=REQUIRED
PHYSICAL_GATE=ONE_IMAGE_DECODE_MODULE_AFTER_HOST_INTEGRATION_PASS
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

### Declared baseline format

P2A baseline declares **PNG** as the required encoded image format. The pinned Miyoo implementation delegates encoded image bytes to `ImageIO` and therefore can incidentally accept additional formats such as JPEG, but those desktop ImageIO extensions are not silently promoted into required RG35XX baseline blockers.

The required PNG matrix is the MIDP 2 PNG baseline: legal color types and legal bit depths, filters 0..4, non-interlaced and Adam7, palette where applicable, and required critical chunks. The RG35XX port still follows pinned Miyoo/JDK8 observable pixel behavior where that canonical path has a limitation.

### R1 — legal PNG matrix

The host diagnostic generated 30 legal cases: every legal PNG color-type / bit-depth combination under interlace 0 and Adam7 interlace 1.

```text
P2A_PNG_LEGAL_CASE_COUNT=30
P2A_PNG_CANONICAL_PASS_COUNT=30
P2A_PNG_RAW_MATCH_COUNT=12
P2A_PNG_RAW_MISMATCH_COUNT=4
P2A_PNG_RAW_UNSUPPORTED_COUNT=14
P2A_RUNTIME_CHANGE=NO
```

Classification:
- 12 existing Raw2D cases are already pixel-exact against pinned JDK8 ImageIO;
- 4 mismatches are grayscale 8-bit and grayscale+alpha 8-bit under both interlace modes;
- 14 unsupported cases are legal sample-depth paths: grayscale 1/2/4/16, RGB16, gray+alpha16 and RGBA16 across interlace 0/1.

### R2 — grayscale / 8-bit non-indexed tRNS semantic decomposition

Pinned JDK8 `ImageIO.read(...).getRGB()` converts 8-bit grayscale through the JDK `CS_GRAY` linear-gray -> sRGB path; direct byte replication is therefore not canonical-equivalent.

R2 also established specifically for **8-bit** grayscale/RGB `tRNS`, under both interlace modes, that pinned Miyoo/JDK8 does not materialize transparent alpha in the tested PlatformImage/ImageIO path. Indexed-palette `tRNS` remains effective. R2 alone did not authorize extending that conclusion to other legal sample depths; R5 below closes that gap.

```text
P2A_R2_JDK8_TRNS_GRAY_RGB_EFFECTIVE_ALPHA=NO
P2A_R2_GRAYSCALE_COLORSPACE=CS_GRAY_TO_SRGB_GETRGB
P2A_R2_TRNS_SCOPE=GRAY8_RGB8_INTERLACE_0_1_ONLY
```

### R3 — exact JDK8 gray8/gray16 transfer

The JDK8 diagnostic exhaustively checked all 256 grayscale-8 samples and all 65,536 grayscale-16 samples through actual PNG `ImageIO.read().getRGB()` output.

```text
P2A_R3_GRAY8_SAMPLE_COUNT=256
P2A_R3_GRAY8_FORMULA_MISMATCH=0
P2A_R3_GRAY16_SAMPLE_COUNT=65536
P2A_R3_GRAY16_FORMULA_MISMATCH=0
P2A_R3_GRAY_TRANSFER_MODEL=LINEAR_GRAY_TO_SRGB_IEC61966_2_1
```

Locked conversion model:
- normalize gray sample to linear [0,1];
- if `linear <= 0.0031308`, `srgb = 12.92 * linear`;
- otherwise `srgb = 1.055 * linear^(1/2.4) - 0.055`;
- output channel is rounded to 8-bit.

### R4 — low-bit grayscale and 16-bit component scaling

The JDK8 diagnostic locked the remaining sample conversion paths:

```text
P2A_R4_GRAY1_SAMPLE_COUNT=2
P2A_R4_GRAY1_MODEL_MISMATCH=0
P2A_R4_GRAY2_SAMPLE_COUNT=4
P2A_R4_GRAY2_MODEL_MISMATCH=0
P2A_R4_GRAY4_SAMPLE_COUNT=16
P2A_R4_GRAY4_MODEL_MISMATCH=0
P2A_R4_RGB16_SAMPLE_COUNT=65536
P2A_R4_RGB16_ROUND_SCALE_MISMATCH=0
P2A_R4_RGBA16_ALPHA_SAMPLE_COUNT=65536
P2A_R4_RGBA16_ALPHA_ROUND_SCALE_MISMATCH=0
P2A_R4_LOWBIT_GRAY_MODEL=DIRECT_ROUND_SAMPLE_TIMES_255_OVER_MAX
P2A_R4_16BIT_RGB_ALPHA_MODEL=ROUND_SAMPLE_TIMES_255_OVER_65535
```

Therefore:
- grayscale 1/2/4-bit is direct rounded expansion to 0..255 and must **not** use the gray8/16 linear-gray transfer;
- 16-bit RGB components and 16-bit alpha use rounded scaling `sample * 255 / 65535`, not high-byte truncation;
- gray8/16 continues to use the R3 linear-gray -> sRGB transfer.

### R5 — all-depth non-indexed tRNS observation

R5 removed the remaining unsupported inference. It generated every legal non-indexed `tRNS` depth for grayscale and RGB, each under non-interlaced and Adam7 encoding. For every case, pixel `(0,0)` exactly matched the declared transparent sample and pixel `(1,0)` deliberately did not match it.

Pinned Temurin JDK 8.0.504+1 `ImageIO.read(...).getRGB()` returned **opaque alpha 255 for both pixels in all 14 cases**, and the returned color model reported no alpha. This is an observed pinned-Miyoo/JDK8 behavior and is not generalized as a statement about PNG implementations or the PNG specification.

```text
P2A_R5_CASE_COUNT=14
P2A_R5_CANONICAL_PASS_COUNT=14
P2A_R5_MATCH_ALPHA0_COUNT=0
P2A_R5_NONMATCH_ALPHA0_COUNT=0
P2A_R5_ALL_MATCH_ALPHA=255
P2A_R5_ALL_NONMATCH_ALPHA=255
P2A_R5_ALL_COLOR_MODELS_HAS_ALPHA=NO
P2A_R5_SCOPE=GRAY_1_2_4_8_16_PLUS_RGB_8_16_X_INTERLACE_0_1
P2A_R5_RUNTIME_CHANGE=NO
NONINDEXED_TRNS_CLASSIFICATION=PINNED_MIYOO_JDK8_CANONICAL_LIMITATION
```

Locked P2A behavior is therefore:
- indexed palette `tRNS` remains effective;
- non-indexed grayscale/RGB `tRNS` remains opaque for every legal tested depth under both interlace modes, matching the pinned Miyoo/JDK8 source-of-truth path;
- RG35XX must not silently implement a different non-indexed `tRNS` behavior merely because another PNG implementation or the format specification would do so.

### P2A implementation authorization

All pre-change fields are now resolved for P2A through R1-R5.

```text
P2A_AUDIT_R1=PASS_EVIDENCE_ONLY
P2A_AUDIT_R2=PASS_EVIDENCE_ONLY
P2A_AUDIT_R3=PASS_EVIDENCE_ONLY
P2A_AUDIT_R4=PASS_EVIDENCE_ONLY
P2A_AUDIT_R5=PASS_EVIDENCE_ONLY
P2A_AUDIT_RUNTIME_DELTA=NONE
P2A_RUNTIME_PATCH=AUTHORIZED_ON_SEPARATE_OWNER_SCOPED_BRANCH_FROM_EXACT_PARENT
P2A_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P2A_AUDIT_BRANCH_PARENT_FOR_RUNTIME=NO
```

Candidate implementation must generalize PNG row accounting and filter byte-width correctly for packed and 16-bit pixels, preserve accepted palette/indexed `tRNS`/Adam7/transform/blit/source-over behavior, and reproduce R3/R4/R5 pinned-JDK8 conversion semantics. The strict candidate host gate is strengthened to 150 legal PNG cases: the 30 type/depth/interlace combinations crossed with filters 0..4. No neighboring subsystem may be modified.

## P2B — Font / Text

```text
PORT_UNIT=P2B_FONT_TEXT
MIYOO_SOURCE=javax.microedition.lcdui.Font + Anbu.getFont + PlatformGraphics text operations
MIYOO_CURRENT_BEHAVIOR=AWT_FONT_METRICS_AND_GLYPH_RASTER; ATTEMPTS ./font.ttf THEN FALLBACK MiSans Normal
FREEJ2ME_REFERENCE=PINNED_MIYOO_SOURCE_IS_AUTHORITY
JDK_OPENJDK_REFERENCE_IF_REQUIRED=YES_IF_RECONSTRUCTING_AWT_METRICS/RASTER
RG35XX_MEASURED_LIMITATION=APPROXIMATE_WIDTH/HEIGHT + FIXED_5X7_ASCII_GLYPHS + BOX_FALLBACK
EXACT_FAILURE_OR_MISSING_CONTRACT=METRICS_AND_GLYPH_COVERAGE_NOT_CANONICAL_EQUIVALENT
FAILURE_OWNER=RG35XX_FONT_TEXT_BOUNDARY
WHY_MIYOO_AS_IS_CANNOT_WORK=RAW2D_CANNOT_USE_DESKTOP_AWT_GRAPHICS/FONT_BACKEND_ON_DEVICE
MINIMUM_REQUIRED_DELTA=UNRESOLVED_FONT_ASSET_PROVENANCE_AND_REFERENCE_BACKEND
FILES_ALLOWED_TO_CHANGE=DIAGNOSTIC/DOCUMENTATION_ONLY_UNTIL_RESOLVED
FILES_FORBIDDEN_TO_CHANGE=IMAGE_DECODE,INPUT,VIDEO_NATIVE,AUDIO,LIFECYCLE,RMS,JAMVM,GLIBJ,GAME_SPECIFIC_RUNTIME
PARENT_REGRESSION_GATES=P1A_COMPLETE_GRAPHICS+PROTECTED_HASHES
HOST_DIFFERENTIAL_GATE=REQUIRED
MODULE_INTEGRATION_GATE=REQUIRED
PHYSICAL_GATE=FONT_TEXT_MODULE
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

Current evidence:
- Miyoo `Font` obtains real AWT FontMetrics; SMALL/MEDIUM/LARGE map to 12/14/16;
- `Anbu.getFont()` attempts `./font.ttf`, otherwise falls back to `MiSans Normal`;
- Miyoo README describes `font.ttf` as a deployment font asset;
- pinned Miyoo Git tree contains no `.ttf`, so exact font binary/license/provenance is not established by the source pin;
- RG35XX current raw text backing is therefore not accepted as canonical-equivalent.

`P2B_RUNTIME_PATCH=FORBIDDEN_PENDING_FONT_ASSET_REFERENCE`

## P2C — Input / Frontend / Resolution policy

```text
PORT_UNIT=P2C_INPUT_FRONTEND_RESOLUTION
MIYOO_SOURCE=KEYMAP_ENG.md + frontend mapping + MobilePlatform + Canvas/GameCanvas
MIYOO_CURRENT_BEHAVIOR=PHONE_MODE_SWITCHING; DOCUMENTED_MAPPING; ROTATION_COMBO; TOUCH/POINTER_MODE; TEXT_INPUT_HELPERS; FRONTEND_CONFIGURED_LOGICAL_RESOLUTION
FREEJ2ME_REFERENCE=PINNED_MIYOO_SOURCE_IS_AUTHORITY_FOR_FRONTEND_POLICY; MOBILEPLATFORM/CANVAS_OWN_J2ME_SEMANTICS
JDK_OPENJDK_REFERENCE_IF_REQUIRED=NOT_REQUIRED
RG35XX_MEASURED_LIMITATION=PROVEN_12BIT_JS0_MAP_ONLY; FIXED_PROFILE; NO_PROVEN_L2_R2_MENU_EVENTS; NO_MODE/ROTATION/POINTER_POLICY; PRODUCTION_LAUNCHER_FIXED_240x320
EXACT_FAILURE_OR_MISSING_CONTRACT=COMPLETE_PHYSICAL_INPUT_AND_GENERIC_FRONTEND_POLICY_NOT_PROVEN
FAILURE_OWNER=RG35XX_INPUT_FRONTEND_BOUNDARY
WHY_MIYOO_AS_IS_CANNOT_WORK=MIYOO_SDL/HARDWARE_EVENTS_DO_NOT_DIRECTLY_MAP_TO_ORIGINAL_RG35XX_JS0
MINIMUM_REQUIRED_DELTA=UNRESOLVED_PENDING_HARDWARE_EVENT_PROBE_AND_GENERIC_POLICY
FILES_ALLOWED_TO_CHANGE=DIAGNOSTIC_HARDWARE_PROBE/FRONTEND_POLICY_ONLY_UNTIL_RESOLVED
FILES_FORBIDDEN_TO_CHANGE=GRAPHICS_RASTER,IMAGE_DECODE,FONT,AUDIO,RMS,JAMVM,GLIBJ,GAME_SPECIFIC_RUNTIME
PARENT_REGRESSION_GATES=P1A_ACCEPTED_GRAPHICS/INPUT+PROTECTED_IDENTITIES
HOST_DIFFERENTIAL_GATE=REQUIRED_WHERE_HOST_CAN_REPRESENT_POLICY
MODULE_INTEGRATION_GATE=REQUIRED
PHYSICAL_GATE=INPUT_FRONTEND_MODULE; HARDWARE_PROBE_ONLY_WHEN_HOST_CANNOT_OBSERVE_JS0
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

Current evidence:
- RG35XX input owner currently emits D-pad, A/B/X/Y, L1/R1, START/SELECT only;
- Java dispatcher maps those bits to one fixed J2ME semantic profile;
- there is no accepted evidence for original-RG35XX L2/R2/Menu js0 event indices, so they must not be invented;
- Miyoo frontend documents mode switching, rotation and touch/pointer behavior;
- current production launcher passes logical 240x320 while presenter owns physical 640x480 fit/scaling;
- P2C must define a generic logical-resolution/frontend policy with no per-game runtime condition.

`P2C_RUNTIME_PATCH=FORBIDDEN_PENDING_HARDWARE_PROBE_POLICY`

## Audit checkpoint

```text
P1A_GRAPHICS_PHYSICAL_ACCEPTANCE=PASS
P2A_CONTRACT_LOCKED=YES_R1_R5
P2A_RUNTIME_PATCH_AUTHORIZED=YES_SEPARATE_BRANCH_FROM_EXACT_PARENT
P2A_NEXT_ACTION=COMPLETE_OWNER_SCOPED_HOST_CANDIDATE_150_CASE_DIFFERENTIAL_THEN_ONE_MODULE_PHYSICAL_GATE
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_NEXT_ACTION=RESOLVE_FONT_ASSET_PROVENANCE_AND_CANONICAL_METRIC_RASTER_REFERENCE
P2C_RUNTIME_PATCH=FORBIDDEN
P2C_NEXT_ACTION=DESIGN_ORIGINAL_RG35XX_INPUT_EVENT_PROBE_AND_GENERIC_FRONTEND_POLICY
PHYSICAL_TEST_REQUEST_NOW=NO_PENDING_P2A_HOST_CANDIDATE_PASS
TIER0_GAME_TEST_NOW=NO
PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```
