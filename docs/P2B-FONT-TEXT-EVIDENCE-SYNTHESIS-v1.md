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

The earlier raw/default JDK8 versus ARM FreeType sampled differential produced substantial raster and some metric divergence. The exhaustive BMP `charWidth` table also left 57 mismatches out of 196,608 cases, concentrated in control/format characters.

Those results remain valid for **raw/default FreeType substitution**, but they are no longer sufficient to characterize the JDK8 scaler path itself.

The prior broad conclusion is therefore corrected as follows:

```text
RAW_DEFAULT_FREETYPE_AS_JDK8_DROPIN=REJECTED
FREETYPE_AS_LOW_LEVEL_ENGINE=NOT_REJECTED
OPENJDK8_SCALER_POLICY=REQUIRES_SOURCE_MATCHED_PROBE
```

### 4.3 Exact OpenJDK8 scaler source/config path

The audited JDK reference is Temurin/OpenJDK 8u504-b01. The `freetypeScaler.c` blob at the exact `jdk8u504-b01` source revision is the same blob used by the source reconstruction audit.

The source-matched diagnostic reproduces the relevant JDK8 `FreetypeFontScaler` policy for this P2B path:

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

This proves the reconstructed scaler policy is source-equivalent for the sampled 144-case raster table when backed by the exact FreeType behavior used by the JDK8 reference.

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

The same exact JDK8u504 vendored FreeType source snapshot was then cross-built with the pinned MiyooCFW ARMv5TE/uClibC compiler and linked statically into the audit probe. The resulting probe is ARM EABI5 and runs under the target sysroot through qemu.

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

This is the decisive portability result for the sampled scaler table: **the exact JDK8u504 vendored FreeType source behavior is reproducible on the pinned Miyoo ARMv5/uClibC toolchain with 144/144 exact sampled raster compatibility.** It does not authorize a production library or runtime integration by itself.

### 4.8 Corrected FreeType classification

The evidence now supports:

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

The older conclusion that FreeType itself could not reproduce JDK8 raster behavior is therefore narrowed. The rejected path is **raw/default or pinned Miyoo 2.11.1 behavior as a direct JDK8 substitute**. A JDK8-source-compatible FreeType engine is now proven technically viable for the sampled raster table on the target architecture/toolchain.

Production direction, if later authorized, must preserve **OpenJDK8 scaler semantics plus the proven JDK8u504 vendored FreeType behavior** rather than substitute raw/default FreeType calls.

---

## 5. Exhaustive `charWidth` / `canDisplay` status

The earlier exhaustive three-size table covered 196,608 BMP UTF-16 code-unit cases against the pinned Miyoo FreeType 2.11.1 engine:

```text
P2B_CHARWIDTH_CASES=196608
P2B_CHARWIDTH_WIDTH_EXACT=196551
P2B_CHARWIDTH_WIDTH_MISMATCH_COUNT=57
P2B_CHARWIDTH_DISPLAY_MISMATCH_COUNT=48
P2B_CHARWIDTH_WIDTH_ABS_ERROR_TOTAL=462
P2B_CHARWIDTH_WIDTH_ABS_ERROR_MAX=10
P2B_CHARWIDTH_CLASSIFICATION=DIVERGENT_REQUIRES_CLASSIFICATION
```

The exact OpenJDK8u504 `CMap.getControlCodeGlyph()` source has now also been checked. Its invisible/control mapping is exactly the rule already encoded in the source-matched C diagnostic:

```text
U+0009 U+000A U+000D
U+200C..U+200F
U+2028..U+202E
U+206A..U+206F
and, for no-surrogate cmap paths, U+FFFF -> glyph 0
```

Therefore the remaining 57 old width mismatches cannot be attributed merely to an omitted control-code list in the diagnostic. However, that exhaustive table was generated against the pinned Miyoo FreeType 2.11.1 engine, not against the newly proven JDK8u504 vendored FreeType ARM rebuild.

Current classification:

```text
P2B_JDK8_CMAP_CONTROL_RULE=SOURCE_MATCHED
P2B_Miyoo_FREETYPE_2_11_1_EXHAUSTIVE_CHARWIDTH=RESIDUAL_57_OF_196608
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=NOT_YET_TESTED
P2B_FREETYPE_CHARWIDTH_BACKING=PARTIAL
```

