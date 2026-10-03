# RG35XX P2B FONT / TEXT — EVIDENCE SYNTHESIS v2

**Status:** AUDIT_ONLY / BACKEND_SEMANTICS_SUBSTANTIALLY_CLOSED  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text`  
**Audit parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  

> This document supersedes `P2B-FONT-TEXT-EVIDENCE-SYNTHESIS-v1.md` for current P2B classification. It is diagnostic synthesis only. It authorizes no production/runtime patch, device package, physical test, stable promotion, or game-specific change.

---

## 1. Locked owner and Miyoo-first contract

The protected P2B contract remains the pinned Miyoo/Aweigit font/text path:

- `src/javax/microedition/lcdui/Font.java`
- `src/org/recompile/mobile/PlatformGraphics.java`
- `src/org/recompile/freej2me/Anbu.java`

Pinned Miyoo loads `./font.ttf`, derives MIDP sizes/styles through Java/AWT, obtains metrics through `FontMetrics`, and renders through the JDK8 Java2D/AWT font stack. RG35XX raw/headless cannot use that backing directly, so the missing implementation remains an RG35XX graphics-boundary responsibility:

```text
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
```

This does not authorize redefining MIDP `Font`, `drawString`, text metrics, shaping, or glyph raster semantics independently of Miyoo/JDK8.

---

## 2. Locked font identity

The exact Miyoo runtime font used by all differentials remains:

```text
P2B_FONT_ENTRY=JAVA/font.ttf
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2B_FONT_SIZE=8092724
P2B_FONT_NAME=MiSans_Normal
P2B_FONT_PS_NAME=MiSans-Normal
P2B_FONT_NUM_GLYPHS=29601
P2B_FONT_ASSET_IDENTITY=PASS
```

Diagnostics do not publish the font bytes. Final font provisioning/redistribution remains a separate packaging/legal gate.

---

## 3. Exact JDK8 scaler and FreeType behavior

The semantic reference is Temurin/OpenJDK `8u504-b01`, exact source tag `jdk8u504-b01`, commit:

```text
4efe36434f44bafb854e602ccbbe1b5696fce1a2
```

The reconstructed `FreetypeFontScaler` policy is:

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

The JDK8 runtime uses bundled FreeType 2.14.3. The exact vendored JDK8u504 FreeType source trees are:

```text
FT_INCLUDE_TREE=43f2e4398cfd927acac29ce3515e23a195349eb7
FT_SRC_TREE=8690dd39ef9f4da5bae000d757fe6dfa2d2102a6
```

When those exact sources are cross-built using the pinned Miyoo ARMv5/uClibC toolchain and executed with the source-matched scaler probe, the 144-case raster table is exact against JDK8:

```text
WIDTH_EXACT=144/144
BOUNDS_EXACT=144/144
INK_EXACT=144/144
PIXEL_FINGERPRINT_EXACT=144/144
MISMATCH_COUNT=0
```

Evidence run:

```text
RUN=37099799022
```

Therefore:

```text
P2B_OPENJDK8_SCALER_POLICY=PROVEN_FOR_SAMPLED_TABLE
P2B_JDK8U504_FREETYPE_ARM_BEHAVIOR=EXACT_FOR_SAMPLED_TABLE
P2B_Miyoo_FREETYPE_2_11_1_RASTER=RESIDUAL_17_OF_144
```

The old Miyoo toolchain FreeType 2.11.1 residual is not an ARM-architecture limitation and is not a reason to calibrate pixels heuristically.

---

## 4. `charWidth` / `canDisplay` contract closed for BMP code units

The earlier 57 width mismatches were traced to JDK CMap/control semantics rather than ordinary glyph metric divergence. Source-matched handling includes the JDK invisible-control rules around TAB/LF/CR, ZWJ/ZWNJ, bidi/format controls, and terminal missing-glyph behavior.

Using exact JDK8u504 vendored FreeType 2.14.3 on ARMv5/uClibC, the exhaustive table is:

```text
CASES=196608
WIDTH_EXACT=196608/196608
DISPLAY_EXACT=196608/196608
MISMATCH_COUNT=0
```

Evidence run:

```text
RUN=37100127253
```

Classification:

```text
P2B_CHARWIDTH_BMP_SEMANTICS=EXACT_FOR_EXHAUSTIVE_TABLE
```

---

## 5. Simple-string contract closed for current corpus

JDK8 `FontDesignMetrics` uses the simple code-point advance path where no complex trigger is present, with final width rounding at the string level; complex text is routed into layout behavior.

The established 336-context diagnostic classifies:

```text
TOTAL_CONTEXTS=336
SIMPLE_CONTEXTS=144
NONSIMPLE_CONTEXTS=192
```

For all 144 simple contexts:

```text
stringWidth == charsWidth == sum(charWidth over the UTF-16 units)
```

Evidence run:

```text
RUN=37100656286
```

Classification:

```text
P2B_SIMPLE_STRING_SEMANTICS=EXACT_FOR_ESTABLISHED_CORPUS
```

---

## 6. Complex text backend lineage

OpenJDK8 source establishes the relevant lineage as:

```text
FontDesignMetrics / TextLayout
    -> GlyphLayout
    -> ScriptRun
    -> SunLayoutEngine.nativeLayout
    -> FontInstanceAdapter
    -> bundled IBM/ICU LayoutEngine
    -> JDK font strike / FreetypeFontScaler
