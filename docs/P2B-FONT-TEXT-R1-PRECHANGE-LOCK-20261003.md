# RG35XX P2B Font/Text Module Candidate R1 — Pre-change Lock

**Status:** MODULE_CANDIDATE / NOT_TESTED  
**Date:** 2026-10-03  
**Branch:** `module/p2b-font-text-candidate-r1`  
**Exact parent:** `5a8bfdf12d42e49d5d4aa8260601799c904e6441` (`physical-test/p2a-image-decode-accepted-20261003`)  
**Pinned Miyoo/Aweigit:** `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

This branch is intentionally parented from the exact accepted P2A physical lineage. It is not parented from A9, a commercial-game branch, or the audit branch.

## Evidence inputs

Audit evidence remains on `audit/p2b-font-text-post-layout-r2` through commit:

```text
8d3dc24f847380c699e18b6efd4bd9183884ac2c
```

That audit lineage establishes:

```text
P2B_FONT_ASSET_IDENTITY=PASS
P2B_JDK8_SEMANTIC_REFERENCE=PASS
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=PASS
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CANDISPLAY=PASS
P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_SIMPLE_DRAWSTRING_SOURCE_PATH=PASS
P2B_SIMPLE_STRING_DRAW_RASTER=PASS_FOR_EXISTING_144_CASE_CORPUS
P2B_COMPLEX_LAYOUT_EXISTING_CORPUS=PASS_192_OF_192
P2B_MINIMUM_OWNER_SCOPED_RUNTIME_INTERFACE=PASS
P2B_FILES_ALLOWED_TO_CHANGE=PASS
P2B_MINIMUM_REQUIRED_DELTA=PASS
P2B_FONT_PROVISIONING_PACKAGING_CONTRACT=PASS
```

## Required pre-change checklist

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT

MIYOO_BUILD_BASE=aweigit/freej2me-miyoomini
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
MIYOO_SOURCE_PATH=src/javax/microedition/lcdui/Font.java + src/org/recompile/mobile/PlatformGraphics.java + src/org/recompile/freej2me/Anbu.java
MIYOO_CURRENT_BEHAVIOR=AWT Font/FontMetrics + Graphics2D.drawString over exact ./font.ttf

FREEJ2ME_REFERENCE=SEMANTIC_REFERENCE_ONLY
JDK_OPENJDK_REFERENCE_IF_REQUIRED=OpenJDK8u504 FreetypeFontScaler + bundled sun/font/layout LayoutEngine

EXACT_RG35XX_GAP=Raw2D deliberately has gc/fm/awtFont unavailable; current A5 fallback is synthetic 5x7/heuristic and not pinned-Miyoo/JDK equivalent
HARDWARE_EVIDENCE=original RG35XX requires headless Raw2D; P1A and P2A module physical acceptance preserved
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
WHY_CHANGE_REQUIRED=replace provisional font/text backing while keeping Miyoo Font/PlatformGraphics semantics

MINIMUM_DELTA=font/text backing only
FILES_ALLOWED_TO_CHANGE=RG35XXCore2D font section + new P2B font native owner + P2B staging/build/tests; generated Raw2D-only deltas in Font.java and PlatformGraphics.java
FILES_FORBIDDEN_TO_CHANGE=JamVM/glibj/input/video/audio/P1A non-text graphics/P2A image/RMS/MMAPI/lifecycle/upstream pin/game-specific runtime

PROTECTED_IDENTITIES=preserve all non-owner golden identities
HOST_GATE=exact JDK8 differential for metrics/simple raster/complex layout + P1A/P2A host regressions
MODULE_GATE=one P2B Font/Text module exerciser
PHYSICAL_GATE=one original-RG35XX P2B module test only after host/module gates PASS

GENERIC_PLATFORM_IMPACT=replace provisional platform font/text backing generically; no game conditions
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
SPECULATIVE_CODE=NO
```

## Font provisioning lock

```text
FONT_ENTRY=JAVA/font.ttf
FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724
FONT_EMBEDDED_APP_ASSET=YES
FONT_MODIFICATION=NO
FONT_STANDALONE_DISTRIBUTION=REJECTED
MISANS_NOTICE_REQUIRED=YES
MISANS_LICENSE_COPY_REQUIRED=YES
```

## Candidate gate

This branch now permits owner-scoped implementation work, but currently contains no P2B runtime delta.

```text
P2B_RUNTIME_IMPLEMENTATION=NOT_TESTED
P2B_HOST_MODULE_GATE=NOT_TESTED
P2B_DEVICE_PACKAGE=FORBIDDEN_UNTIL_HOST_MODULE_GATE_PASS
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
NEW_TIER1_FIX=FORBIDDEN
```
