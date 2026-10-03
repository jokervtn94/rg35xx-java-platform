# RG35XX P2B FONT / TEXT — BOUNDARY DESIGN AUDIT v1

**Status:** AUDIT_ONLY / DESIGN_LOCK  
**Phase:** P2B_FONT_TEXT  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**P2 audit parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Exact OpenJDK reference:** `jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2`

> This document defines the smallest source-grounded P2B boundary that may be implemented later. It does not authorize a runtime patch, device package, stable promotion, font redistribution, or physical-device claim.

---

## 1. Governing ownership

P2B remains a Miyoo-first reconstruction. The semantic owner is the pinned Aweigit path:

- `src/javax/microedition/lcdui/Font.java`
- `src/org/recompile/mobile/PlatformGraphics.java`
- `src/org/recompile/freej2me/Anbu.java`

The accepted RG35XX raw/headless path cannot use the AWT font backing used by those classes, so the failure owner remains:

```text
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
```

P2B must replace only the missing platform backing. It must not create a new MIDP font model, a game-specific text path, or an independent graphics renderer.

---

## 2. Canonical Miyoo behavior that must remain visible at the Java/MIDP layer

### 2.1 `Font`

Pinned Aweigit `Font` uses a single physical font supplied by `Anbu`, derives point size/style, and delegates metrics to AWT `FontMetrics`.

The protected Java-facing behavior is:

```text
SIZE_SMALL  -> 12 pt
SIZE_MEDIUM -> 14 pt
SIZE_LARGE  -> 16 pt
other       -> 12 pt

charWidth(char)     -> backend FontMetrics.charWidth
stringWidth(String) -> null => 0; otherwise backend FontMetrics.stringWidth
substringWidth      -> stringWidth(substring)
charsWidth           -> additive loop over charWidth for each UTF-16 code unit
getHeight            -> backend FontMetrics.getHeight
getBaselinePosition  -> convertSize(size), not backend ascent
```

`face` is retained as MIDP state but does not select another physical font in the pinned backend.

Incoming style values `0..3` map to the JDK/AWT font styles. Values `4..7` normalize to style `0` in the audited JDK8 path. Therefore the RG35XX backing must not invent a separate underline style or treat `4..7` as bold/italic combinations.

### 2.2 `PlatformGraphics.drawString`

Pinned Aweigit owns anchor interpretation and final Java graphics composition. Its AWT path uses whole-string width plus backend ascent/descent:

```text
HCENTER -> x -= stringWidth / 2
RIGHT   -> x -= stringWidth

BOTTOM  -> baselineY = y - descent
VCENTER -> baselineY = y - (descent + ascent) / 2
BASELINE-> baselineY = y
otherwise-> baselineY = y + ascent
```

The backend receives the complete string. The semantic audit proves that the non-simple path cannot be replaced by an always-additive per-character loop.

### 2.3 `Anbu`

Pinned Aweigit normally loads `./font.ttf` into the AWT font stack. The exact official Miyoo release asset used by the audit is:

```text
SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
SIZE=8092724
FONT_NAME=MiSans_Normal
PS_NAME=MiSans-Normal
NUM_GLYPHS=29601
```

`Anbu` itself is not a required RG35XX production modification for P2B. Non-raw/AWT behavior must remain untouched.

---

## 3. Current RG35XX residual that P2B is allowed to replace

The accepted A4/A5 raw path intentionally supplies only a partial font substitute. `RG35XXCore2D` currently contains synthetic font metrics and a 5x7 bitmap glyph table. The A5 raw `PlatformGraphics.drawString` helper draws one UTF-16 code unit at a time and advances the pen by synthetic `charWidth`.

That path is outside the proven P2B semantic contract because:

1. exact JDK8 `charWidth` / `canDisplay` semantics have now been reconstructed independently;
2. exact JDK8 simple-string metric semantics have been reconstructed independently;
3. exact JDK8 bundled LayoutEngine output for the established non-simple corpus has been reconstructed independently;
4. non-simple layout is path-based, not detectable only by comparing additive widths;
5. the existing raw helper applies synthetic underline/bold behavior that does not match the pinned AWT style normalization.