```

Default/raw HarfBuzz is not an exact replacement for this JDK8 contract. The exhaustive complex-trigger HarfBuzz differential remains:

```text
CASES=13764
ALL_SEMANTIC_FIELDS_EXACT=0
MISMATCH_COUNT=13764
P2B_HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED
```

This is a rejection of direct substitution, not of HarfBuzz as an unrelated diagnostic library.

---

## 7. Exact JDK8 LayoutEngine ARM capability

The exact bundled LayoutEngine source tree is:

```text
JDK8_LAYOUT_TREE=bc6641fecdfb59f3146bb1591e090761a24b4061
```

With the pinned Miyoo ARMv5/uClibC toolchain:

```text
CORE_CPP_COMPILED=87
JNI_WRAPPER_EXCLUDED=SunLayoutEngine.cpp
WHOLE_ARCHIVE_FORCE_LINK=PASS
EXTERNAL_DEPENDENCY_CLASS=libstdc++ / libc / libm
```

Evidence run:

```text
RUN=37100993243
```

This proves target compile/link capability. Semantic equivalence is established separately below.

---

## 8. JDK8 LayoutEngine semantic differential — host source-equivalence gate

A diagnostic-only `LEFontInstance` provider was built directly from the exact JDK8 contracts instead of inventing a new text engine. It supplies:

- exact JDK8u504 vendored FreeType 2.14.3 behavior;
- exact 72-DPI / interpreter-35 / AA-off / FM-off scaler rules;
- exact SFNT table access needed by LayoutEngine;
- JDK invisible-control behavior;
- `FontInstanceAdapter` mapped ZWJ/ZWNJ behavior;
- glyph advances and glyph-point semantics;
- identity transform behavior for the established P2B context.

The JDK8 reference itself emits exact `ScriptRun` records, script code, combining-mark engine flag (`0x4`), `lang=-1`, and final `GlyphVector` output. This avoids reimplementing JDK run segmentation on the target.

Corpus:

```text
CASES=192
SCRIPT_RUNS=192
COMBINING_FLAG_RUNS=72
DIRECTION=LTR
LANGUAGE=-1
```

The same exact JDK8u504 FreeType + LayoutEngine source, rebuilt natively on the host through the diagnostic provider, produced:

```text
META_EXACT=192/192
GLYPH_COUNT_EXACT=192/192
GLYPH_IDS_EXACT=192/192
CHAR_INDICES_EXACT=192/192
POSITION_FLOAT_BITS_EXACT=192/192
POSITION_1_64_EXACT=192/192
ALL_EXACT=192/192
MISMATCH_COUNT=0
CLASSIFICATION=EXACT_FOR_EXISTING_NONSIMPLE_CORPUS
```

Evidence:

```text
RUN=37102055227
ARTIFACT=11266237434
```

This host gate proves the diagnostic `LEFontInstance` bridge is source-equivalent for the established non-simple corpus before ARM architecture is introduced.

---

## 9. JDK8 LayoutEngine semantic differential — ARMv5/uClibC gate

The same diagnostic bridge and the same exact JDK8u504 vendored FreeType/LayoutEngine source were then cross-built with:

```text
arm-miyoo-linux-uclibcgnueabi-gcc/g++ 9.4.0
-march=armv5te
-mtune=arm926ej-s
-mfloat-abi=soft
uClibC target sysroot
```

The produced target executable is ARM EABI5 with `/lib/ld-uClibc.so.0` and was executed under QEMU against the pinned Miyoo sysroot.

Result against the exact JDK8 reference:

```text
P2B_LAYOUTENGINE_SEMANTIC_CASES=192
P2B_LAYOUTENGINE_SEMANTIC_META_EXACT=192
P2B_LAYOUTENGINE_SEMANTIC_GLYPH_COUNT_EXACT=192
P2B_LAYOUTENGINE_SEMANTIC_GLYPHS_EXACT=192
P2B_LAYOUTENGINE_SEMANTIC_INDICES_EXACT=192
P2B_LAYOUTENGINE_SEMANTIC_POS_BITS_EXACT=192
P2B_LAYOUTENGINE_SEMANTIC_POS64_EXACT=192
P2B_LAYOUTENGINE_SEMANTIC_ALL_EXACT=192
P2B_LAYOUTENGINE_SEMANTIC_MISMATCH_COUNT=0
P2B_LAYOUTENGINE_SEMANTIC_CLASSIFICATION=EXACT_FOR_EXISTING_NONSIMPLE_CORPUS
```

Evidence:

```text
RUN=37102231021
ARTIFACT=11265913223
ARTIFACT_SHA256=8f9bbeca4f31a31f4e19b2dbaa313653b07231fc60a67b3283053d89c24a922f
```

No font bytes or source-build binaries remain in the uploaded evidence artifact.

Classification:

```text
P2B_JDK8_LAYOUTENGINE_HOST_SEMANTICS=EXACT_FOR_EXISTING_NONSIMPLE_LTR_CORPUS
P2B_JDK8_LAYOUTENGINE_ARM_SEMANTICS=EXACT_FOR_EXISTING_NONSIMPLE_LTR_CORPUS
```

This does **not** claim exhaustive Unicode, RTL, arbitrary transforms, or all possible JDK text attributes. It closes the bounded P2B LTR non-simple corpus already established by the Miyoo/JDK8 audit and proves that exact source lineage is portable to the target toolchain without substituting HarfBuzz.

---

## 10. Corrected backend classification

The legal backend direction is now evidence-backed:

```text
PINNED MIYOO FONT/TEXT CONTRACT
        ↓
