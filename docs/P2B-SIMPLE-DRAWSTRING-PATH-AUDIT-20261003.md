# RG35XX P2B Font/Text — Simple drawString Path Audit

**Status:** AUDIT_ONLY / PASS_FOR_DECLARED_SCOPE  
**Date:** 2026-10-03  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text-post-layout-r2`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**OpenJDK reference:** `adoptium/jdk8u@4efe36434f44bafb854e602ccbbe1b5696fce1a2` (`jdk8u504-b01`)

> Audit-only source/evidence closure. No runtime file is modified and no device package is authorized.

## 1. Question

Does the existing 144-case JDK8-vs-ARM raster differential actually cover the JDK8 simple `Graphics2D.drawString` path, or is it only a coincidental glyph-bitmap comparison?

## 2. Exact JDK8 render path

Exact OpenJDK8u504 `sun/java2d/pipe/GlyphListPipe.java` shows:

```text
drawString(...)
  -> get FontInfo
  -> GlyphList.setFromString(...)
     -> if simple mapping succeeds: drawGlyphList(...)
     -> if shaping is required: TextLayout fallback
```

Exact `sun/font/GlyphList.java` shows the simple path:

```text
setFromString
  -> charsToGlyphsNS(...)
  -> fontStrike.getGlyphImagePtrs(...)
  -> starting device position = x + 0.5, y + 0.5
  -> per glyph:
       topLeftX/topLeftY from GlyphInfo
       floor(current position + topLeft)
       accumulate xAdvance/yAdvance from GlyphInfo
```

Exact `sun/font/TrueTypeGlyphMapper.java` shows `charsToGlyphsNS()` returns the shaping-required signal only for JDK complex-layout code points (and supplementary-char handling). The existing raster corpus strings are simple under that rule:

```text
ABCxyz09
iiiiWWWW
Tieng Viet
Tiếng Việt
Đặng
中文
```

Their precomposed Vietnamese code points and CJK code points do not fall in the JDK8 complex-layout ranges used by `charsToGlyphsNS()`.

Therefore the actual JDK reference `Graphics2D.drawString()` calls in `RG35XXP2BJdkRasterFingerprintDiagnostic` take the `GlyphList` simple path, not the `TextLayout` complex path, for this declared corpus.

## 3. Placement / advance equivalence to the ARM audit probe

Exact OpenJDK8u504 `freetypeScaler.c` records glyph image placement as:

```text
topLeftX = bitmap_left
topLeftY = -bitmap_top
```

For the FM-off horizontal path it records:

```text
advanceX = FT26Dot6ToInt(ftglyph->advance.x)
FT26Dot6ToInt(x) = ((int)x) >> 6
```

The existing audit-only ARM scaler probe `p2b_freetype_jdk8_scaler_arm.c` uses the same source-matched JDK8 policy and, for each simple glyph, uses:

```text
gx = pen + bitmap_left
gy = -bitmap_top
pen += advance.x >> 6
```

The JDK raster diagnostic draws at integral device coordinates. `GlyphList` starts at `x + 0.5` and floors the position plus integer `topLeftX/topLeftY`; therefore for this context the resulting integer placement equals the probe's integral baseline placement.

No fractional-metrics or anti-aliasing context is active in the locked P2B reference.

## 4. Existing differential evidence

The JDK reference diagnostic fingerprints the occupied pixel set produced by actual `Graphics2D.drawString()` for:

```text
8 incoming style values
x 3 sizes (12/14/16)
x 6 simple strings
= 144 cases
```

The exact JDK8u504 vendored FreeType 2.14.3 source was rebuilt with the pinned Miyoo ARMv5TE/uClibC toolchain and run through the source-matched scaler probe.

The existing comparator records for that exact-source ARM engine:

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

Because the exact JDK source path, placement rule, scaler rule, and existing pixel differential now align, this is no longer classified merely as a glyph-scaler sample disconnected from `drawString`.

## 5. Scoped classification

```text
P2B_SIMPLE_DRAWSTRING_SOURCE_PATH=PASS
P2B_SIMPLE_STRING_DRAW_RASTER=PASS
P2B_SIMPLE_STRING_DRAW_RASTER_SCOPE=EXISTING_144_CASE_SIMPLE_RASTER_CORPUS
P2B_SIMPLE_STRING_DRAW_RASTER_UNIVERSAL_EQUIVALENCE=NOT_TESTED
```

The `PASS` is intentionally scoped. It proves the declared 144-case simple raster corpus and the exact source path used by that corpus. It does not claim every possible simple Unicode string, transform, AA mode, fractional-metrics mode, font size, or Graphics2D surface mode.

## 6. What remains open

After LayoutEngine R2 and this simple draw-path audit:

```text
P2B_COMPLEX_LAYOUT_EXISTING_CORPUS=PASS
P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_SIMPLE_STRING_DRAW_RASTER=PASS_FOR_DECLARED_SCOPE
P2B_MINIMUM_OWNER_SCOPED_RUNTIME_INTERFACE=PARTIAL
P2B_FILES_ALLOWED_TO_CHANGE=PARTIAL
P2B_FONT_PACKAGING_LICENSE_SCOPE=PARTIAL
P2B_MINIMUM_REQUIRED_DELTA=PARTIAL
```

The next approved P2B action is therefore **documentation/design only**:

```text
P2B-MINIMUM-OWNER-SCOPED-RUNTIME-INTERFACE-AUDIT
```

It must map the minimum Miyoo-owned font/text contract onto the already-proven JDK8u504 FreeType + LayoutEngine semantics, enumerate exactly which RG35XX boundary files/classes would be allowed to change, and keep all canonical/Miyoo MIDP `Font` semantics outside the adapter.

No runtime implementation is authorized by this audit.

## 7. Hard stop

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
```
