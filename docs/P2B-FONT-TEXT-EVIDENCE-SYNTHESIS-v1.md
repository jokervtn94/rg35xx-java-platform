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

## 4. Pinned FreeType differential

The exact MiyooCFW toolchain FreeType tested is:

```text
libfreetype.so.6.18.1
SHA256=dc4fe5572e1c9dbd913e70584c7c42e9e7ff6e2e573f637009b309bad6295afa
TARGET=ARMv5TE / EABI5 / soft-float
```

### 4.1 Initial sampled differential

The JDK8 versus ARM FreeType sampled differential produced:

```text
P2B_DIFF_METRIC_CASES=24
P2B_DIFF_METRIC_NORMALIZED_STYLE_EXACT=24
P2B_DIFF_METRIC_TRIPLE_EXACT=8
P2B_DIFF_HEIGHT_EXACT=8
P2B_DIFF_ASCENT_EXACT=24
P2B_DIFF_DESCENT_EXACT=24
P2B_DIFF_SAMPLE_CASES=144
P2B_DIFF_WIDTH_EXACT=108
P2B_DIFF_WIDTH_ABS_ERROR_MAX=7
P2B_DIFF_RASTER_CASES=144
P2B_DIFF_RASTER_BOUNDS_EXACT=23
P2B_DIFF_RASTER_INK_EXACT=0
P2B_DIFF_RASTER_ALPHA_SUM_EXACT=0
P2B_FREETYPE_LAYOUT_CLASSIFICATION=DIVERGENT_REQUIRES_CALIBRATION_OR_OTHER_BACKEND
P2B_FREETYPE_RASTER_CLASSIFICATION=DIAGNOSTIC_ONLY
```

### 4.2 Exhaustive BMP `charWidth` differential

The exhaustive three-size table covered 196,608 cases:

```text
P2B_CHARWIDTH_CASES=196608
P2B_CHARWIDTH_WIDTH_EXACT=196551
P2B_CHARWIDTH_WIDTH_MISMATCH_COUNT=57
P2B_CHARWIDTH_DISPLAY_MISMATCH_COUNT=48
P2B_CHARWIDTH_WIDTH_ABS_ERROR_TOTAL=462
P2B_CHARWIDTH_WIDTH_ABS_ERROR_MAX=10
P2B_CHARWIDTH_CLASSIFICATION=DIVERGENT_REQUIRES_CLASSIFICATION
```

The remaining width mismatches are concentrated in control/format characters observed by the diagnostic, including TAB/LF and Unicode format/control code points such as ZWJ/ZWNJ and bidi controls. Therefore FreeType is very close for ordinary per-character metrics, but is not an exact JDK8 `FontMetrics.charWidth` replacement without explicit JDK-compatible classification/normalization.

### 4.3 Raster variants

The exact raster-variant comparison found the closest tested FreeType mode to be MONO:

```text
MONO:
  CASES=144
  NORMALIZED_STYLE_EXACT=144
  WIDTH_EXACT=144
  BOUNDS_EXACT=144
  INK_EXACT=114
  FP_EXACT=0
```

Other tested threshold variants also produced zero exact pixel fingerprints.

Result:

```text
P2B_FREETYPE_CHARWIDTH_BACKING=PARTIAL
P2B_FREETYPE_DROPIN_RASTER=REJECTED
P2B_FREETYPE_DROPIN_BACKEND=REJECTED
```

`REJECTED` here is scoped only to using raw/default FreeType behavior as a drop-in replacement for the pinned Miyoo JDK8/AWT semantics. It does not reject FreeType as a possible low-level glyph source inside a later proven JDK-compatible RG35XX boundary.

---

## 5. HarfBuzz complex-layout differential

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

This again rejects only direct substitution. HarfBuzz may remain a diagnostic/reference component, but current evidence does not authorize wiring its default output into the production runtime.

---

## 6. Font licensing / packaging evidence

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

## 7. Backend decision after current evidence

Current evidence does **not** authorize any of these shortcuts:

```text
Miyoo/AWT unavailable
  -> use current synthetic 5x7 Raw2D font                 REJECTED
  -> use raw FreeType as drop-in                          REJECTED
  -> use raw HarfBuzz as drop-in                          REJECTED
  -> use per-character additive draw loop for all text    REJECTED
```

The remaining legal engineering path is:

```text
PINNED MIYOO FONT/TEXT CONTRACT
        ↓
JDK8/AWT SEMANTIC REFERENCE
        ↓
CLASSIFY EXACT METRIC / STRING-LAYOUT / RASTER RULES
        ↓
USE NATIVE FONT LIBRARIES ONLY AS LOW-LEVEL SOURCES WHERE PROVEN
        ↓
MINIMUM RG35XX FONT/TEXT BACKING
        ↓
STRICT HOST DIFFERENTIAL
        ↓
ONE P2B MODULE EXERCISER
        ↓
ONE ORIGINAL-RG35XX P2B PHYSICAL MODULE TEST
```

No physical device test is justified yet because the host/backend contract is not complete.

---

## 8. Current locked P2B status

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
P2B_FREETYPE_CHARWIDTH_BACKING=PARTIAL
P2B_FREETYPE_DROPIN_RASTER=REJECTED
P2B_FREETYPE_DROPIN_BACKEND=REJECTED
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

## 9. Next approved P2B action

Do **not** create a runtime font backend yet.

The next approved unit is an audit-only **JDK8 text-backend semantic decomposition** that resolves, separately:

1. exact `FontMetrics` metric derivation and rounding;
2. exact control/format-character `charWidth` / display classification responsible for the remaining 57 exhaustive mismatches;
3. exact simple-string rule versus complex/string-level layout rule;
4. exact glyph raster placement/pixel rule responsible for `MONO` having exact bounds but zero exact fingerprints;
5. the minimum interface needed between `Font` / `PlatformGraphics` and any RG35XX low-level glyph provider;
6. exact owner-scoped files allowed to change;
7. compliant runtime font provisioning/packaging strategy without assuming redistribution permission.

Only after those fields are resolved may a P2B runtime candidate be designed.

---

## 10. Hard stop

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
```

Reason: backend semantics and final font provisioning contract remain `PARTIAL`.
