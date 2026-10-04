# RG35XX P2B FONT / TEXT — EVIDENCE SYNTHESIS v1

**Status:** AUDIT_ONLY / PARTIAL  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text`  
**Audit parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  

> This document is diagnostic synthesis only. It authorizes no runtime patch, physical package, stable promotion, or game-specific change.

---

## 1. Locked P2B owner and contract

The P2B port unit remains the pinned Miyoo/Aweigit font/text path:

- `src/javax/microedition/lcdui/Font.java`
- `src/org/recompile/mobile/PlatformGraphics.java`
- `src/org/recompile/freej2me/Anbu.java`

Pinned Miyoo behavior loads `./font.ttf` through the Java/AWT font stack, derives the MIDP size/style faces, obtains metrics through AWT `FontMetrics`, and renders text through the Java2D/AWT graphics path.

The original RG35XX raw/headless path cannot use that AWT backing. The accepted raw path therefore has a real RG35XX boundary gap for font/text backing. Ownership remains:

```text
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
```

This does not transfer MIDP `Font` or text semantics into a new independent RG35XX implementation.

---

## 2. Exact Miyoo runtime font identity

The official Aweigit Miyoo release used by the P2B diagnostics contains one runtime `JAVA/font.ttf` with the locked identity:

```text
P2B_FONT_ENTRY=JAVA/font.ttf
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2B_FONT_SIZE=8092724
P2B_FONT_IDENTITY=PASS
```

JDK8 identifies this font as:

```text
NAME=MiSans_Normal
FAMILY=MiSans_Normal
PS_NAME=MiSans-Normal
NUM_GLYPHS=29601
```

The exact binary identity used by the Miyoo release is therefore locked for differential work. The diagnostic artifacts intentionally do not redistribute the font bytes.

Status:

```text
P2B_FONT_ASSET_IDENTITY=PASS
P2B_FONT_FAMILY_PROVENANCE=PASS
P2B_EXACT_BINARY_PROVENANCE=PARTIAL
```

`P2B_EXACT_BINARY_PROVENANCE=PARTIAL` means that the exact runtime binary is identified and reports itself as MiSans, but this audit has not proven that the exact 8,092,724-byte binary is byte-for-byte identical to a current Xiaomi download package.

---

## 3. JDK8 semantic reference established

The P2B diagnostics use the exact Miyoo font with JDK8 as the backend semantic reference required by the MIYOO-FIRST rule.

Observed protected reference properties include:

- MIDP point sizes 12 / 14 / 16;
- style values 0..7 normalize through the AWT font style path, with values 4..7 not becoming separate AWT font styles;
- JDK8 `FontMetrics` supplies height/ascent/descent/string/character widths;
- `drawString` is not always equivalent to drawing each character independently;
- string-level layout behavior exists and therefore must not be replaced by an always-additive character loop.

The string-shaping diagnostic executed 336 cases and found:

```text
P2B_JDK_SHAPING_CASES=336
P2B_JDK_SHAPING_WIDTH_DIFF_CASES=48
P2B_JDK_SHAPING_RASTER_DIFF_CASES=24
P2B_JDK_SHAPING_RESULT=PASS
P2B_STRING_LAYOUT_CLASSIFICATION=STRING_LEVEL_BEHAVIOR_PRESENT
```

This is a semantic reference result, not a production backend selection.

---

## 4. FreeType differential and exact JDK8 scaler reconstruction

### 4.1 Pinned Miyoo FreeType identity

The exact MiyooCFW toolchain FreeType tested is:

```text
FILE=libfreetype.so.6.18.1
SHA256=dc4fe5572e1c9dbd913e70584c7c42e9e7ff6e2e573f637009b309bad6295afa
FT_LIBRARY_VERSION=2.11.1
TARGET=ARMv5TE / EABI5 / soft-float / uClibC
```

### 4.2 Initial raw/default FreeType differential

The earlier raw/default JDK8 versus ARM FreeType sampled differential produced substantial raster and some metric divergence. The exhaustive BMP `charWidth` table also left 57 mismatches out of 196,608 cases.

Those results remain valid for **raw/default or pinned Miyoo FreeType 2.11.1 substitution**, but they are no longer sufficient to characterize the JDK8 scaler path itself.

The prior broad conclusion is corrected as follows:

```text
RAW_DEFAULT_FREETYPE_AS_JDK8_DROPIN=REJECTED
PINNED_MIYOO_FREETYPE_2_11_1_AS_EXACT_JDK8_ENGINE=REJECTED
FREETYPE_AS_LOW_LEVEL_ENGINE=NOT_REJECTED
OPENJDK8_SCALER_POLICY=REQUIRES_SOURCE_MATCHED_PROBE
```

### 4.3 Exact OpenJDK8 scaler source/config path

The audited JDK reference is Temurin/OpenJDK 8u504-b01. The source-matched diagnostic reproduces the relevant JDK8 `FreetypeFontScaler` policy for this P2B path:

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

The JDK8 scaler context diagnostic also confirms the sampled AWT strike uses AA off, fractional metrics off, and identity device transform.

### 4.4 Actual JDK8 font-engine provenance

Dynamic-loader tracing proves the JDK8 AWT font path loads:

```text
/usr/lib/jvm/temurin-8-jdk-amd64/jre/lib/amd64/libfontmanager.so
/usr/lib/jvm/temurin-8-jdk-amd64/jre/lib/amd64/libfreetype.so
```

The bundled FreeType used by the sampled Temurin 8u504 runtime is:

```text
P2B_JDK8_BUNDLED_FREETYPE_SHA256=2997f135c1f57499c00467690f3ca8346d98029bdd3f80a4f229ea037c72d882
P2B_JDK8_BUNDLED_FREETYPE_VERSION=2.14.3
```

The exact Adoptium JDK8u504 source tag resolves as:

```text
P2B_JDK8U_TAG=jdk8u504-b01
P2B_JDK8U_COMMIT=4efe36434f44bafb854e602ccbbe1b5696fce1a2
P2B_JDK8U_FT_INCLUDE_TREE=43f2e4398cfd927acac29ce3515e23a195349eb7
P2B_JDK8U_FT_SRC_TREE=8690dd39ef9f4da5bae000d757fe6dfa2d2102a6
P2B_JDK8U_FT_C_FILES=106
P2B_JDK8U_FT_DECLARED_VERSION=2.14.3
P2B_JDK8U_FT_SOURCE_PROVENANCE=PASS
```

OpenJDK's bundled build path compiles the vendored `jdk/src/share/native/sun/awt/libfreetype/src` tree with its bundled headers and `FT2_BUILD_LIBRARY`. This gives a source-identity basis stronger than merely matching the FreeType version number.

### 4.5 Decisive same-probe differential

The same source-matched C scaler probe was executed against three FreeType engines while keeping the P2B font, style normalization, sizes, strings, scaler policy, and comparator fixed.

#### Exact Temurin bundled FreeType 2.14.3

```text
P2B_JDK8_FT_SCALER_CASES=144
P2B_JDK8_FT_SCALER_NORMALIZED_STYLE_EXACT=144
P2B_JDK8_FT_SCALER_WIDTH_EXACT=144
P2B_JDK8_FT_SCALER_BOUNDS_EXACT=144
P2B_JDK8_FT_SCALER_INK_EXACT=144
P2B_JDK8_FT_SCALER_FP_EXACT=144
P2B_JDK8_FT_SCALER_INK_ABS_ERROR_TOTAL=0
P2B_JDK8_FT_SCALER_MISMATCH_COUNT=0
P2B_JDK8_FT_SCALER_CLASSIFICATION=EXACT_FOR_SAMPLED_TABLE
```

#### Host system FreeType 2.13.2

```text
WIDTH_EXACT=144
BOUNDS_EXACT=144
INK_EXACT=138
FP_EXACT=138
MISMATCH_COUNT=6
INK_ABS_ERROR_TOTAL=6
```

#### Pinned Miyoo FreeType 2.11.1

```text
WIDTH_EXACT=144
BOUNDS_EXACT=144
INK_EXACT=127
FP_EXACT=127
MISMATCH_COUNT=17
INK_ABS_ERROR_TOTAL=48
MISMATCH_STYLE_1_BOLD=8
MISMATCH_STYLE_2_ITALIC=3
MISMATCH_STYLE_3_BOLD_ITALIC=6
```

All 17 Miyoo residual cases preserve width and raster bounds; the differences are only ink/pixel occupancy in the sampled table.

### 4.6 Exact vendored-source rebuild on host

The exact 106-file FreeType source snapshot from `adoptium/jdk8u@4efe36434f44bafb854e602ccbbe1b5696fce1a2` was rebuilt independently from source, using the vendored headers and `FT2_BUILD_LIBRARY`, then linked into the identical scaler probe.

The host source rebuild produced:

```text
P2B_FT_LIBRARY_VERSION=2.14.3
P2B_JDK8_FT_SCALER_WIDTH_EXACT=144
P2B_JDK8_FT_SCALER_BOUNDS_EXACT=144
P2B_JDK8_FT_SCALER_INK_EXACT=144
P2B_JDK8_FT_SCALER_FP_EXACT=144
P2B_JDK8_FT_SCALER_MISMATCH_COUNT=0
P2B_JDK8_VENDORED_FT_HOST_RECIPE_EQUIVALENCE=PASS
```

This narrows provenance further: the exact sampled behavior is reproducible from the JDK8u504 vendored source snapshot and is not dependent on copying the Temurin host binary.

### 4.7 Exact vendored-source rebuild on Miyoo ARMv5/uClibC toolchain

The same exact JDK8u504 vendored FreeType source snapshot was cross-built with the pinned MiyooCFW ARMv5TE/uClibC compiler and linked into the audit probe. The resulting probe is ARM EABI5 and runs under the target sysroot through qemu.

The ARM source-equivalent probe produced:

```text
P2B_FT_LIBRARY_VERSION=2.14.3
P2B_FT_JDK8_INTERPRETER=35
P2B_FT_JDK8_AA=OFF
P2B_FT_JDK8_FM=OFF
P2B_FT_JDK8_DPI=72
P2B_FT_JDK8_SCALER_CASES=144
P2B_JDK8_FT_SCALER_NORMALIZED_STYLE_EXACT=144
P2B_JDK8_FT_SCALER_WIDTH_EXACT=144
P2B_JDK8_FT_SCALER_BOUNDS_EXACT=144
P2B_JDK8_FT_SCALER_INK_EXACT=144
P2B_JDK8_FT_SCALER_FP_EXACT=144
P2B_JDK8_FT_SCALER_INK_ABS_ERROR_TOTAL=0
P2B_JDK8_FT_SCALER_MISMATCH_COUNT=0
P2B_JDK8_VENDORED_FT_ARM_CLASSIFICATION=EXACT_FOR_SAMPLED_TABLE
```

The audit run completed successfully and removed the font, FreeType source checkout, object files, static archives, and diagnostic executables before evidence upload:

```text
P2B_JDK8_VENDORED_FT_BYTE_LEAK=NO
P2B_RUNTIME_PATCH=FORBIDDEN
DEVICE_TEST=NOT_REQUESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

