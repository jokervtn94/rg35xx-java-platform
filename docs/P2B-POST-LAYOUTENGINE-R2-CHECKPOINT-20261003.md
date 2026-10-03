# RG35XX P2B Font/Text — Post-LayoutEngine R2 Checkpoint

**Status:** AUDIT_ONLY / PARTIAL  
**Date:** 2026-10-03  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text-post-layout-r2`  
**Parent:** `2d5c4f4b910ef951e5f844f1817363b023a8521f`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

> Audit/documentation checkpoint only. This file authorizes no runtime patch, device package, physical test, stable promotion, or game-specific change.

## 1. Authority / ancestry lock

```text
MIYOO_BUILD_BASE=PRESERVED
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
```

The accepted platform progression remains:

```text
P0_GOLDEN_AUTHORITY=PASS
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

## 2. LayoutEngine R2 evidence now locked

Workflow:

```text
P2B Font JDK8 LayoutEngine ARM Semantic Audit R2
run=37102231021
commit=2d5c4f4b910ef951e5f844f1817363b023a8521f
result=SUCCESS
```

Artifact:

```text
artifact=P2B-layoutengine-r2
sha256=8f9bbeca4f31a31f4e19b2dbaa313653b07231fc60a67b3283053d89c24a922f
```

The audit pins OpenJDK/Temurin `jdk8u504-b01`, the exact `sun/font/layout` tree, the exact vendored FreeType 2.14.3 source tree, the exact Miyoo MiSans diagnostic identity, and the pinned Miyoo ARMv5TE/uClibC toolchain.

The exact bundled LayoutEngine core was cross-built for ARMv5/uClibC with `LE_STANDALONE` / `HEADLESS`, using the audit-only minimal font adapter backed by the source-matched JDK8u504 FreeType engine.

R2 result:

```text
P2B_JDK8_LAYOUTENGINE_SEMANTIC_CASES=192
P2B_ARM_LAYOUTENGINE_SEMANTIC_CASES=192
P2B_LAYOUTENGINE_SEMANTIC_MISMATCH_COUNT=0
P2B_JDK8_LAYOUTENGINE_ARM_R2_CLASSIFICATION=EXACT_FOR_EXISTING_NONSIMPLE_CORPUS
P2B_COMPLEX_LAYOUT_EXISTING_CORPUS=PASS
P2B_RUNTIME_PATCH=FORBIDDEN
DEVICE_TEST=NOT_TESTED
```

This closes the previously open semantic question only for the exact existing 192-case non-simple corpus. It does not by itself authorize runtime integration or claim universal text-layout equivalence.

## 3. Evidence preserved from earlier P2B audit

```text
P2B_FONT_ASSET_IDENTITY=PASS
P2B_JDK8_SEMANTIC_REFERENCE=PASS
P2B_JDK8U504_FREETYPE_ARMV5_UCLIBC_REBUILD=EXACT_FOR_SAMPLED_TABLE
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=EXACT_196608_OF_196608
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CANDISPLAY=EXACT_196608_OF_196608
P2B_JDK8_CHARWIDTH_STYLE_INVARIANCE=EXACT_1376256_OF_1376256
P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_FREETYPE_RAW_DROPIN_BACKEND=REJECTED
P2B_HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED
```

The exact JDK8u504 vendored FreeType engine also reproduced the existing sampled raster table 144/144 exactly on the pinned ARMv5/uClibC toolchain. However, the audit probe renders glyphs sequentially from scaler output; this is not yet a source-closed proof that the complete JDK8/AWT simple `drawString` path has been reconstructed at the RG35XX boundary.

Therefore preserve the existing conservative classification:

```text
P2B_SIMPLE_STRING_DRAW_RASTER=NOT_TESTED
```

## 4. Blockers remaining after LayoutEngine R2

The LayoutEngine semantic blocker is removed for the existing non-simple corpus. The remaining P2B blockers are:

```text
P2B_SIMPLE_STRING_DRAW_RASTER=NOT_TESTED
P2B_MINIMUM_OWNER_SCOPED_RUNTIME_INTERFACE=PARTIAL
P2B_FILES_ALLOWED_TO_CHANGE=PARTIAL
P2B_FONT_PACKAGING_LICENSE_SCOPE=PARTIAL
P2B_BACKEND_SEMANTIC_SYNTHESIS=PARTIAL
P2B_MINIMUM_REQUIRED_DELTA=PARTIAL
```

No physical device cycle is justified while these are unresolved.

## 5. Next approved audit-only unit

### P2B-SIMPLE-DRAWSTRING-PATH-AUDIT

Before any runtime implementation:

1. Trace the exact OpenJDK8u504 simple `Graphics2D.drawString` / text-render path used by the already-pinned P2B JDK8 reference when `FontUtilities.isNonSimpleChar == false`, AA is off, fractional metrics are off, and there are no layout attributes.
2. Identify the exact glyph-list / strike / placement rules that sit between the already-proven `FreetypeFontScaler` glyph bitmap/advance output and the final raster operation.
3. Compare those rules against the existing audit-only sequential scaler raster probe. Do not assume equivalence from matching sampled fingerprints alone.
4. If source proof is insufficient, add one audit-only differential that compares the exact JDK8 simple draw path with an ARM source-matched reconstruction on the existing simple corpus. No adapter/runtime files may change.
5. Only after that closes may P2B define the minimum owner-scoped runtime interface and exact file scope for a candidate.
6. Font provisioning/packaging must remain separate and `PARTIAL`; diagnostic font bytes must not be published as artifacts.

Required outputs:

```text
P2B_SIMPLE_DRAWSTRING_SOURCE_PATH=PASS/PARTIAL
P2B_SIMPLE_STRING_DRAW_RASTER=PASS/NOT_TESTED
P2B_MINIMUM_OWNER_SCOPED_RUNTIME_INTERFACE=PARTIAL
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
DEVICE_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

## 6. Hard stop

Until the simple draw path, owner-scoped runtime interface/file scope, and font provisioning contract are resolved:

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
NEW_TIER1_FIX=FORBIDDEN
```

The next work remains platform-first, Miyoo-first, audit-only.