# RG35XX P2B FONT / TEXT — PRE-CHANGE LOCK v1

**Status:** LOCKED_FOR_ONE_OWNER_SCOPED_HOST_CANDIDATE  
**Phase:** P2B_FONT_TEXT  
**Audit branch:** `audit/p2b-font-text`  
**Production parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

> This record fills the mandatory Miyoo-first pre-change fields for exactly one host candidate. It does not authorize packaging, physical testing, stable promotion, game-specific code, JamVM/glibj changes, Core2D rewrites, or unrelated subsystem changes.

---

## 1. Mandatory pre-change checklist

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT

MIYOO_BUILD_BASE=aweigit/freej2me-miyoomini
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
MIYOO_SOURCE_PATH=
  upstream/freej2me-miyoomini/src/javax/microedition/lcdui/Font.java
  upstream/freej2me-miyoomini/src/org/recompile/mobile/PlatformGraphics.java
  upstream/freej2me-miyoomini/src/org/recompile/freej2me/Anbu.java
MIYOO_CURRENT_BEHAVIOR=
  Anbu supplies ./font.ttf to AWT;
  Font delegates width/metrics to AWT FontMetrics;
  PlatformGraphics delegates whole-string drawing to Graphics2D.drawString and owns MIDP anchor interpretation.

FREEJ2ME_REFERENCE=SEMANTIC_CROSS_CHECK_ONLY_NOT_BUILD_REPLACEMENT
JDK_OPENJDK_REFERENCE_IF_REQUIRED=
  adoptium/jdk8u jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2;
  exact FreetypeFontScaler/GlyphLayout/TextLayout/TextLine/SunLayoutEngine semantics;
  exact vendored FreeType and bundled LayoutEngine trees pinned by audit.

EXACT_RG35XX_GAP=
  original RG35XX protected JamVM/glibj raw/headless path cannot provide the desktop AWT/Java2D font backend used by pinned Miyoo;
  existing raw fallback is a synthetic 5x7/per-UTF16-unit substitute and is not parity.
HARDWARE_EVIDENCE=
  ARMv5/uClibC source build/link and QEMU/sysroot execution proven;
  AWT desktop backing is not the target runtime boundary;
  original-device module acceptance is still required after host candidate gates.
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
WHY_CHANGE_REQUIRED=REPLACE_ONLY_THE_MISSING_AWT_FONT_BACKING_WHILE_PRESERVING_Miyoo_JAVA_SEMANTICS

MINIMUM_DELTA=
  one thin RG35XX Java font/text backend adapter;
  one native JDK8-derived font backend;
  raw-only routing changes in pinned Font/PlatformGraphics staging overlays;
  reuse accepted RG35XXCore2D.blit for composition;
  no direct native framebuffer text rendering.

