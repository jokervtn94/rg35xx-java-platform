# RG35XX P2B FONT / TEXT — PRE-CHANGE LOCK v2

**Status:** LOCKED_FOR_ONE_OWNER_SCOPED_HOST_CANDIDATE  
**Phase:** P2B_FONT_TEXT  
**Audit branch:** `audit/p2b-font-text`  
**Production parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**Evidence closure:** `P2B-FONT-TEXT-EVIDENCE-SYNTHESIS-v4.md`

> This record supersedes `P2B-FONT-TEXT-PRECHANGE-LOCK-v1.md` for current candidate authorization. The v1 record remains historical evidence. Its authorization was correctly suspended by `P2B-FONT-TEXT-RUNTIME-PLANNER-GAP-v1.md`; the exact source-derived planner diagnostics in synthesis v4 close that suspension reason. This v2 lock authorizes exactly one host candidate from the accepted production parent. It does not authorize a device package, physical test, stable promotion, game-specific code, protected JamVM/glibj modification, font redistribution, or unrelated subsystem change.

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
  exact FreetypeFontScaler/GlyphLayout/TextLayout/TextLine/Bidi/ScriptRun/SunLayoutEngine semantics;
  exact vendored FreeType, bundled LayoutEngine, Bidi data and UnicodeData identities pinned by audit.

EXACT_RG35XX_GAP=
  original RG35XX protected JamVM/glibj raw/headless path cannot provide the desktop AWT/Java2D font backend used by pinned Miyoo;
  existing raw fallback is a synthetic 5x7/per-UTF16-unit substitute and is not parity;
  protected GNU Classpath character category data is not exact JDK8 for the GlyphLayout Mn/Me/Mc predicate.

HARDWARE_EVIDENCE=
  ARMv5/uClibC source build/link and QEMU/sysroot execution proven;
  exact JDK8 vendored FreeType and bundled LayoutEngine semantics proven on ARM;
  original-device module acceptance is still required after host candidate gates.

FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
WHY_CHANGE_REQUIRED=REPLACE_ONLY_THE_MISSING_AWT_FONT_BACKING_WHILE_PRESERVING_PINNED_MIYOO_JAVA_SEMANTICS

MINIMUM_DELTA=
  one thin RG35XX Java font/text backend adapter;
  one native JDK8-derived font backend/JNI owner;
  one source-derived Java6 JDK8 layout planner materialized from exact pins at candidate build/stage time;
  raw-only routing changes in pinned Font/PlatformGraphics staging overlays;
  reuse accepted RG35XXCore2D.blit for composition;
  no direct native framebuffer text rendering;
  no protected JamVM/glibj replacement or patch.
```

---

## 2. Planner closure required by the suspended v1 lock — now satisfied

The following gates are now closed by exact differential evidence:

```text
P2B_JDK8_PLANNER_SOURCE_PROVENANCE=PASS
P2B_JDK8_PLANNER_JAVA6_COMPILE=PASS
P2B_JDK8_PLANNER_NO_GLIBJ_PATCH=PASS
P2B_JDK8_PLANNER_SCRIPT_RUN_DIFFERENTIAL=PASS
P2B_JDK8_PLANNER_BIDI_LEVEL_DIFFERENTIAL=PASS
P2B_JDK8_PLANNER_COMPONENT_PLAN_DIFFERENTIAL=PASS
P2B_JDK8_PLANNER_MIXED_SCRIPT_CASES=PASS
P2B_JDK8_PLANNER_MIXED_BIDI_CASES=PASS
P2B_JDK8_PLANNER_SURROGATE_CONTROL_CASES=PASS
```

Final corrected full planner evidence:

```text
RUN=37111651688
HEAD=ff450a96473c3fcd48aa8a86b9ab29e0a4089bfe
ARTIFACT=11269648705
ARTIFACT_SHA256=6c48b4f7fd1aa159764a5d9c35093df12b866fd3efc6323fba028d468c9366f6
CLASS_MAJOR=50
CASES=24
COMPONENTS=52
SCRIPT_RUNS=65
LINE_MISMATCH=0
LEVELS_MISMATCH=0
L2V_MISMATCH=0
ORDER_MISMATCH=0
COMPONENTS_MISMATCH=0
TOTAL_MISMATCH=0
BYTE_LEAK=NO
```

The planner uses source-derived JDK8 Bidi + `ubidi.icu`, ScriptRun, BidiUtils, JDK8 UTF16 closure and a compact JDK8 Mn/Me/Mc classifier. It must not delegate planner category semantics to protected glibj.

---

## 3. Backend evidence retained

The candidate continues to depend on the exact backend evidence already closed before the planner work:

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

Native source identity remains:

```text
OPENJDK8=jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2
FREETYPE_INCLUDE_TREE=43f2e4398cfd927acac29ce3515e23a195349eb7
FREETYPE_SRC_TREE=8690dd39ef9f4da5bae000d757fe6dfa2d2102a6
LAYOUT_TREE=bc6641fecdfb59f3146bb1591e090761a24b4061
```

---

## 4. Exact candidate ownership contract

The candidate may implement only this path:

```text
PINNED Miyoo Font / PlatformGraphics public behavior
                  ↓