JDK8/AWT SEMANTIC REFERENCE
        ↓
OPENJDK8 FreetypeFontScaler POLICY
        ↓
EXACT JDK8u504 VENDORED FREETYPE 2.14.3 BEHAVIOR
        ↓
SIMPLE STRING: SOURCE-MATCHED METRICS / ADVANCE PATH
COMPLEX STRING: EXACT JDK8 BUNDLED LAYOUTENGINE LINEAGE
        ↓
MINIMUM RG35XX FONT/TEXT BOUNDARY
```

Rejected shortcuts remain:

```text
synthetic 5x7 Raw2D font                         REJECTED
raw/default FreeType as JDK8 drop-in             REJECTED
Miyoo FreeType 2.11.1 as raster-exact            REJECTED
raw/default HarfBuzz as complex-layout drop-in   REJECTED
always-additive per-character draw loop          REJECTED
pixel calibration / heuristic shaping            REJECTED
```

---

## 11. Current locked P2B status

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
MIYOO_BUILD_BASE=PRESERVED
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY

P2B_SOURCE_AUDIT=PASS
P2B_FONT_ASSET_IDENTITY=PASS
P2B_FONT_PACKAGING_LICENSE_SCOPE=PARTIAL

P2B_OPENJDK8_SCALER_POLICY=PROVEN_FOR_SAMPLED_TABLE
P2B_JDK8U504_FREETYPE_ARM_RASTER=EXACT_FOR_SAMPLED_TABLE
P2B_CHARWIDTH_BMP_SEMANTICS=EXACT_FOR_EXHAUSTIVE_TABLE
P2B_SIMPLE_STRING_SEMANTICS=EXACT_FOR_ESTABLISHED_CORPUS
P2B_JDK8_LAYOUTENGINE_ARM_CAPABILITY=PASS
P2B_JDK8_LAYOUTENGINE_HOST_SEMANTICS=EXACT_FOR_EXISTING_NONSIMPLE_LTR_CORPUS
P2B_JDK8_LAYOUTENGINE_ARM_SEMANTICS=EXACT_FOR_EXISTING_NONSIMPLE_LTR_CORPUS

P2B_BACKEND_SEMANTIC_SYNTHESIS=PASS_FOR_CURRENT_P2B_CORPUS
P2B_MINIMUM_REQUIRED_DELTA=PARTIAL
P2B_FILES_ALLOWED_TO_CHANGE=PARTIAL
P2B_FONT_PROVISIONING=PARTIAL

P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
DEVICE_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

---

## 12. Next approved P2B action

Backend semantics are now sufficiently evidenced to begin the **minimum owner-scoped boundary design audit**. This is still not runtime implementation.

The next unit must resolve from pinned Miyoo and existing RG35XX ownership:

1. the smallest interface required by `Font` and `PlatformGraphics` for metrics, simple-string width, complex layout, and glyph mask/raster emission;
2. which logic must remain Java/MIDP-facing and which exact JDK backend semantics may live behind the RG35XX boundary;
3. the exact production files allowed to change, with no game-specific code and no unrelated graphics refactor;
4. how the exact JDK8u504 FreeType/LayoutEngine source or equivalent proven objects would be built/linked for ARMv5/uClibC without replacing the platform baseline;
5. the runtime font provisioning strategy, without assuming permission to redistribute the standalone Miyoo `font.ttf`;
6. the module-level host differential/exerciser required before any physical device package is requested.

Only after this boundary design is source-grounded and owner-scoped may a P2B runtime candidate branch be created.

---

## 13. Hard stop

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
```

Reason: backend semantics for the current P2B corpus are now proven, but the minimum production boundary/files, build/link integration, font provisioning, and module-level host exerciser contract are not yet locked.