FILES_ALLOWED_TO_CHANGE=
  NEW adapter/java/org/recompile/rg35xx/RG35XXFontText.java
  NEW adapter/native/rg35xx_font_jdk8.cpp (or one equivalent single P2B native owner)
  NEW scripts/stage-p2b-font-text.py
  NEW scripts/build-p2b-font-text-candidate.sh
  NEW tests/p2b/candidate/* and host module exerciser/gate files
  NEW .github/workflows/p2b-font-text-candidate*.yml
  STAGED OUTPUT ONLY: javax/microedition/lcdui/Font.class
  STAGED OUTPUT ONLY: org/recompile/mobile/PlatformGraphics.class
  STAGED OUTPUT ONLY: org/recompile/rg35xx/RG35XXFontText.class

FILES_FORBIDDEN_TO_CHANGE=
  upstream/freej2me-miyoomini gitlink or source tree
  upstream/freej2me-miyoomini/src/org/recompile/freej2me/Anbu.java
  adapter/java/org/recompile/rg35xx/RG35XXCore2D.java
  adapter/java/org/recompile/rg35xx/RG35XXInput.java
  adapter/java/org/recompile/rg35xx/RG35XXVideo.java
  protected JamVM
  protected glibj.zip
  existing accepted native input/video/audio identities
  historical P1A/P2A stage/build scripts
  packaging/a8/*
  game-specific runtime files or conditions

PROTECTED_IDENTITIES=
  PRODUCTION_PARENT=77a36526e0f6d875c57c7e9a973e0c1a05573721
  MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
  JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
  GLIBJ_ZIP_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
  EXISTING_A8_NATIVE_PLATFORM_IDENTITIES=PROTECTED_BY_PARENT_DIFF_AND_HASH_GATES

HOST_GATE=
  rebuild from exact production parent;
  Java 6 compatibility;
  strict changed-file/entry-set gate;
  protected identity gate;
  exact font hash/size verification;
  native dependency gate;
  canonical 336 string-width and whole-raster differential;
  public metric and charWidth regression gates.
MODULE_GATE=
  one P2B host module exerciser covering Font public metrics/widths plus PlatformGraphics whole-string composition and anchors;
  accepted P1A/P2A parent regression protected.
PHYSICAL_GATE=
  exactly one original-RG35XX P2B module physical test only after all host/module gates PASS;
  DEVICE_PASS remains NO before that evidence.

GENERIC_PLATFORM_IMPACT=GENERIC_FONT_TEXT_BACKING_ONLY
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
SPECULATIVE_CODE=NO
```

All required fields are resolved for this bounded candidate.

---

## 2. Source/evidence basis for the minimum delta

Current audit closure:

```text
P2B_FONT_METRICS_ARM=EXACT_24_OF_24
P2B_CHARWIDTH_BMP=EXACT_196608_OF_196608
P2B_CANDISPLAY_BMP=EXACT_196608_OF_196608
P2B_STRING_WIDTH=EXACT_336_OF_336_FOR_ESTABLISHED_CORPUS
P2B_WHOLE_STRING_DRAW_RASTER=EXACT_336_OF_336_FOR_ESTABLISHED_CORPUS
P2B_RTL_SUBSET=EXACT_72_OF_72_FOR_WIDTH_AND_RASTER
P2B_NATIVE_LINK_SELF_CONTAINED_CXX=PASS
P2B_NATIVE_LINK_DLOPEN_SYSROOT=PASS
```

Newest evidence:

```text
WHOLE_RASTER_RUN=37105567710
WHOLE_RASTER_ARTIFACT=11268142443
WHOLE_RASTER_ARTIFACT_SHA256=7d1e8548e13715a6ba8b33977a9223cec87fd2e9686a14ae0c655d8a969c8c93

COMPLEX_WIDTH_REFERENCE_RUN=37105906820
COMPLEX_WIDTH_REFERENCE_ARTIFACT=11267883447
COMPLEX_WIDTH_REFERENCE_ARTIFACT_SHA256=c5b73c47fee04f9d20ec7f73eb46939905a23109520b69137dc00c2f442dae03

COMPLEX_WIDTH_ARM_RUN=37106105836
COMPLEX_WIDTH_ARM_ARTIFACT=11268220393
COMPLEX_WIDTH_ARM_ARTIFACT_SHA256=8c3e37de4f2555b71a1c423e4f002b45431ade9f50d39ebe8f941b91c6c35604
```

No evidence artifact contains the font, source-built object files, static libraries, or executables.

---

## 3. Candidate ownership contract

The candidate may implement this boundary only:

```text
PINNED Miyoo Font / PlatformGraphics API behavior
                  ↓
raw/headless RG35XX route only
                  ↓
RG35XXFontText Java adapter
                  ↓
exact JDK8-derived native font backend
  - exact vendored FreeType 2.14.3 policy
  - exact JDK char-to-glyph/control behavior
  - simple width path
  - exact bundled LayoutEngine for non-simple text
  - whole-string monochrome raster/mask
                  ↓
existing accepted RG35XXCore2D.blit composition
```

Ownership must terminate at the current graphics boundary. The native backend must not own MIDP anchors, clip state, translate state, color state, source-over composition, lifecycle, input, audio, presenter, RMS, or game behavior.

---

## 4. Font provisioning lock

The candidate must not embed or redistribute the audited MiSans font.

Allowed host/runtime behavior for the first candidate:

```text
1. resolve explicit externally supplied path (for example rg35xx.font.path);
2. optionally accept user-provided ./font.ttf for Miyoo-compatible layout;
3. verify SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10;
4. verify size=8092724;
5. fail closed with a diagnostic on absence or mismatch;
6. never silently substitute system or synthetic fonts while claiming parity.
```

CI may materialize the exact font temporarily for differential testing and must remove it before evidence upload.

---

## 5. First-candidate restrictions

```text
NO_GAME_NAME_DETECTION
NO_GAME_SPECIFIC_CODE
NO_TIMING_CHANGE
NO_INPUT_CHANGE
NO_AUDIO_CHANGE
NO_VIDEO_PRESENTER_CHANGE
NO_CORE2D_IMAGE_SHAPE_REWRITE
NO_JAMVM_CHANGE
NO_GLIBJ_CHANGE
NO_UPSTREAM_GITLINK_CHANGE
NO_FONT_BYTES_IN_REPOSITORY_OR_ARTIFACT
NO_PACKAGE_YET
NO_PHYSICAL_TEST_YET
NO_STABLE_CLAIM
```

If implementation requires any forbidden file or a second subsystem, stop the candidate and return to diagnostic/design audit.

---

## 6. Promotion gates for this candidate

The host candidate is rejected unless every item passes:

```text
MIYOO_BASE_PRESERVED=YES
OWNER_SCOPE_VERIFIED=YES
UNRELATED_CLASS_DIFF=NONE
PROTECTED_HASHES=PASS
JAVA6_GATE=PASS
NATIVE_SOURCE_IDENTITIES=PASS
NATIVE_DYNAMIC_DEPENDENCY_GATE=PASS
FONT_IDENTITY_GATE=PASS
FONT_BYTE_LEAK=NO
FONT_PUBLIC_METRIC_REGRESSION=PASS
CHARWIDTH_REGRESSION=PASS
STRING_WIDTH_336=PASS
WHOLE_RASTER_336=PASS
RTL_SUBSET_72=PASS
P1A_P2A_PARENT_REGRESSION=PASS
P2B_HOST_MODULE_EXERCISER=PASS
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
```

Only then may a separate package/physical-test unit be prepared.

---

## 7. Authorization boundary

```text
P2B_OWNER_SCOPED_HOST_CANDIDATE=AUTHORIZED
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=FORBIDDEN_UNTIL_HOST_MODULE_GATE_PASS
DEVICE_PASS=NO
STABLE=NO
```

This authorization is narrow: it permits implementation and host validation of the minimum boundary above, based on the exact accepted parent. It is not a general permission to refactor font, graphics, runtime, or packaging code.
