# RG35XX P2B Font/Text — Minimum Owner-Scoped Runtime Interface Audit

**Status:** AUDIT_ONLY / PARTIAL  
**Date:** 2026-10-03  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text-post-layout-r2`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

> This document locks ownership and the minimum boundary interface only. It does **not** authorize a runtime patch, native library, device package, physical test, stable promotion, or font redistribution.

## 1. Port-decision fields

```text
PORT_UNIT=P2B_FONT_TEXT
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
MIYOO_BUILD_BASE=PRESERVED
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
```

Exact P2B evidence already closed before this interface audit:

```text
P2B_FONT_ASSET_IDENTITY=PASS
P2B_JDK8_SEMANTIC_REFERENCE=PASS
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=EXACT_196608_OF_196608
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CANDISPLAY=EXACT_196608_OF_196608
P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_SIMPLE_DRAWSTRING_SOURCE_PATH=PASS
P2B_SIMPLE_STRING_DRAW_RASTER=PASS_FOR_EXISTING_144_CASE_CORPUS
P2B_COMPLEX_LAYOUT_EXISTING_CORPUS=PASS_192_OF_192
```

## 2. Exact current boundary and divergence

Pinned Miyoo `Font.java` owns the MIDP-facing API. It derives `Anbu.getFont()` through AWT and uses `FontMetrics` for `charWidth`, `getHeight`, and `stringWidth`. Its `getBaselinePosition()` is not an AWT query; it returns the Miyoo `convertSize(size)` value directly.

Pinned Miyoo `PlatformGraphics.drawString()` owns anchor semantics. It uses the current AWT `FontMetrics` for width/ascent/descent, converts anchor coordinates to a baseline position, then calls `Graphics2D.drawString()` once for the whole string.

The accepted RG35XX Raw2D boundary intentionally has `gc=null` and `fm=null`, so A4/A5 staging introduced a headless fallback through `RG35XXCore2D`.

The current A5 fallback is provisional and differs from pinned Miyoo/JDK semantics in owner-relevant ways:

- `RG35XXCore2D.charWidth/stringWidth/fontHeight/fontAscent/fontDescent` are synthetic heuristics;
- `RG35XXCore2D.glyph()` uppercases characters and uses a 5x7 ASCII bitmap with a box fallback;
- raw `drawString()` renders character-by-character rather than as one string-level layout operation;
- raw `drawString()` uses a different top-left/height anchor model rather than the pinned Miyoo baseline/ascent/descent model;
- the A5 raw override changes `Font.getBaselinePosition()` from pinned Miyoo `convertSize(size)` to `RG35XXCore2D.fontAscent(size)`;
- manual bold/underline raster behavior in the provisional raw path is not an authorized substitute for the exact pinned Miyoo/JDK font derivation/render path.

These are P2B platform-contract gaps, not game-specific failures.

## 3. Canonical/Miyoo ownership that must remain unchanged

The following stay in the existing Miyoo classes and must not migrate into a second RG35XX J2ME implementation:

```text
javax.microedition.lcdui.Font:
  FACE_* / SIZE_* / STYLE_* constants
  getFont(...)
  getFace/getSize/getPointSize/getStyle
  isBold/isItalic/isPlain/isUnderlined
  charsWidth control flow
  substringWidth control flow
  convertSize mapping SMALL/MEDIUM/LARGE -> 12/14/16
  getBaselinePosition semantics -> convertSize(size)

org.recompile.mobile.PlatformGraphics:
  current Font object ownership
  drawChar/drawChars/drawSubstring public semantics
  drawString anchor semantics
  current Graphics color/clip/translate ownership
  non-RG35XX AWT fallback
```

`Anbu.java` remains unchanged. Raw2D must not require the AWT `Anbu.getFont()` path to initialize, but P2B does not rewrite Anbu or replace Miyoo's non-RG35XX behavior.

## 4. Minimum RG35XX-owned backing contract

The RG35XX boundary only needs to replace the unavailable AWT/JDK **backend services** used by those existing Miyoo methods.

The minimum logical backend contract is:

```text
FONT CONTEXT
  exact configured font asset identity
  point size 12/14/16
  exact JDK8-compatible style derivation used by pinned Miyoo

METRICS
  charWidth(UTF-16 code unit)
  canDisplay(UTF-16 code unit) [module/exerciser support]
  stringWidth(whole String)
  height
  ascent
  descent

STRING RASTER/LAYOUT
  render/describe one whole String from a baseline origin
  simple strings -> exact JDK8u504 scaler/glyph placement path
  JDK non-simple strings -> exact JDK8u504 bundled LayoutEngine path
  preserve exact glyph positions and character-index/layout behavior required by drawString