This is the decisive sampled-raster portability result: **the exact JDK8u504 vendored FreeType source behavior is reproducible on the pinned Miyoo ARMv5/uClibC toolchain with 144/144 exact sampled raster compatibility.** It does not authorize a production library or runtime integration by itself.

### 4.8 Corrected FreeType raster classification

```text
P2B_OPENJDK8_SCALER_POLICY=PROVEN_FOR_SAMPLED_TABLE
P2B_JDK8_EXACT_FREETYPE_BEHAVIOR=PROVEN_FOR_SAMPLED_TABLE
P2B_JDK8U504_FREETYPE_SOURCE_PROVENANCE=PASS
P2B_JDK8U504_FREETYPE_HOST_REBUILD=EXACT_FOR_SAMPLED_TABLE
P2B_JDK8U504_FREETYPE_ARMV5_UCLIBC_REBUILD=EXACT_FOR_SAMPLED_TABLE
P2B_Miyoo_FREETYPE_2_11_1_LAYOUT_PLACEMENT=EXACT_FOR_SAMPLED_TABLE
P2B_Miyoo_FREETYPE_2_11_1_RASTER=RESIDUAL_17_OF_144
P2B_Miyoo_FREETYPE_RESIDUAL_OWNER=FREETYPE_ENGINE_BUILD_BEHAVIOR
P2B_FREETYPE_RAW_DROPIN_BACKEND=REJECTED
```