The accepted image/shape/blit parts of `RG35XXCore2D` are not P2B failure owners and are not authorized for replacement.

---

## 4. Proven backend primitives available to the boundary

### 4.1 Exact JDK8-source-compatible FreeType

The exact `jdk8u504-b01` vendored FreeType 2.14.3 source has been rebuilt for the pinned Miyoo ARMv5/uClibC toolchain.

Proven results include:

```text
SAMPLED_RASTER=144/144 EXACT
BMP_CHARWIDTH=196608/196608 EXACT
BMP_CANDISPLAY=196608/196608 EXACT
STYLE_INVARIANCE=1376256/1376256 EXACT
```

### 4.2 Exact public font metrics

Run `37103670937` reproduces the exact JDK8 `FreetypeFontScaler` -> `StrikeMetrics` -> `FontDesignMetrics` integer contract on ARM for all P2B style/size cases:

```text
P2B_FONT_METRICS_CASES=24
P2B_FONT_METRICS_NORMALIZED_EXACT=24
P2B_FONT_METRICS_HEIGHT_EXACT=24
P2B_FONT_METRICS_ASCENT_EXACT=24
P2B_FONT_METRICS_DESCENT_EXACT=24
P2B_FONT_METRICS_LEADING_EXACT=24
P2B_FONT_METRICS_MISMATCH_COUNT=0
P2B_FONT_METRICS_CLASSIFICATION=EXACT_FOR_ALL_P2B_STYLE_SIZE_CASES
```

The exact public values are:

```text
SIZE=12 HEIGHT=17 ASCENT=13 DESCENT=4 LEADING=0
SIZE=14 HEIGHT=19 ASCENT=15 DESCENT=4 LEADING=0
SIZE=16 HEIGHT=22 ASCENT=17 DESCENT=5 LEADING=0
```

These are identical for normalized styles `0..3`; incoming styles `4..7` normalize to style `0`.

The implementation rule is source-derived, not a hard-coded table requirement: FreeType supplies ascender/descender/height at the active scaler size, `StrikeMetrics` converts coordinate sign, and `FontDesignMetrics` applies its `0.95f` integer rounding rules.

### 4.3 Exact JDK8 bundled LayoutEngine

The exact `sun/font/layout` tree has been cross-compiled for ARMv5/uClibC, and the established non-simple semantic corpus is exact on ARM:

```text
CASES=192
GLYPH_COUNT_EXACT=192
GLYPH_IDS_EXACT=192
CHAR_INDICES_EXACT=192
POSITION_FLOAT_BITS_EXACT=192
MISMATCH_COUNT=0
```

Raw/default HarfBuzz remains rejected as a `TextLayout` drop-in.

### 4.4 Native link strategy

Run `37103781371` proves the exact FreeType + LayoutEngine sources can be linked as one ARM shared object using the pinned Miyoo toolchain while statically carrying the C++ runtime:

```text
P2B_NATIVE_LINK_FT_OBJECTS=106
P2B_NATIVE_LINK_LAYOUT_OBJECTS=87
P2B_NATIVE_LINK_LAYOUT_JNI_WRAPPER_EXCLUDED=1
P2B_NATIVE_LINK_STATIC_LIBSTDCXX=PASS
P2B_NATIVE_LINK_STATIC_LIBGCC=PASS
P2B_NATIVE_LINK_SELF_CONTAINED_CXX=PASS
P2B_NATIVE_LINK_DLOPEN_SYSROOT=PASS
```

The produced audit ELF is:

```text
ELF32 / ARM / EABI5 / soft-float
```

Its dynamic `NEEDED` entries are limited to the target C runtime/loader:

```text
libc.so.0
ld-uClibc.so.1
```

No `libstdc++.so` or `libgcc_s.so` runtime dependency is required by this strategy.

This is a capability result only. No `.so` is currently authorized for packaging.

---

## 5. Minimum future RG35XX font/text boundary

The smallest owner-scoped design is one new thin Java adapter backed by one new native font engine.