The next char-width audit must therefore rerun the exact same 196,608-case table against the exact JDK8u504 vendored FreeType ARM build before any further control/format calibration is considered.

---

## 6. HarfBuzz complex-layout differential

The pinned Miyoo toolchain also contains HarfBuzz `libharfbuzz.so.0.30302.0`. The exhaustive JDK8 complex-trigger table was compared to ARM HarfBuzz for sizes 12 / 14 / 16.

Results:

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
P2B_HB_COMPLEX_MISMATCH_BY_CLASS:
  LAYOUT_ADV_AND_GLYPHCOUNT_MISMATCH=45
  LAYOUT_ADV_MISMATCH=4217
  WIDTH_MISMATCH=9502
P2B_HARFBUZZ_COMPLEX_CLASSIFICATION=NOT_EXACT_FOR_EXHAUSTIVE_JDK8_TRIGGER_TABLE
```

Therefore:

```text
P2B_HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED
```

This rejects only direct substitution. HarfBuzz may remain a diagnostic/reference component, but current evidence does not authorize wiring its default output into the production runtime.

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
  -> use raw HarfBuzz as drop-in                          REJECTED
  -> use per-character additive draw loop for all text    REJECTED
```

The legal engineering path is now more specific:

```text
PINNED MIYOO FONT/TEXT CONTRACT
        ↓
EXACT JDK8/AWT REFERENCE
        ↓
OPENJDK8 FREETYPEFONTSCALER POLICY — SAMPLED RECONSTRUCTION PROVEN
        ↓
JDK8U504 VENDORED FREETYPE — ARMv5/uClibC SAMPLED RASTER PROVEN EXACT
        ↓
PROVE EXHAUSTIVE CHARWIDTH/CANDISPLAY WITH THAT SAME ARM ENGINE
        ↓
RESOLVE SIMPLE-STRING VS COMPLEX/STRING-LEVEL LAYOUT SEMANTICS
        ↓
MINIMUM RG35XX FONT/TEXT BACKING DESIGN
        ↓
STRICT HOST DIFFERENTIAL
        ↓
ONE P2B MODULE EXERCISER
        ↓
ONE ORIGINAL-RG35XX P2B PHYSICAL MODULE TEST
```

No physical device test is justified yet because the text-layout/backend contract remains incomplete.

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
P2B_Miyoo_FREETYPE_VERSION=2.11.1
P2B_Miyoo_FREETYPE_SAMPLED_WIDTH_BOUNDS=EXACT
P2B_Miyoo_FREETYPE_SAMPLED_RASTER=RESIDUAL_17_OF_144
P2B_JDK8_CMAP_CONTROL_RULE=SOURCE_MATCHED
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=NOT_YET_TESTED
P2B_FREETYPE_CHARWIDTH_BACKING=PARTIAL
P2B_FREETYPE_RAW_DROPIN_BACKEND=REJECTED
P2B_HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED

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

The next approved audit-only unit is now narrower:

1. rerun the exact 196,608-case BMP `FontMetrics.charWidth` + `Font.canDisplay` table using the proven JDK8u504 vendored FreeType ARMv5/uClibC build;
2. require exact width/display equality or classify every remaining mismatch by exact JDK source semantics before any implementation design;
3. if the exhaustive table becomes exact, correct the older 57-mismatch conclusion so it is explicitly scoped to the Miyoo FreeType 2.11.1 engine;
4. then decompose JDK8 simple-string versus complex/string-level layout behavior without replacing it with an always-additive character loop or raw HarfBuzz output;
5. define the minimum owner-scoped interface and files only after both metric and string-layout semantics are proven;
6. resolve compliant runtime font provisioning/packaging without assuming redistribution permission.

Only after those fields are resolved may a P2B runtime candidate be designed.

---

## 11. Hard stop

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
```

Reason: sampled JDK8 scaler raster portability to ARMv5/uClibC is now proven exact, but exhaustive `charWidth/canDisplay`, string-layout semantics, minimum owner-scoped runtime interface, and final font provisioning contract remain `PARTIAL`.
