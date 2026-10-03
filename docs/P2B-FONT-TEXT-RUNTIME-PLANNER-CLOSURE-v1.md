# RG35XX P2B FONT / TEXT — RUNTIME LAYOUT PLANNER CLOSURE v1

**Status:** PLANNER_LAYER_CLOSED / RUNTIME_CANDIDATE_STILL_SUSPENDED  
**Phase:** P2B_FONT_TEXT  
**Audit branch:** `audit/p2b-font-text`  
**Production parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Pinned Miyoo/Aweigit:** `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**Exact JDK reference:** `jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2`

> This document closes only the generic Java-side layout-planner diagnostic gap identified by `P2B-FONT-TEXT-RUNTIME-PLANNER-GAP-v1.md`. It does not authorize a runtime patch, candidate branch, package, physical test, or stable promotion. The previously suspended host-runtime authorization remains suspended until an integrated local-planner -> exact ARM backend differential and protected JamVM/glibj execution-compatibility gate both pass.

---

## 1. Gap status

The v1 gap required an arbitrary runtime string to derive, without corpus lookup tables or unverified GNU Classpath semantics:

```text
bidi requirement and base direction
per-UTF16-unit bidi levels
logical/visual mapping
visual component boundaries and component order
component RTL and line-RTL flags
ScriptRun segmentation and script codes
combining-mark EngineRecord flag 0x4
supplementary UTF-16 handling
```

Those planner semantics are now source-derived from exact JDK8u504 and independently differential-tested.

```text
P2B_GENERIC_RUNTIME_LAYOUT_PLANNER=PASS_FOR_EXPANDED_PLANNER_CORPUS
P2B_PLANNER_LAYER_GAP=CLOSED
```

This does not yet prove the planner and native backend operate correctly when composed as one RG35XX runtime path.

---

## 2. ScriptRun gate

Exact source:

```text
sun/font/Script.java
sun/font/ScriptRunData.java
sun/font/ScriptRun.java
```

Adaptation is package relocation only.

```text
P2B_PLANNER_SCRIPTRUN_CASES=8260
P2B_PLANNER_SCRIPTRUN_FULL_CASES=4747
P2B_PLANNER_SCRIPTRUN_SLICE_CASES=3513
P2B_PLANNER_SCRIPTRUN_MISMATCH_COUNT=0
P2B_PLANNER_SCRIPTRUN_GENERIC_DIFFERENTIAL=PASS
P2B_PLANNER_SCRIPTRUN_JAVA6_GATE=PASS
```

---

## 3. Bidi / direction / UTF16 gate

The JDK8 Bidi closure was reconstructed from pinned source plus `ubidi.icu`, with only package relocation, Java-6 syntax backport preserving the same catch body, exclusion of an unreachable `UCharacterProperty` friend method, and source-extracted minimal `UCharacter` / UTF16 dependencies.

Evidence:

```text
RUN=37109167277
HEAD=364778e14a71f6842a364a60aad96dcfbbd65f77
ARTIFACT=11269112192
ARTIFACT_SHA256=f4f600fa14178b7e214f17aede92fc1d1f9fa6406c739ce24b996512da8816af
```

Results:

```text
P2B_PLANNER_BIDI_CLASS_COUNT=28
P2B_PLANNER_BIDI_CLASS_MAJORS=50
P2B_PLANNER_BIDI_DIRECTION_CODEPOINTS=1114112
P2B_PLANNER_BIDI_DIRECTION_MISMATCH_COUNT=0
P2B_PLANNER_BIDI_UTF16_CASES=1048587
P2B_PLANNER_BIDI_UTF16_MISMATCH_COUNT=0
P2B_PLANNER_BIDI_CASES=16500
P2B_PLANNER_BIDI_CHAR_LEVEL_COMPARISONS=358320
P2B_PLANNER_BIDI_RUN_COMPARISONS=90298
P2B_PLANNER_BIDI_REQUIRES_CASES=8245
P2B_PLANNER_BIDI_REORDER_CASES=64
P2B_PLANNER_BIDI_REORDER_MISMATCH_COUNT=0
P2B_PLANNER_BIDI_MISMATCH_COUNT=0
P2B_PLANNER_BIDI_GENERIC_DIFFERENTIAL=PASS
```

No protected JamVM/glibj change occurred.

---

## 4. JDK8 mark-classifier closure

`GlyphLayout.EngineRecord` sets engine flag `0x4` when a run contains an Mn, Mc, or Me code point. Protected GNU Classpath 0.99 cannot be used as the authority for this predicate because its generated Unicode 4.0 data differs from the JDK8 data.

The audit therefore derives a compact JDK8-only Mn/Mc/Me range classifier from pinned JDK8 `UnicodeData.txt` and exhaustively compares it against JDK8 `Character.getType`.

Evidence:

```text
RUN=37111149098
HEAD=f0278855b96f171de07a527528eeb36bad4e4d91
ARTIFACT=11269014042
ARTIFACT_SHA256=4a6a4f756b2445483000b03e1981f93e7269f580140ee19fe53195085e33990a
```

Results:

```text
P2B_PLANNER_MARK_CODEPOINTS_TESTED=1114112
P2B_PLANNER_MARK_CODEPOINT_COUNT=1645
P2B_PLANNER_MARK_RANGE_COUNT=204
P2B_PLANNER_MARK_MISMATCH_COUNT=0
P2B_PLANNER_MARK_DIFFERENTIAL=PASS
P2B_PROTECTED_GLIBJ_MARK_DIFF_COUNT=706
P2B_PROTECTED_GLIBJ_MARK_CLASSIFIER=NOT_EXACT_JDK8
P2B_JDK8_PLANNER_NO_GLIBJ_PATCH=PASS
```

The planner therefore does not modify or silently trust protected glibj for this semantic.

---

## 5. Expanded planner reference coverage

Exact JDK8 TextLayout reference coverage:

```text
P2B_JDK8_EXPANDED_PLAN_CASES=24
P2B_JDK8_EXPANDED_PLAN_TOTAL_COMPONENTS=52
P2B_JDK8_EXPANDED_PLAN_MULTI_COMPONENT_CASES=14
P2B_JDK8_EXPANDED_PLAN_MULTI_SCRIPT_CASES=18
P2B_JDK8_EXPANDED_PLAN_MIXED_BIDI_CASES=14
P2B_JDK8_EXPANDED_PLAN_LINE_RTL_CASES=5
P2B_JDK8_EXPANDED_PLAN_RTL_COMPONENTS=19
P2B_JDK8_EXPANDED_PLAN_VISUAL_REORDERED_CASES=8
P2B_JDK8_EXPANDED_PLAN_SCRIPT_RUNS=65
P2B_JDK8_EXPANDED_PLAN_COMBINING_SCRIPT_RUNS=7
P2B_JDK8_EXPANDED_PLAN_CORPUS_COVERAGE=PASS
```

The corpus includes mixed LTR/RTL, multiple scripts, paired punctuation, combining marks, ZWJ/ZWNJ, directional controls, numbers in RTL contexts, and supplementary characters. It is a bounded planner corpus, not an exhaustive Unicode layout claim.

---

## 6. Full local planner differential

The source-derived local planner independently rebuilds the exact JDK8 fast-path plan from UTF-16 input:

```text
Bidi.requiresBidi
  -> source-derived JDK8 Bidi levels/maps
  -> TextLine contiguous-level component boundaries
  -> TextLabelFactory component flags 0x1 / 0x8
  -> BidiUtils component visual order
  -> exact ScriptRun
  -> source-derived JDK8 Mn/Mc/Me classifier for EngineRecord flag 0x4
  -> source-derived JDK8 UTF16 supplementary assembly