The older conclusion that FreeType itself could not reproduce JDK8 raster behavior is therefore narrowed. The rejected path is raw/default or pinned Miyoo 2.11.1 behavior as a direct JDK8 substitute. A JDK8-source-compatible FreeType engine is now proven technically viable for the sampled raster table on the target architecture/toolchain.

---

## 5. Exhaustive `charWidth` / `canDisplay` contract

### 5.1 Exact JDK source rule

The exact OpenJDK8u504 `CMap.getControlCodeGlyph()` source was checked against the diagnostic implementation. The JDK invisible/control mapping is:

```text
U+0009 U+000A U+000D
U+200C..U+200F
U+2028..U+202E
U+206A..U+206F
and, for the no-surrogate cmap path used here, U+FFFF -> glyph 0
```

The source-match gate passed:

```text
P2B_JDK8_CMAP_CONTROL_RULE_SOURCE_MATCH=PASS
```

`CharToGlyphMapper.canDisplay()` is driven by whether the mapped glyph differs from the missing glyph; the diagnostic preserves JDK invisible-glyph semantics for the listed controls and the missing-glyph rule for U+FFFF.

### 5.2 Older pinned-Miyoo FreeType 2.11.1 exhaustive result

The earlier three-size table against Miyoo FreeType 2.11.1 covered 196,608 BMP UTF-16 code-unit cases and produced:

```text
P2B_CHARWIDTH_CASES=196608
P2B_CHARWIDTH_WIDTH_EXACT=196551
P2B_CHARWIDTH_WIDTH_MISMATCH_COUNT=57
P2B_CHARWIDTH_DISPLAY_MISMATCH_COUNT=48
P2B_CHARWIDTH_WIDTH_ABS_ERROR_TOTAL=462
P2B_CHARWIDTH_WIDTH_ABS_ERROR_MAX=10
```

That result is now explicitly scoped to the **pinned Miyoo FreeType 2.11.1 engine** and is not a residual semantic uncertainty in the JDK8-compatible design.

### 5.3 Exact JDK8u504 vendored FreeType ARM exhaustive result

Run `37100127253` rebuilt the exact JDK8u504 vendored FreeType 2.14.3 source on the pinned Miyoo ARMv5/uClibC toolchain, generated both JDK8 and ARM tables for sizes 12/14/16, and compared all 196,608 BMP code-unit cases.

The JDK side also checked all styles 1..7 against style 0 across all code units and sizes:

```text
P2B_JDK_CHARWIDTH_TABLE_CASES=196608
P2B_JDK_CHARWIDTH_DISPLAYABLE_COUNT=87684
P2B_JDK_CHARWIDTH_STYLE_COMPARE_CASES=1376256
P2B_JDK_CHARWIDTH_STYLE_MISMATCHES=0
```

The ARM exact-source engine returned the same displayable count:

```text
P2B_FT_JDK8_CHARWIDTH_TABLE_CASES=196608
P2B_FT_JDK8_CHARWIDTH_DISPLAYABLE_COUNT=87684
```

The final differential is exact:

```text
P2B_CHARWIDTH_DIFF_PARSE=PASS
P2B_CHARWIDTH_CASES=196608
P2B_CHARWIDTH_WIDTH_EXACT=196608
P2B_CHARWIDTH_DISPLAY_EXACT=196608
P2B_CHARWIDTH_BOTH_EXACT=196608
P2B_CHARWIDTH_WIDTH_ABS_ERROR_TOTAL=0
P2B_CHARWIDTH_WIDTH_ABS_ERROR_MAX=0
P2B_CHARWIDTH_WIDTH_MISMATCH_COUNT=0
P2B_CHARWIDTH_DISPLAY_MISMATCH_COUNT=0
P2B_CHARWIDTH_CLASSIFICATION=EXACT_ALL_BMP_CODE_UNITS
P2B_CHARWIDTH_DIFF_RESULT=PASS
```

Cleanup also passed without publishing the font, generated binary tables, archive, object files, or diagnostic executable:

```text
P2B_JDK8_VENDORED_CHARWIDTH_BYTE_LEAK=NO
```

### 5.4 Corrected `charWidth` classification

The older 57-width / 48-display mismatch conclusion is therefore corrected and narrowed:

```text
P2B_Miyoo_FREETYPE_2_11_1_EXHAUSTIVE_CHARWIDTH=RESIDUAL_57_OF_196608
P2B_Miyoo_FREETYPE_2_11_1_EXHAUSTIVE_CANDISPLAY=RESIDUAL_48_OF_196608
P2B_JDK8_CMAP_CONTROL_RULE=SOURCE_MATCHED
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=EXACT_196608_OF_196608
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CANDISPLAY=EXACT_196608_OF_196608
P2B_JDK8_CHARWIDTH_STYLE_INVARIANCE=EXACT_1376256_OF_1376256
P2B_FREETYPE_CHARWIDTH_BACKING=PROVEN_WITH_JDK8U504_SOURCE_ENGINE
```

`charWidth` and `canDisplay` are no longer P2B semantic blockers for the proven JDK8u504 source-compatible ARM engine.

---

## 6. String-width and complex-layout boundary

### 6.1 Exact JDK8 simple/non-simple source split

Exact JDK8u504 source establishes two distinct `FontDesignMetrics` measurement paths for a font without layout attributes:

```text
SIMPLE PATH:
  accumulate FontStrike.getCodePointAdvance() values
  round only once at end: (int)(0.5 + total)

NON-SIMPLE PATH:
  if FontUtilities.isNonSimpleChar(ch)
  -> measure the entire string with TextLayout
```

For the P2B context, the exact native scaler source also converts non-fractional horizontal glyph advance with:

```text
FT26Dot6ToInt(x) = ((int)x) >> 6
```

so the FM-off simple-path advances are integer-valued floats before the final `FontDesignMetrics` round.

`FontUtilities.isNonSimpleChar` treats JDK-defined complex-script ranges plus surrogate code units as non-simple. The complex ranges include combining marks, Hebrew/Arabic, Indic/Thai, Tibetan, old Hangul, Khmer, ZWJ/ZWNJ, and selected directional controls.

### 6.2 Simple-string contract audit

Run `37100656286` used the exact Miyoo font, exact Temurin/OpenJDK 8u504 reference, and exact `FontUtilities.isNonSimpleChar` implementation through reflection. It exercised all 8 incoming style values, all three P2B sizes, and the existing 14-string shaping corpus.

Every style/size context had the required source conditions:

```text
P2B_JDK_SIMPLE_STRING_CASES=336
P2B_JDK_SIMPLE_STRING_LAYOUT_ATTRIBUTE_CONTEXTS=0
P2B_JDK_SIMPLE_STRING_AA_CONTEXTS=0
P2B_JDK_SIMPLE_STRING_FM_CONTEXTS=0
```

The corpus partitioned as:

```text
P2B_JDK_SIMPLE_STRING_SIMPLE_CASES=144
P2B_JDK_SIMPLE_STRING_NONSIMPLE_CASES=192
```