Conceptual owner names for a future candidate:

```text
Java owner:   org.recompile.rg35xx.RG35XXFontText
Native owner: librg35xx_font.so
```

These names define ownership for the design; they are not runtime files yet.

### 5.1 Java adapter responsibilities

The Java adapter may only provide RG35XX backing services needed by the existing MIDP/Aweigit owners:

```text
initialize / verify exact runtime font
charWidth(char, size, style)
stringWidth(String, size, style)
fontHeight(size, style)
fontAscent(size, style)
fontDescent(size, style)
fontLeading(size, style)
rasterizeWholeString(String, size, style) -> glyph raster/mask + bounds relative to baseline
```

The adapter must not reinterpret MIDP anchors, face constants, clip state, translate state, color state, or image composition.

Null handling required by pinned `Font.stringWidth(null)` remains in Java and returns zero before crossing JNI.

`Font.charsWidth` remains the pinned Aweigit additive UTF-16 loop over `charWidth`; it must not be silently replaced with JDK `FontMetrics.charsWidth`.

`Font.getBaselinePosition()` remains the pinned Aweigit `convertSize(size)` result and must not be replaced by ascent.

### 5.2 Native responsibilities

The native engine may own only the exact JDK8-derived font backend mechanics:

- exact vendored FreeType 2.14.3 initialization and scaler policy;
- exact char-to-glyph / invisible-control behavior already proven by exhaustive audit;
- exact public font metric calculation;
- JDK simple-string width path;
- JDK non-simple trigger classification;
- exact bundled LayoutEngine for complex runs;
- exact glyph placement;
- monochrome glyph rasterization using the proven JDK8 scaler policy;
- assembly of a complete whole-string raster/mask and its baseline-relative bounds.

The native engine must not draw directly into the RG35XX framebuffer and must not own MIDP clipping, translation, anchor interpretation, or source-over blending.

### 5.3 Whole-string raster return contract

The minimum raster result should contain enough information for Java to composite without re-laying out the text:

```text
xOffsetFromBaselineOrigin
yOffsetFromBaseline
width
height
binary/alpha mask pixels
```

The current proven reference is AA off / monochrome. The Java boundary can colorize occupied mask pixels with the current `PlatformGraphics` color, leaving unoccupied pixels transparent.

No separate synthetic underline pass is permitted because incoming style values `4..7` normalize to plain in the pinned JDK/AWT path.

---

## 6. Composition boundary: reuse accepted `RG35XXCore2D.blit`

`RG35XXCore2D.blit(...)` already owns accepted RG35XX raw image composition and provides:

- source-over ARGB blending;
- destination bounds clipping;
- current clip-rectangle clipping;
- optional MIDP image transform handling.

P2B text does not require an image transform. The future raw `PlatformGraphics.drawString` path should therefore:

1. compute the canonical pinned anchor-adjusted baseline `(x, baselineY)` using whole-string width and backend ascent/descent;
2. obtain one complete string raster/mask from `RG35XXFontText`;
3. colorize the mask using current `rgbColor`;
4. call existing `RG35XXCore2D.blit` at `(x + xOffset, baselineY + yOffset)` with the existing translated clip rectangle;
5. perform no per-character layout or synthetic font styling in Java.

This keeps the accepted Core2D source-over/clip behavior as the graphics owner and avoids a second native framebuffer renderer.

Classification:

```text
P2B_TEXT_LAYOUT_OWNER=NATIVE_JDK8_FONT_ENGINE
P2B_TEXT_ANCHOR_OWNER=PINNED_PLATFORMGRAPHICS_JAVA
P2B_TEXT_COLOR_OWNER=PLATFORMGRAPHICS_JAVA
P2B_TEXT_COMPOSITION_OWNER=ACCEPTED_RG35XX_CORE2D_BLIT
P2B_DIRECT_NATIVE_FRAMEBUFFER_TEXT=REJECTED
```

---

## 7. Minimum later production delta allowlist

No production file is changed by this audit. If the remaining raster gate passes, a future P2B candidate may be designed with this maximum owner-scoped delta:

```text
NEW:
  adapter/java/org/recompile/rg35xx/RG35XXFontText.java
  adapter/native/rg35xx_font_jdk8.cpp        (or equivalent single P2B JNI/native owner)
  scripts/stage-p2b-font-text.py             (new overlay only)
  scripts/build-p2b-font-text-candidate.sh   (new candidate builder only)

STAGED CANONICAL OUTPUT ALLOWED TO DIFFER:
  javax/microedition/lcdui/Font.class
  org/recompile/mobile/PlatformGraphics.class
  org/recompile/rg35xx/RG35XXFontText.class
```

The build may source the exact pinned OpenJDK8u504 FreeType/LayoutEngine trees by commit/tree identity and compile them into the P2B native library. Those source trees must not replace the pinned Aweigit submodule or protected Java runtime.

### Explicitly not allowed in the first runtime candidate

```text
upstream/freej2me-miyoomini gitlink
src/org/recompile/freej2me/Anbu.java
adapter/java/org/recompile/rg35xx/RG35XXCore2D.java
adapter/java/org/recompile/rg35xx/RG35XXInput.java
adapter/java/org/recompile/rg35xx/RG35XXVideo.java
JamVM binary
GNU Classpath/glibj.zip
existing accepted native input/video libraries
existing P1A/P2A historical stage/build scripts
packaging/a8/*
```

The old synthetic font helper methods may remain present but dead/unreferenced in `RG35XXCore2D` during the first P2B candidate so that accepted image/shape class behavior does not drift.

Packaging changes are a later gate and are not authorized by this design audit.

---

## 8. Candidate build/link contract after authorization

A future candidate builder must rebuild from the exact accepted P2A parent, then apply only the new P2B overlay, following the existing owner-isolation pattern used by P2A.

The native build contract is:

```text
TOOLCHAIN=docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e
ARCH=armv5te
TUNE=arm926ej-s
FLOAT_ABI=soft
PIC=yes

OPENJDK8=jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2
FREETYPE_INCLUDE_TREE=43f2e4398cfd927acac29ce3515e23a195349eb7
FREETYPE_SRC_TREE=8690dd39ef9f4da5bae000d757fe6dfa2d2102a6
LAYOUT_TREE=bc6641fecdfb59f3146bb1591e090761a24b4061
LAYOUT_DEFINES=LE_STANDALONE,HEADLESS
LAYOUT_SUN_JNI_WRAPPER=EXCLUDED
LIBSTDCXX=STATIC
LIBGCC=STATIC
```

Candidate gates must reject:

- any unexpected JAR entry drift;
- any mutation of protected baseline artifacts;
- any dynamic dependency on `libstdc++.so` or `libgcc_s.so`;
- any unpinned OpenJDK/FreeType/LayoutEngine source;
- any bundled font bytes unless a separate packaging/legal gate explicitly authorizes them.

---

## 9. Runtime font provisioning contract

The exact semantic evidence is tied to the exact 8,092,724-byte MiSans runtime font identified above. The current license audit supports use/embedding language but also contains redistribution restrictions; therefore generic RG35XX packaging permission remains unresolved.

The first candidate design must not silently replace the exact font with another file or with the existing synthetic bitmap font.

The engineering-safe provisioning contract is:

1. accept an explicit external path such as `rg35xx.font.path` when provided;
2. optionally recognize the pinned Miyoo-compatible local path `./font.ttf` when it is user-provisioned;
3. verify exact SHA256 and byte size before enabling the parity backend;
4. fail closed with a clear diagnostic if the exact font is absent or mismatched;
5. do not publish the font in repository commits, CI artifacts, or a generic device package while packaging scope remains `PARTIAL`.

No system-font or synthetic-font fallback may be described as P2B parity.

Classification:

```text
P2B_FONT_IDENTITY_REQUIRED=YES
P2B_FONT_HASH_VERIFICATION_REQUIRED=YES
P2B_FONT_SILENT_SUBSTITUTION=FORBIDDEN
P2B_FONT_BYTES_IN_AUDIT_ARTIFACTS=FORBIDDEN
P2B_FONT_GENERIC_PACKAGE_REDISTRIBUTION=NOT_AUTHORIZED_BY_ENGINEERING_AUDIT
```

