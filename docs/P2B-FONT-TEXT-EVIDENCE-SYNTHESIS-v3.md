# RG35XX P2B FONT / TEXT — EVIDENCE SYNTHESIS v3

**Status:** AUDIT_ONLY / CURRENT_CORPUS_BACKEND_CLOSED  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text`  
**Audit parent / accepted P2A production parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**Exact OpenJDK reference:** `jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2`

> This document supersedes `P2B-FONT-TEXT-EVIDENCE-SYNTHESIS-v2.md` for current P2B evidence classification. It remains an audit record. It authorizes only the separately locked owner-scoped host candidate described by the P2B pre-change lock. It does not authorize a device package, physical-device PASS, stable promotion, font redistribution, game-specific code, or unrelated runtime changes.

---

## 1. Governing contract remains Miyoo-first

The semantic owner remains the pinned Aweigit/Miyoo implementation:

- `src/javax/microedition/lcdui/Font.java`
- `src/org/recompile/mobile/PlatformGraphics.java`
- `src/org/recompile/freej2me/Anbu.java`

The original RG35XX raw/headless runtime cannot use the AWT/Java2D font backing used by that implementation. The exact failure owner remains:

```text
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
```

The permitted work is therefore reconstruction of the missing backend only. MIDP `Font`, `drawString`, anchor semantics, clip/translate ownership, graphics composition semantics, lifecycle, and game behavior are not transferred to a new independent platform implementation.

---

## 2. Exact font and backend identities

The semantic evidence remains tied to the exact Miyoo runtime font:

```text
FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724
FONT_NAME=MiSans_Normal
FONT_PS_NAME=MiSans-Normal
FONT_NUM_GLYPHS=29601
```

The exact JDK backend lineage is:

```text
OPENJDK8=jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2
FREETYPE_INCLUDE_TREE=43f2e4398cfd927acac29ce3515e23a195349eb7
FREETYPE_SRC_TREE=8690dd39ef9f4da5bae000d757fe6dfa2d2102a6
LAYOUT_TREE=bc6641fecdfb59f3146bb1591e090761a24b4061
```

The established scaler policy remains:

```text
TRUETYPE_INTERPRETER_VERSION=35
AA=OFF
FRACTIONAL_METRICS=OFF
DPI=72
RENDER_TARGET=MONO
ALGORITHMIC_BOLD=FT_GlyphSlot_Embolden
ALGORITHMIC_ITALIC=JDK8_OBLIQUE_MATRIX
STYLE_VALUES_4_TO_7=NORMALIZED_TO_STYLE_0
```

The font bytes are diagnostic input only. They are not committed or uploaded in audit artifacts.

---

## 3. Previously closed primitive evidence

The following prior v2 conclusions remain unchanged:

```text
P2B_JDK8U504_FREETYPE_ARM_RASTER=EXACT_144_OF_144
P2B_CHARWIDTH_BMP=EXACT_196608_OF_196608
P2B_CANDISPLAY_BMP=EXACT_196608_OF_196608
P2B_FONT_METRICS_ARM=EXACT_24_OF_24
P2B_SIMPLE_STRING_SEMANTICS=EXACT_FOR_ESTABLISHED_CORPUS
P2B_JDK8_LAYOUTENGINE_ARM_SEMANTICS=EXACT_FOR_EXISTING_NONSIMPLE_CORPUS
P2B_NATIVE_LINK_SELF_CONTAINED_CXX=PASS
P2B_NATIVE_LINK_DLOPEN_SYSROOT=PASS
```

Raw/default HarfBuzz, synthetic 5x7 text, default FreeType substitution, always-additive per-character rendering, pixel calibration, and heuristic shaping remain rejected as parity implementations.

---

## 4. Final assembled whole-string raster gate — CLOSED

The final proposed backend decomposition was exercised against exact JDK8 `Graphics2D.drawString` for the established 14-string matrix:

```text
14 strings * 8 incoming styles * 3 sizes = 336 cases
```

The reference contains both JDK draw paths:

```text
DIRECT_CASES=144
COMPLEX_CASES=192
RTL_CASES=72
```

The ARM diagnostic used the exact source-pinned JDK8u504 vendored FreeType and bundled LayoutEngine, produced a baseline-relative whole-string monochrome mask, and compared the assembled raster against the JDK8/AWT reference.

Result:

```text
P2B_WHOLE_RASTER_META_EXACT=336
P2B_WHOLE_RASTER_INK_EXACT=336
P2B_WHOLE_RASTER_X0_EXACT=336
P2B_WHOLE_RASTER_Y0_EXACT=336
P2B_WHOLE_RASTER_X1_EXACT=336
P2B_WHOLE_RASTER_Y1_EXACT=336
P2B_WHOLE_RASTER_FP_EXACT=336
P2B_WHOLE_RASTER_DIRECT_WIDTH_EXACT=144
P2B_WHOLE_RASTER_ALL_EXACT=336
P2B_WHOLE_RASTER_MISMATCH_COUNT=0
P2B_WHOLE_RASTER_CLASSIFICATION=EXACT_FOR_EXISTING_336_DRAWSTRING_RASTER_CORPUS
P2B_WHOLE_RASTER_DIFF_RESULT=PASS
```

Evidence:

```text
RUN=37105567710
HEAD=07f7cd7c8202d9e792cfe8448086ff3bafbbfc57
ARTIFACT=11268142443
ARTIFACT_SHA256=7d1e8548e13715a6ba8b33977a9223cec87fd2e9686a14ae0c655d8a969c8c93
BYTE_LEAK=NO
```

Classification:

```text
P2B_WHOLE_STRING_DRAW_RASTER=EXACT_336_OF_336_FOR_ESTABLISHED_CORPUS
P2B_WHOLE_STRING_DRAW_RASTER_RTL=EXACT_72_OF_72_WITHIN_CORPUS
```

This is a bounded corpus claim. It is not an exhaustive Unicode, arbitrary-transform, arbitrary-attribute, or arbitrary-font claim.

---

## 5. Complex `stringWidth` reference decomposition — CLOSED

The whole-raster gate intentionally did not reuse JDK reference width as an ARM result for complex strings. A separate diagnostic decomposed the exact JDK8 `FontDesignMetrics.stringWidth` -> `TextLayout.getAdvance` path for all 192 complex contexts.

The established corpus has one TextLayout component per case. For all 192 cases:

```text
TEXTLAYOUT_ADVANCE == SINGLE_COMPONENT_ADVANCE  (float-bit exact)
RIGHT_ITALIC_PADDING=0
ITALIC_ANGLE=0
STRINGWIDTH == (int)(0.5f + TextLayout.advance)
```

Result:

```text
P2B_JDK8_COMPLEX_WIDTH_CASES=192
P2B_JDK8_COMPLEX_WIDTH_PADDED_CASES=0
P2B_JDK8_COMPLEX_WIDTH_COMPONENT_ADV_EXACT_CASES=192
P2B_JDK8_COMPLEX_WIDTH_ROUNDING_EXACT_CASES=192
P2B_JDK8_COMPLEX_WIDTH_RESULT=PASS
```

Evidence:

```text
RUN=37105906820
HEAD=8656bc970cd365294717dd0256708a13e2a2e750
ARTIFACT=11267883447
ARTIFACT_SHA256=c5b73c47fee04f9d20ec7f73eb46939905a23109520b69137dc00c2f442dae03
BYTE_LEAK=NO
```

The zero-padding conclusion is limited to this exact font/style/size/corpus matrix and is not generalized to arbitrary fonts or transformed text.

---

## 6. Complex `stringWidth` ARM differential — CLOSED

An independent ARMv5/uClibC diagnostic then derived complex width from the exact JDK8 bundled LayoutEngine terminal advance, using the exact reference layout flags and script-run plan and applying the JDK8 final integer rounding rule.

Build/source identity:

```text
TOOLCHAIN=docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e
ARCH=armv5te
TUNE=arm926ej-s
FLOAT_ABI=soft
FREETYPE_OBJECTS=106
LAYOUTENGINE_OBJECTS=87
SUNLAYOUTENGINE_JNI_WRAPPER_EXCLUDED=1
TARGET=ELF32_ARM_EABI5_UCLIBC
```

Result:

```text
P2B_ARM_COMPLEX_WIDTH_CASES=192
P2B_ARM_COMPLEX_WIDTH_RTL_CASES=72
P2B_COMPLEX_WIDTH_META_EXACT=192
P2B_COMPLEX_WIDTH_WIDTH_EXACT=192
P2B_COMPLEX_WIDTH_MISMATCH_COUNT=0
P2B_COMPLEX_WIDTH_CLASSIFICATION=EXACT_FOR_EXISTING_192_COMPLEX_STRINGWIDTH_CORPUS
P2B_COMPLEX_WIDTH_DIFF_RESULT=PASS
P2B_COMPLEX_STRING_WIDTH_ARM_GATE=PASS
```

Evidence:

```text
RUN=37106105836
HEAD=3eb406cba1680c0da82514c27e258b9d67835b88
ARTIFACT=11268220393
ARTIFACT_SHA256=8c3e37de4f2555b71a1c423e4f002b45431ade9f50d39ebe8f941b91c6c35604
BYTE_LEAK=NO
```

Therefore the established full width matrix is closed as:

```text
DIRECT_WIDTH=144/144 EXACT
COMPLEX_WIDTH=192/192 EXACT
TOTAL_STRING_WIDTH=336/336 EXACT
RTL_COMPLEX_WIDTH=72/72 EXACT_WITHIN_CORPUS
```

---

## 7. Current backend closure

For the exact P2B corpus and identities above:

```text
FONT_IDENTITY=LOCKED
PUBLIC_FONT_METRICS=EXACT_24_OF_24
BMP_CHARWIDTH=EXACT_196608_OF_196608
BMP_CANDISPLAY=EXACT_196608_OF_196608
STRING_WIDTH=EXACT_336_OF_336
WHOLE_STRING_RASTER=EXACT_336_OF_336
COMPLEX_RTL_WIDTH=EXACT_72_OF_72_WITHIN_CORPUS
COMPLEX_RTL_RASTER=EXACT_72_OF_72_WITHIN_CORPUS
NATIVE_SOURCE_LINEAGE=PINNED_JDK8U504
ARMV5_UCLIBC_SOURCE_CAPABILITY=PASS
```

Classification:

```text
P2B_BACKEND_SEMANTICS=CLOSED_FOR_ESTABLISHED_P2B_CORPUS
P2B_FINAL_ASSEMBLED_BACKEND_DIFFERENTIAL=PASS
```

The closure is sufficient to stop backend invention and move to the already designed minimum RG35XX boundary. It does not enlarge that boundary.

---

## 8. Remaining non-semantic constraints

The following remain unresolved or intentionally unpromoted:

```text
P2B_FONT_GENERIC_PACKAGE_REDISTRIBUTION=NOT_AUTHORIZED_BY_ENGINEERING_AUDIT
P2B_OWNER_SCOPED_RUNTIME_CANDIDATE=NOT_YET_BUILT_AT_THIS_AUDIT_MILESTONE
P2B_HOST_MODULE_EXERCISER=NOT_YET_RUN_ON_RUNTIME_CANDIDATE
P2B_DEVICE_PACKAGE=FORBIDDEN_UNTIL_HOST_MODULE_GATE
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