The simple samples are indices `0,1,2,3,4,12`; the non-simple samples are `5,6,7,8,9,10,11,13`. The first triggers observed include combining marks, Arabic, Hebrew, Devanagari, Thai, and ZWJ exactly through JDK's own classification.

For every simple case:

```text
stringWidth == charsWidth == sum(FontMetrics.charWidth(each UTF-16 code unit))
```

and the diagnostic produced:

```text
P2B_JDK_SIMPLE_STRING_SIMPLE_MISMATCHES=0
P2B_JDK_SIMPLE_STRING_STRING_CHARS_MISMATCHES=0
P2B_JDK_SIMPLE_STRING_RESULT=PASS
P2B_JDK8_SIMPLE_STRING_BYTE_LEAK=NO
```

Combined with the already-proven 196,608/196,608 exact ARM `charWidth` table and the exact FM-off JDK scaler advance rule, this closes the P2B **simple string metric** contract for strings that have no layout attributes and contain no JDK `isNonSimpleChar` UTF-16 code unit.

Classification:

```text
P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_SIMPLE_STRING_METRIC_SCOPE=NO_LAYOUT_ATTRS_NONCOMPLEX_UTF16
P2B_SIMPLE_STRING_CORPUS_CASES=144
P2B_SIMPLE_STRING_CORPUS_MISMATCHES=0
P2B_SIMPLE_STRING_DRAW_RASTER=NOT_TESTED
```

This audit does **not** prove `drawString` raster for arbitrary simple strings; metric width and draw raster remain separate contracts.

### 6.3 Exact source owner of the non-simple path

The existing 336-case corpus now explains the earlier 48 `stringWidth`-versus-additive differences more precisely. The strings containing Devanagari and ZWJ differ from the rounded-additive path across all 24 style/size contexts, accounting for the 48 width differences. Other non-simple strings may still enter `TextLayout` even when their final integer width happens to equal the additive sum.

Therefore the rule is **path-based**, not "only shape when widths differ".

Exact JDK8u504 source tracing shows that the non-simple `TextLayout` path is backed by JDK's bundled native LayoutEngine, not by direct raw/default HarfBuzz substitution. `SunLayoutEngine.nativeLayout` constructs a `FontInstanceAdapter`, calls:

```text
LayoutEngine::layoutEngineFactory(...)
        ↓
engine->layoutChars(...)
        ↓
getGlyphs / getGlyphPositions / getCharIndices
```

The exact layout source tree at the audited JDK8u504 revision is:

```text
P2B_JDK8_LAYOUT_TREE=bc6641fecdfb59f3146bb1591e090761a24b4061
```

and the OpenJDK `libfontmanager` build recipe compiles the bundled `sun/font/layout` tree with:

```text
-DLE_STANDALONE
-DHEADLESS
```

plus the fontmanager/FreeType headers and libraries.

This is material because the earlier pinned-Miyoo HarfBuzz differential remains non-exact for the exhaustive JDK8 complex-trigger table:

```text
P2B_HB_COMPLEX_JDK_CASES=13764
P2B_HB_COMPLEX_ARM_CASES=13764
P2B_HB_COMPLEX_STRING_WIDTH_EXACT=4262
P2B_HB_COMPLEX_CHARS_WIDTH_EXACT=4262
P2B_HB_COMPLEX_ADDITIVE_WIDTH_EXACT=4611
P2B_HB_COMPLEX_LAYOUT_ADV64_EXACT=0
P2B_HB_COMPLEX_LAYOUT_GLYPHCOUNT_EXACT=12681
P2B_HB_COMPLEX_ALL_SEMANTIC_FIELDS_EXACT=0
P2B_HB_COMPLEX_MISMATCH_COUNT=13764
P2B_HARFBUZZ_COMPLEX_CLASSIFICATION=NOT_EXACT_FOR_EXHAUSTIVE_JDK8_TRIGGER_TABLE
P2B_HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED
```