---

## 10. Remaining blocker before any runtime candidate

Metrics, simple width semantics, exhaustive `charWidth/canDisplay`, complex LayoutEngine placement, target compilation and native link strategy are proven. The final assembled text raster path is not yet proven.

The next approved audit-only unit is therefore a **whole-string draw-raster differential** using the final proposed backend decomposition:

```text
JDK8/AWT gc.drawString reference
        vs
exact JDK8u504 FreeType + bundled LayoutEngine ARM backend
        -> whole-string baseline-relative mask
```

Minimum corpus:

- existing 14-string P2B shaping corpus;
- all incoming styles `0..7` with audited normalization;
- sizes `12/14/16`;
- both simple and non-simple strings;
- compare whole-string bounds, ink count, and pixel fingerprint;
- compare final logical advance where applicable;
- no Java per-character raster substitution.

Target count for the existing matrix:

```text
14 strings * 8 styles * 3 sizes = 336 cases
```

This gate must use the same exact font identity and the exact JDK8-source-compatible ARM engine. It must not package any font or executable binary in evidence artifacts.

Only if that gate is exact may an owner-scoped host P2B module candidate/exerciser be implemented.

---

## 11. Candidate gate sequence after draw-raster proof

```text
WHOLE_STRING_RASTER_DIFFERENTIAL
        ↓ PASS REQUIRED
P2B OWNER-SCOPED HOST CANDIDATE
        ↓
JAR ENTRY-SET / PROTECTED-HASH GATE
        ↓
P2B HOST MODULE EXERCISER
        ↓ PASS REQUIRED
FONT PROVISIONING / PACKAGE GATE
        ↓
ONE ORIGINAL-RG35XX P2B PHYSICAL MODULE TEST
        ↓ PASS REQUIRED
PROMOTION REVIEW
```

A QEMU/sysroot `dlopen` PASS is not a physical-device PASS.

---

## 12. Current design classification

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
MIYOO_BUILD_BASE=PRESERVED
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY

P2B_FONT_TEXT_BOUNDARY_DESIGN=LOCKED_AUDIT_ONLY
P2B_JAVA_OWNER_SCOPE=FONT_PLUS_PLATFORMGRAPHICS_BACKING_ONLY
P2B_ANBU_RUNTIME_DELTA=NOT_REQUIRED
P2B_CORE2D_IMAGE_SHAPE_DELTA=FORBIDDEN
P2B_CORE2D_BLIT_REUSE=REQUIRED_BY_CURRENT_DESIGN

P2B_FONT_METRICS_ARM=EXACT_24_OF_24
P2B_CHARWIDTH_BMP=EXACT_196608_OF_196608
P2B_CANDISPLAY_BMP=EXACT_196608_OF_196608
P2B_LAYOUTENGINE_ARM_SEMANTICS=EXACT_FOR_EXISTING_NONSIMPLE_LTR_CORPUS
P2B_NATIVE_LINK_SELF_CONTAINED_CXX=PASS
P2B_NATIVE_LINK_DLOPEN_SYSROOT=PASS

P2B_WHOLE_STRING_DRAW_RASTER=NOT_YET_PROVEN_FOR_FINAL_ASSEMBLED_ENGINE
P2B_FONT_PROVISIONING=DESIGN_DEFINED_PACKAGE_PERMISSION_PARTIAL
P2B_MINIMUM_REQUIRED_DELTA=DESIGN_LOCKED_IMPLEMENTATION_NOT_AUTHORIZED
P2B_FILES_ALLOWED_TO_CHANGE=DESIGN_LOCKED_IMPLEMENTATION_NOT_AUTHORIZED

P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

---

## 13. Hard stop

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
```

Reason: the minimum owner boundary, exact metric contract, complex-layout engine and build/link strategy are now source-grounded, but the final assembled whole-string raster path has not yet passed the 336-case differential. Runtime integration before that proof would violate the audit-first and Miyoo-first rules.