```

The tightened rerun removes any hidden host `java.lang.Character` dependency for surrogate assembly.

Evidence:

```text
RUN=37111651688
HEAD=ff450a96473c3fcd48aa8a86b9ab29e0a4089bfe
ARTIFACT=11269648705
ARTIFACT_SHA256=6c48b4f7fd1aa159764a5d9c35093df12b866fd3efc6323fba028d468c9366f6
```

Results:

```text
P2B_LOCAL_PLAN_CLASS_COUNT=34
P2B_LOCAL_PLAN_CLASS_MAJORS=50
P2B_LOCAL_PLAN_JAVA6_GATE=PASS
P2B_LOCAL_COMPONENT_PLAN_CASES=24
P2B_LOCAL_COMPONENT_PLAN_TOTAL_COMPONENTS=52
P2B_LOCAL_COMPONENT_PLAN_SCRIPT_RUNS=65
P2B_LOCAL_COMPONENT_PLAN_LINE_MISMATCH_COUNT=0
P2B_LOCAL_COMPONENT_PLAN_LEVELS_MISMATCH_COUNT=0
P2B_LOCAL_COMPONENT_PLAN_L2V_MISMATCH_COUNT=0
P2B_LOCAL_COMPONENT_PLAN_ORDER_MISMATCH_COUNT=0
P2B_LOCAL_COMPONENT_PLAN_COMPONENTS_MISMATCH_COUNT=0
P2B_LOCAL_COMPONENT_PLAN_MISMATCH_COUNT=0
P2B_LOCAL_COMPONENT_PLAN_DIFFERENTIAL=PASS
P2B_PLANNER_FULL_LAYOUT_PLAN=PASS_FOR_EXPANDED_CORPUS
P2B_LOCAL_PLAN_EVIDENCE_LEAK=NO
```

---

## 7. Planner gate classification

The planner-specific requirements from the gap document are now closed at the planner layer:

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

The final gap item, `P2B_JDK8_PLANNER_EXISTING_336_REGRESSION`, is intentionally **not** inferred by composing separate historical PASS results. The earlier 336 ARM backend differential consumed JDK-emitted plans; it did not consume plans generated by this local planner.

Therefore:

```text
P2B_JDK8_PLANNER_EXISTING_336_REGRESSION=PENDING_COMBINED_LOCAL_PLAN_TO_ARM_BACKEND_GATE
```

---

## 8. Authorization remains fail-closed

```text
P2B_PLANNER_LAYER_GAP=CLOSED
P2B_BACKEND_LAYER_EVIDENCE=RETAINED
P2B_COMBINED_PLANNER_BACKEND_336=NOT_YET_RUN
P2B_PROTECTED_JAMVM_GLIBJ_EXECUTION_COMPATIBILITY=NOT_YET_PROVEN

P2B_PRECHANGE_V1_RUNTIME_AUTHORIZATION=SUSPENDED
P2B_RUNTIME_PATCH=FORBIDDEN
P2B_RUNTIME_CANDIDATE_BRANCH=DO_NOT_CREATE
P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=FORBIDDEN
DEVICE_PASS=NO
STABLE=NO
```

This preserves the Error Correction Rule: two independently proven layers are not automatically promoted to an integrated runtime result.

---

## 9. Next approved unit

```text
CURRENT_UNIT=P2B_COMBINED_LOCAL_PLANNER_TO_ARM_BACKEND_DIAGNOSTIC
ACTION=
  generate plans with the source-derived local Java6 planner rather than JDK reference metadata;
  feed those plans into the exact already-proven ARMv5/uClibC JDK8 FreeType/LayoutEngine backend;
  rerun the established 336 string-width and whole-raster differential;
  require exact field-by-field equality and zero mismatch;
  keep runtime, packaging, and physical device untouched.

FOLLOWING_REQUIRED_UNIT=
  prove the staged Java6 planner closure executes/loads under the protected JamVM/glibj runtime boundary without replacing protected runtime files.
```