Raw/default HarfBuzz is therefore not authorized as a `TextLayout` replacement. The canonical backend audit must follow the JDK-bundled LayoutEngine source path instead.

---

## 7. Font licensing / packaging evidence

Xiaomi's current official MiSans material identifies MiSans as free for commercial use and states that embedded-font use is allowed if the software specifically notes that MiSans is used.

However, the same official license text also states that MiSans/font components may not be separately leased, sublicensed, given, loaned, further distributed, or redistributed/sold as font software or copies.

Official sources consulted:

- `https://hyperos.mi.com/font/en/download/`
- `https://hyperos.mi.com/font/en/faq/`

Engineering classification:

```text
P2B_FONT_USE_LICENSE_SOURCE=PASS
P2B_FONT_PACKAGING_LICENSE_SCOPE=PARTIAL
```

`PARTIAL` means the source material supports use/embedding with attribution but also contains explicit restrictions on redistribution of the font software itself. This engineering audit does not make a legal determination that shipping the standalone Miyoo `font.ttf` inside a generic RG35XX installer is permitted.

Until the final packaging form is resolved, P2B diagnostics must continue to avoid publishing font bytes as artifacts.

---

## 8. Backend decision after current evidence

Current evidence does **not** authorize any of these shortcuts:

```text
Miyoo/AWT unavailable
  -> use current synthetic 5x7 Raw2D font                 REJECTED
  -> use raw/default FreeType as drop-in                  REJECTED
  -> use pinned Miyoo FreeType 2.11.1 as raster-exact     REJECTED
  -> use raw HarfBuzz as TextLayout drop-in               REJECTED
  -> decide shaping only when additive widths differ      REJECTED
```

The legal engineering path is now:

```text
PINNED MIYOO FONT/TEXT CONTRACT
        ↓
EXACT JDK8/AWT REFERENCE
        ↓
OPENJDK8 FREETYPEFONTSCALER POLICY — SAMPLED RECONSTRUCTION PROVEN
        ↓
JDK8U504 VENDORED FREETYPE — ARMv5/uClibC SAMPLED RASTER PROVEN EXACT
        ↓
JDK8U504 VENDORED FREETYPE — 196608/196608 CHARWIDTH/CANDISPLAY PROVEN EXACT
        ↓
SIMPLE-STRING METRIC PATH — PROVEN
        ↓
JDK8 BUNDLED LAYOUTENGINE — AUDIT TARGET FOR NON-SIMPLE TEXT
        ↓
MINIMUM RG35XX FONT/TEXT BACKING DESIGN
        ↓
STRICT HOST DIFFERENTIAL
        ↓
ONE P2B MODULE EXERCISER
        ↓
ONE ORIGINAL-RG35XX P2B PHYSICAL MODULE TEST
```

No physical device test is justified yet because the complex string-layout/backend contract remains incomplete.

---

## 9. Current locked P2B status

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
MIYOO_BUILD_BASE=PRESERVED
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY

P2B_SOURCE_AUDIT=PASS
P2B_FONT_ASSET_IDENTITY=PASS
P2B_FONT_FAMILY_PROVENANCE=PASS
P2B_EXACT_BINARY_PROVENANCE=PARTIAL
P2B_FONT_PACKAGING_LICENSE_SCOPE=PARTIAL

