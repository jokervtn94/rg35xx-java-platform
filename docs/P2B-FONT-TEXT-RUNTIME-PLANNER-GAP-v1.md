# RG35XX P2B FONT / TEXT — RUNTIME LAYOUT PLANNER GAP v1

**Status:** LOCKED_DIAGNOSTIC_GAP  
**Phase:** P2B_FONT_TEXT  
**Pinned Miyoo:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**Production parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`

> This audit corrects the candidate-eligibility interpretation in `P2B-FONT-TEXT-PRECHANGE-LOCK-v1.md`. The backend scaler/layout/raster results remain valid, but they do not yet prove a generic production runtime can derive the JDK8 TextLayout plan for arbitrary input strings. Therefore the v1 host-runtime authorization is suspended until the planner gate below is closed.

---

## 1. Exact discovered gap

The final 336-case whole-string raster and 192-case complex-width ARM probes consume planner metadata emitted by the exact JDK8 reference:

```text
LAYOUT_FLAGS
SCRIPT_RUNS = start:limit:script:engineFlags
BIDI_DIRECTION / RTL
```

The reference obtains that information from the JDK8 TextLayout/TextLine path:

```text
TextLayout.fastInit
  -> TextLine.fastCreateTextLine
      -> java.text.Bidi / sun.text.bidi.BidiBase
      -> BidiUtils visual/logical mapping
      -> TextLabelFactory
      -> sun.font.ScriptRun
      -> GlyphLayout / SunLayoutEngine
```

The ARM renderer/layout probes then consume the emitted plan. They do **not** derive the complete plan from arbitrary runtime strings.

Therefore:

```text
JDK8_LAYOUTENGINE_AFTER_SEGMENTATION=PROVEN
JDK8_WHOLE_RASTER_FOR_REFERENCE_PLANS=PROVEN
GENERIC_RUNTIME_LAYOUT_PLAN_DERIVATION=NOT_YET_PROVEN
```

No corpus-specific lookup table may be used to close this gap.

---

## 2. Why this blocks a production runtime patch

A production `Font.stringWidth` / `PlatformGraphics.drawString` backend must accept arbitrary application strings. For non-simple text it must independently derive, with canonical semantics:

```text
1. whether bidi analysis is required;
2. paragraph/base direction;
3. per-UTF16-unit bidi levels;
4. visual chunks / component direction;
5. exact ScriptRun segmentation and script code;
6. combining-mark engine flag (0x4);
7. LayoutEngine RTL and line-direction flags;
8. visual component order when multiple components exist.
```

The current established 14-string corpus happens to produce one TextLayout component per case. That does not prove mixed-script or mixed-direction component construction.

A runtime implementation that hardcodes the 14 strings, assumes one component, assumes one script run, classifies direction heuristically, or delegates to an unverified GNU Classpath `java.text.Bidi` would be speculative and is forbidden.

---

## 3. Source-grounded exact route under audit

OpenJDK8u504 provides portable Java source for the missing planning semantics:

```text
jdk/src/share/classes/sun/text/bidi/BidiBase.java
jdk/src/share/classes/sun/text/bidi/BidiLine.java
jdk/src/share/classes/sun/text/bidi/BidiRun.java
jdk/src/share/classes/sun/text/normalizer/UBiDiProps.java
jdk/src/share/classes/sun/text/normalizer/UTF16.java
jdk/src/share/classes/sun/text/normalizer/ICUData.java
jdk/src/share/classes/sun/text/normalizer/ICUBinary.java
jdk/src/share/classes/sun/text/normalizer/Trie.java
jdk/src/share/classes/sun/text/normalizer/CharTrie.java
jdk/src/share/classes/sun/text/resources/ubidi.icu
jdk/src/share/classes/sun/font/Script.java
jdk/src/share/classes/sun/font/ScriptRun.java
jdk/src/share/classes/sun/font/ScriptRunData.java
```

`ScriptRun` and its data tables are self-contained Java-side source semantics. `BidiBase` obtains bidi properties from the pinned JDK `ubidi.icu` data through `UBiDiProps`.

This source lineage is eligible for diagnostic reconstruction because pinned Miyoo delegates this behavior to JDK8/AWT and original RG35XX cannot provide that desktop backend. It is not permission for a generic font/text rewrite.

---

## 4. Required planner gates

Before any P2B runtime candidate branch is created, diagnostics must prove:

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
P2B_JDK8_PLANNER_EXISTING_336_REGRESSION=PASS
```

The planner corpus must extend beyond the existing 14 strings and explicitly include mixed LTR/RTL, multiple scripts, paired punctuation, combining marks, ZWJ/ZWNJ, directional controls, numbers inside RTL text, and supplementary characters.

Only exact field-by-field equality against JDK8 may promote the planner.

---

## 5. Current authorization correction

```text
P2B_BACKEND_SCALER_LAYOUT_RASTER_EVIDENCE=RETAINED
P2B_STRING_WIDTH_336=PASS_FOR_REFERENCE_PLAN_CORPUS
P2B_WHOLE_RASTER_336=PASS_FOR_REFERENCE_PLAN_CORPUS

P2B_GENERIC_RUNTIME_LAYOUT_PLANNER=OPEN
P2B_PRECHANGE_V1_RUNTIME_AUTHORIZATION=SUSPENDED
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_RUNTIME_CANDIDATE_BRANCH=DO_NOT_CREATE
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=FORBIDDEN
DEVICE_PASS=NO
STABLE=NO
```

This is a diagnostic correction, not a regression of the exact backend evidence.

---

## 6. Next approved unit

```text
CURRENT_UNIT=P2B_JDK8_RUNTIME_LAYOUT_PLANNER_DIAGNOSTIC
ACTION=
  source-pin exact JDK8 planner classes/data;
  establish Java6/self-contained portability;
  build an independent source-derived planner;
  compare its emitted plan against exact JDK8 TextLayout on a mixed-script/mixed-bidi corpus;
  keep runtime untouched.
```

If exact planner parity cannot be established without changing protected JamVM/glibj, stop and return to design review. Protected runtime replacement is not authorized by this unit.