```

The backend must not expose a "draw each char and sum" production shortcut for `stringWidth()` or `drawString()` because JDK string-level behavior is already proven.

The backend must not own MIDP anchors, clip, translate, logical color, Canvas semantics, or Font API semantics. Those stay in the existing Miyoo/Raw2D Java owner.

## 5. Smallest Java integration surface

The already-established A4/A5 Raw2D pattern is retained: `Font.java` and `PlatformGraphics.java` use RG35XX-only branches only when the AWT objects are unavailable on a Raw2D surface; the normal Miyoo/AWT path remains intact.

### `javax/microedition/lcdui/Font.java`

Allowed raw-only changes:

- keep the existing A4 AWT-constructor bypass under `rg35xx.raw2d`;
- replace provisional `RG35XXCore2D` synthetic metric calls with exact P2B backend metric calls;
- restore/retain pinned Miyoo `getBaselinePosition() == convertSize(size)` on Raw2D;
- do not change the public MIDP API, size conversion, face/style accessors, `charsWidth`, or `substringWidth` control flow.

### `org/recompile/mobile/PlatformGraphics.java`

Allowed raw-only changes:

- keep `setFont()` storing the canonical `Font` object while leaving AWT `fm` null for Raw2D;
- replace only the provisional raw `rg35xxDrawString()` implementation;
- use the current `Font` backend metrics to reproduce the pinned Miyoo anchor-to-baseline calculation;
- request one whole-string layout/raster result from the RG35XX backing;
- apply the result to the existing Raw2D target without changing non-text graphics, input, presenter, image, lifecycle, RMS, or audio behavior.

No production text path may depend on game name or game profile.

## 6. Smallest RG35XX adapter surface

`adapter/java/org/recompile/rg35xx/RG35XXCore2D.java` is already the accepted A5 headless image/font backing owner. Therefore the smallest Java ownership delta is to replace **only its provisional font/text helper section** with calls to an exact P2B backend; a second parallel Java text-semantics layer is not justified.

The P2B native/backend implementation, if later authorized, must be a **new font-owner artifact**. It must not be folded into or mutate protected non-owner natives (`librg35xx_input.so`, `librg35xx_video.so`, `libaudio.so`).

Conceptually permitted future native owner:

```text
librg35xx_font.so
```

Its implementation source must come from the already source-proven OpenJDK8u504 font backend path required for equivalence:

```text
JDK8u504 vendored FreeType 2.14.3
+
JDK8u504 bundled sun/font/layout LayoutEngine
+
minimum JNI/boundary glue only
```

This is an ownership statement, not authorization to build or commit the library yet.

## 7. Exact future file scope

### Runtime files allowed to change in a future P2B candidate

```text
adapter/java/org/recompile/rg35xx/RG35XXCore2D.java
scripts/stage-p2b-font-text.py                    [new owner-scoped staging unit]
adapter/native/rg35xx_font_jdk8.*                 [new owner-scoped native glue only]
scripts/build-p2b-font-text-candidate.sh           [new build unit]
```

The P2B staging unit may generate Raw2D-only deltas in exactly:

```text
src/javax/microedition/lcdui/Font.java
src/org/recompile/mobile/PlatformGraphics.java
```

The pinned upstream gitlink itself remains unchanged.

Exact OpenJDK8u504 FreeType/LayoutEngine source may be fetched/staged by pinned revision for the candidate build, or represented by another reproducible source-identity mechanism, but must not be silently substituted by system FreeType/HarfBuzz or the older Miyoo FreeType 2.11.1 engine.

### Test/audit scaffolding allowed

```text
tests/p2b/**
.github/workflows/p2b-*
docs/P2B-*
scripts/*p2b*diagnostic*
```

### Files/subsystems forbidden to change for P2B

```text
upstream/freej2me-miyoomini gitlink / pin
JamVM
glibj.zip
adapter/native/rg35xx_input.c
adapter/native/rg35xx_video_sdl1.c
adapter/native/rg35xx_audio_sdl1_mixer.c
RG35XX input/key dispatcher behavior
RG35XX presenter/scaler behavior
P1A non-text graphics semantics
P2A image decode semantics
RMS/filesystem semantics
MMAPI/audio semantics
MIDlet lifecycle/shutdown semantics
commercial-game-specific runtime logic
```

Protected final input/video/audio identities remain unchanged unless a separately approved owner phase proves otherwise.

## 8. Minimum required delta classification

With LayoutEngine R2 and the simple drawString source audit complete, the P2B semantic interface is now source-closed enough to state the minimum runtime delta:

```text
MINIMUM_REQUIRED_DELTA=
  replace provisional Raw2D synthetic font metrics/raster backing
  with source-matched JDK8u504 font backend semantics,
  while preserving the pinned Miyoo Font/PlatformGraphics API and anchor ownership
```

Status:

```text
P2B_MINIMUM_OWNER_SCOPED_RUNTIME_INTERFACE=PASS
P2B_FILES_ALLOWED_TO_CHANGE=PASS
P2B_MINIMUM_REQUIRED_DELTA=PASS
```

This still does **not** authorize implementation because the font provisioning/packaging contract remains unresolved.

## 9. Remaining hard blocker before a runtime candidate

The exact Miyoo runtime font identity is known, but packaging/redistribution remains `PARTIAL`.

Before `RUNTIME_PATCH` may change from `FORBIDDEN`, P2B must lock one generic font provisioning contract that:

1. preserves the exact font identity required by the proven differential, or explicitly reopens all affected metrics/raster/layout evidence for a different font;
2. does not publish font bytes without an authorized redistribution basis;
3. is compatible with a generic RG35XX installer/platform rather than a developer-only manual shell flow;
4. hash-gates the font identity used for the candidate;
5. preserves Miyoo-first behavior and does not alter games individually.

Next approved unit:

```text
P2B-FONT-PROVISIONING-PACKAGING-CONTRACT-AUDIT
```

## 10. Gates after provisioning is resolved

Only after the provisioning contract is `PASS` may a P2B runtime candidate be implemented. That future candidate must then pass, in order:

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
```

Only then may one P2B Font/Text physical module package be built for original RG35XX.

## 11. Current hard stop

```text
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=NOT_TESTED
P2B_FONT_PACKAGING_LICENSE_SCOPE=PARTIAL
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
NEW_TIER1_FIX=FORBIDDEN
```