P2B_JDK8_SEMANTIC_REFERENCE=PASS
P2B_JDK_STRING_LEVEL_BEHAVIOR=PASS
P2B_OPENJDK8_SCALER_POLICY=PROVEN_FOR_SAMPLED_TABLE
P2B_JDK8_BUNDLED_FREETYPE_VERSION=2.14.3
P2B_JDK8U504_FREETYPE_SOURCE_PROVENANCE=PASS
P2B_JDK8U504_FREETYPE_HOST_REBUILD=EXACT_FOR_SAMPLED_TABLE
P2B_JDK8U504_FREETYPE_ARMV5_UCLIBC_REBUILD=EXACT_FOR_SAMPLED_TABLE
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=EXACT_196608_OF_196608
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CANDISPLAY=EXACT_196608_OF_196608
P2B_JDK8_CHARWIDTH_STYLE_INVARIANCE=EXACT_1376256_OF_1376256
P2B_Miyoo_FREETYPE_VERSION=2.11.1
P2B_Miyoo_FREETYPE_SAMPLED_WIDTH_BOUNDS=EXACT
P2B_Miyoo_FREETYPE_SAMPLED_RASTER=RESIDUAL_17_OF_144
P2B_Miyoo_FREETYPE_EXHAUSTIVE_CHARWIDTH=RESIDUAL_57_OF_196608
P2B_Miyoo_FREETYPE_EXHAUSTIVE_CANDISPLAY=RESIDUAL_48_OF_196608
P2B_JDK8_CMAP_CONTROL_RULE=SOURCE_MATCHED
P2B_FREETYPE_CHARWIDTH_BACKING=PROVEN_WITH_JDK8U504_SOURCE_ENGINE
P2B_FREETYPE_RAW_DROPIN_BACKEND=REJECTED

P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_SIMPLE_STRING_METRIC_SCOPE=NO_LAYOUT_ATTRS_NONCOMPLEX_UTF16
P2B_SIMPLE_STRING_CORPUS_CASES=144
P2B_SIMPLE_STRING_CORPUS_MISMATCHES=0
P2B_SIMPLE_STRING_DRAW_RASTER=NOT_TESTED
P2B_JDK8_COMPLEX_LAYOUT_BACKEND=SOURCE_IDENTIFIED
P2B_JDK8_COMPLEX_LAYOUT_ENGINE=JDK8_BUNDLED_LAYOUTENGINE
P2B_HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED
P2B_COMPLEX_TEXTLAYOUT_PATH=PARTIAL

P2B_BACKEND_SEMANTIC_SYNTHESIS=PARTIAL
P2B_MINIMUM_REQUIRED_DELTA=PARTIAL
P2B_FILES_ALLOWED_TO_CHANGE=PARTIAL

P2B_RUNTIME_PATCH=FORBIDDEN
DEVICE_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

---

## 10. Next approved P2B action

Do **not** create a runtime font backend yet.

The next approved audit-only unit is now the **exact JDK8 bundled LayoutEngine capability/decomposition**:

1. verify the exact `jdk8u504-b01` bundled `sun/font/layout` source tree and `libfontmanager` compile flags/dependencies;
2. determine the minimum `LEFontInstance` interface required by the bundled LayoutEngine (`font tables`, `char->glyph`, `glyph advance`, `glyph point`, units-per-em and pixel-scale information) without importing the JNI `FontInstanceAdapter` into the RG35XX runtime;
3. perform a compile/link-only ARMv5/uClibC audit of the exact bundled LayoutEngine source with `LE_STANDALONE`/`HEADLESS`, excluding runtime integration and device packaging;
4. only if that capability gate passes, build an audit-only minimal font adapter backed by the already-proven exact JDK8u504 FreeType engine and exact MiSans table bytes;
5. compare JDK8 versus ARM bundled-LayoutEngine output on the existing complex-trigger corpus: glyph count, glyph IDs, char indices, positions and final advance before considering raster integration;
6. keep raw/default HarfBuzz rejected unless a source-matched path proves exact semantics;
7. define the minimum owner-scoped runtime interface/files only after complex layout semantics are complete;
8. resolve compliant runtime font provisioning/packaging without assuming redistribution permission.

Only after those fields are resolved may a P2B runtime candidate be designed.

---

## 11. Hard stop

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
```

Reason: sampled raster portability, exhaustive `charWidth/canDisplay`, and the no-layout-attributes simple-string metric path are now proven; complex JDK8 bundled-LayoutEngine semantics, simple-string draw raster coverage, minimum owner-scoped runtime interface, and final font provisioning contract remain `PARTIAL`.