raw/headless RG35XX route only
                  ↓
RG35XXFontText Java adapter
                  ↓
source-derived Java6 JDK8 planner
  - exact Bidi + ubidi.icu
  - exact ScriptRun
  - exact BidiUtils component ordering
  - exact JDK8 UTF16 supplementary handling
  - exact JDK8 Mn/Me/Mc EngineRecord predicate
                  ↓
exact JDK8-derived native font backend
  - exact vendored FreeType 2.14.3 policy
  - exact char-to-glyph/control behavior
  - simple width path
  - exact bundled LayoutEngine for non-simple runs
  - whole-string monochrome raster/mask
                  ↓
existing accepted RG35XXCore2D.blit composition
```

Ownership must terminate at the current graphics boundary. The candidate must not own MIDP anchor constants, clip state, translate state, color state, source-over composition, lifecycle, input, audio, presenter, RMS, or game behavior.

---

## 5. Production delta allowlist

The host candidate must be created from the exact production parent, not from the audit branch:

```text
CANDIDATE_PARENT=77a36526e0f6d875c57c7e9a973e0c1a05573721
AUDIT_BRANCH_AS_PARENT=FORBIDDEN
```

Maximum repository delta allowed for the first candidate:

```text
NEW:
  adapter/java/org/recompile/rg35xx/RG35XXFontText.java
  adapter/native/rg35xx_font_jdk8.cpp
      OR one equivalent single P2B JNI/native bridge owner
  scripts/stage-p2b-font-text.py
  scripts/build-p2b-font-text-candidate.sh
  tests/p2b/candidate/*
  one P2B host module exerciser/gate
  .github/workflows/p2b-font-text-candidate*.yml
```

The exact JDK8 planner Java sources/data and exact FreeType/LayoutEngine sources must be materialized or generated at build/stage time from pinned source identities. They must not replace the pinned Miyoo submodule or protected Java runtime.

Generated/staged Java planner classes are allowed only under a dedicated P2B namespace, for example:

```text
org/recompile/rg35xx/p2b/jdk8/text/*
org/recompile/rg35xx/p2b/jdk8/bidi/*
org/recompile/rg35xx/p2b/jdk8/normalizer/*
org/recompile/rg35xx/p2b/jdk8/script/*
org/recompile/rg35xx/p2b/jdk8/font/*
org/recompile/rg35xx/p2b/jdk8/mark/*
```

Those classes are P2B backing implementation only. They must not shadow `java.*`, `javax.microedition.*`, `sun.*`, or protected glibj classes at runtime.

Staged canonical output allowed to differ:

```text
javax/microedition/lcdui/Font.class
org/recompile/mobile/PlatformGraphics.class
org/recompile/rg35xx/RG35XXFontText.class
org/recompile/rg35xx/p2b/jdk8/**.class
```

No other canonical JAR entry may drift without returning to audit/design review.

---

## 6. Files and identities forbidden to change

```text
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
```

Protected identities:

```text
PRODUCTION_PARENT=77a36526e0f6d875c57c7e9a973e0c1a05573721
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_ZIP_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXISTING_A8_NATIVE_PLATFORM_IDENTITIES=PROTECTED_BY_PARENT_DIFF_AND_HASH_GATES
```

The old synthetic font helpers may remain present but dead/unreferenced inside accepted `RG35XXCore2D` during the first candidate. P2B does not authorize a Core2D cleanup/refactor.

---

## 7. Native build/link lock

The candidate native library must be built from exact audited source identity:

```text
TOOLCHAIN=docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e
ARCH=armv5te
TUNE=arm926ej-s
FLOAT_ABI=soft
PIC=yes
OPENJDK8=jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2
LAYOUT_DEFINES=LE_STANDALONE,HEADLESS
LAYOUT_SUN_JNI_WRAPPER=EXCLUDED
LIBSTDCXX=STATIC
LIBGCC=STATIC
```

Dynamic dependency gate must reject `libstdc++.so` and `libgcc_s.so`. The proven strategy permits only the target C runtime/loader dependencies:

```text
libc.so.0
ld-uClibc.so.1
```

The native font backend must not draw directly to the framebuffer.

---

## 8. Font provisioning lock

The candidate must not embed or redistribute the audited MiSans font.

First-candidate behavior:

```text
1. resolve an explicit externally supplied path such as rg35xx.font.path;
2. optionally accept user-provided ./font.ttf for Miyoo-compatible layout;
3. verify SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10;
4. verify size=8092724;
5. fail closed with a diagnostic on absence/mismatch;
6. never silently substitute system, glibj, synthetic or alternate fonts while claiming parity.
```

CI may materialize the exact font temporarily for differential tests and must delete it before evidence upload.

---

## 9. Candidate host and module gates

The candidate is rejected unless all of the following pass:

```text
MIYOO_BASE_PRESERVED=YES
OWNER_SCOPE_VERIFIED=YES
UNRELATED_CLASS_DIFF=NONE
PROTECTED_HASHES=PASS
JAVA6_GATE=PASS
PLANNER_SOURCE_IDENTITIES=PASS
PLANNER_CLASS_MAJOR_50=PASS
PLANNER_EXPANDED_COMPONENT_PLAN_DIFFERENTIAL=PASS
NATIVE_SOURCE_IDENTITIES=PASS
NATIVE_DYNAMIC_DEPENDENCY_GATE=PASS
FONT_IDENTITY_GATE=PASS
FONT_BYTE_LEAK=NO
FONT_PUBLIC_METRIC_REGRESSION=PASS
CHARWIDTH_REGRESSION=PASS
CANDISPLAY_REGRESSION=PASS
STRING_WIDTH_336=PASS
WHOLE_RASTER_336=PASS
RTL_SUBSET_72=PASS
P1A_P2A_PARENT_REGRESSION=PASS
P2B_HOST_MODULE_EXERCISER=PASS
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
```

The host module exerciser must cover the P2B module as one integrated unit: public Font metrics/widths plus `PlatformGraphics.drawString` whole-string layout/composition/anchors, including simple, complex, RTL and mixed-direction planner cases. Do not create per-method device packages.

---

## 10. First-candidate restrictions

```text
NO_GAME_NAME_DETECTION
NO_GAME_SPECIFIC_CODE
NO_CORPUS_LOOKUP_TABLE
NO_HEURISTIC_BIDI
NO_GLIBJ_CHARACTER_CATEGORY_DEPENDENCY_FOR_JDK8_ENGINEFLAG
NO_TIMING_CHANGE
NO_INPUT_CHANGE
NO_AUDIO_CHANGE
NO_VIDEO_PRESENTER_CHANGE
NO_CORE2D_IMAGE_SHAPE_REWRITE
NO_JAMVM_CHANGE
NO_GLIBJ_CHANGE
NO_UPSTREAM_GITLINK_CHANGE
NO_FONT_BYTES_IN_REPOSITORY_OR ARTIFACT
NO_DEVICE_PACKAGE_YET
NO_PHYSICAL_TEST_YET
NO_STABLE_CLAIM
```

If implementation requires any forbidden file, protected runtime change, game-specific branch, or second subsystem, stop the candidate and return to diagnostic/design audit.

---

## 11. Promotion sequence

```text
CREATE ONE HOST CANDIDATE FROM EXACT P2A PRODUCTION PARENT
        ↓
OWNER / ENTRY-SET / PROTECTED-HASH / JAVA6 / SOURCE-IDENTITY GATES
        ↓
NATIVE BUILD/LINK/DEPENDENCY GATES
        ↓
BACKEND 336 + PLANNER EXPANDED-CORPUS REGRESSIONS
        ↓
P2B HOST MODULE EXERCISER
        ↓ PASS REQUIRED
PACKAGE / FONT-PROVISIONING REVIEW
        ↓
ONE ORIGINAL-RG35XX P2B MODULE PHYSICAL TEST
        ↓ PASS REQUIRED
PROMOTION REVIEW
```

No commercial game is a gate or owner for this phase.

---

## 12. Authorization boundary

```text
P2B_PRECHANGE_V1_SUSPENSION_REASON=CLOSED_BY_SYNTHESIS_V4
P2B_PRECHANGE_V2=LOCKED
P2B_OWNER_SCOPED_HOST_CANDIDATE=AUTHORIZED
P2B_RUNTIME_CANDIDATE_BRANCH=MAY_CREATE_FROM_EXACT_PRODUCTION_PARENT_ONLY

P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=FORBIDDEN_UNTIL_HOST_MODULE_GATE_PASS
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

This authorization permits only implementation and host validation of the minimum owner-scoped P2B font/text backing above. It is not permission to refactor font, graphics, runtime, packaging, or another subsystem.