The host candidate must use external/user-provided exact font provisioning with SHA256/size verification and fail closed on mismatch. No system font, synthetic font, or silently substituted font may be represented as parity.

---

## 9. Next authorized engineering unit

Backend diagnostic work is now sufficient for one owner-scoped P2B host candidate, subject to the separate pre-change lock.

Required sequence:

```text
P2B PRE-CHANGE LOCK
        ↓
OWNER-SCOPED HOST CANDIDATE
        ↓
JAR ENTRY-SET / PROTECTED-HASH / JAVA6 / NATIVE-DEPENDENCY GATES
        ↓
P2B HOST MODULE EXERCISER + CANONICAL DIFFERENTIAL
        ↓ PASS REQUIRED
FONT PROVISIONING / PACKAGE REVIEW
        ↓
ONE ORIGINAL-RG35XX P2B PHYSICAL MODULE TEST
        ↓ PASS REQUIRED
PROMOTION REVIEW
```

No commercial game is a gate or owner for this phase.

---

## 10. Current status lock

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
MIYOO_BUILD_BASE=PRESERVED
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY

P2B_BACKEND_SEMANTICS=CLOSED_FOR_ESTABLISHED_P2B_CORPUS
P2B_WHOLE_STRING_DRAW_RASTER=EXACT_336_OF_336_FOR_ESTABLISHED_CORPUS
P2B_STRING_WIDTH=EXACT_336_OF_336_FOR_ESTABLISHED_CORPUS
P2B_RTL_SUBSET=EXACT_72_OF_72_FOR_WIDTH_AND_RASTER
P2B_RUNTIME_CANDIDATE_ELIGIBILITY=YES_SUBJECT_TO_PRECHANGE_LOCK

P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
```
