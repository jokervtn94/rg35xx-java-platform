# RG35XX P2B FONT / TEXT — EVIDENCE SYNTHESIS v4

**Status:** AUDIT_ONLY / BACKEND_AND_RUNTIME_PLANNER_CLOSED_FOR_ESTABLISHED_CORPORA  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text`  
**Audit parent / accepted P2A production parent:** `77a36526e0f6d875c57c7e9a973e0c1a05573721`  
**Pinned Miyoo/Aweigit:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**Exact OpenJDK reference:** `jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2`

> This document supersedes `P2B-FONT-TEXT-EVIDENCE-SYNTHESIS-v3.md` for current P2B evidence classification. It also closes the diagnostic blocker recorded in `P2B-FONT-TEXT-RUNTIME-PLANNER-GAP-v1.md` for the expanded planner corpus. It does not rewrite either historical record. It does not claim DEVICE-PASS, stable status, unrestricted Unicode parity, arbitrary-font parity, packaging permission, font redistribution permission, or P2B phase completion.

---

## 1. Governing Miyoo-first ownership is unchanged

The semantic owner remains the pinned Aweigit/Miyoo platform:

- `src/javax/microedition/lcdui/Font.java`
- `src/org/recompile/mobile/PlatformGraphics.java`
- `src/org/recompile/freej2me/Anbu.java`

The exact failure owner remains:

```text
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
```

OpenJDK8 is used only to reconstruct the AWT/JDK backend semantics required by that pinned Miyoo path and unavailable on the accepted RG35XX raw/headless runtime. The work does not transfer MIDP ownership to a new independent platform implementation.

Protected JamVM and protected `glibj.zip` remain unchanged.

---

## 2. Backend evidence from v3 remains retained

All backend closure in v3 remains valid and is not weakened by the later planner correction:

```text
FONT_IDENTITY=LOCKED
P2B_FONT_METRICS_ARM=EXACT_24_OF_24
P2B_CHARWIDTH_BMP=EXACT_196608_OF_196608
P2B_CANDISPLAY_BMP=EXACT_196608_OF_196608
P2B_STRING_WIDTH=EXACT_336_OF_336_FOR_ESTABLISHED_CORPUS
P2B_WHOLE_STRING_DRAW_RASTER=EXACT_336_OF_336_FOR_ESTABLISHED_CORPUS
P2B_RTL_SUBSET=EXACT_72_OF_72_FOR_WIDTH_AND_RASTER
P2B_JDK8_LAYOUTENGINE_ARM_SEMANTICS=EXACT_FOR_EXISTING_NONSIMPLE_CORPUS
P2B_NATIVE_LINK_SELF_CONTAINED_CXX=PASS
P2B_NATIVE_LINK_DLOPEN_SYSROOT=PASS
```

The exact backend lineage remains:

```text
OPENJDK8=jdk8u504-b01@4efe36434f44bafb854e602ccbbe1b5696fce1a2
FREETYPE_INCLUDE_TREE=43f2e4398cfd927acac29ce3515e23a195349eb7
FREETYPE_SRC_TREE=8690dd39ef9f4da5bae000d757fe6dfa2d2102a6
LAYOUT_TREE=bc6641fecdfb59f3146bb1591e090761a24b4061
```

The exact audited font remains:

```text
FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724
FONT_NAME=MiSans_Normal
FONT_PS_NAME=MiSans-Normal
FONT_NUM_GLYPHS=29601
```

Font bytes remain diagnostic input only and are not committed or uploaded in evidence artifacts.

---

## 3. Why v3 candidate eligibility was suspended

`P2B-FONT-TEXT-RUNTIME-PLANNER-GAP-v1.md` correctly identified that the 336-case raster and 192-case complex-width ARM probes consumed JDK-generated layout plans. Those results proved the backend after planning, but did not yet prove that a production RG35XX runtime could independently derive a generic JDK8 plan from arbitrary input text.

The missing planner responsibilities were:

```text
BIDI_REQUIREMENT
PARAGRAPH_BASE_DIRECTION
PER_UTF16_BIDI_LEVELS
LOGICAL_TO_VISUAL_MAPPING
COMPONENT_BOUNDARIES
COMPONENT_VISUAL_ORDER
TEXTLABEL_LAYOUT_FLAGS
SCRIPT_RUN_SEGMENTATION
COMBINING_MARK_ENGINE_FLAG_0x4
SUPPLEMENTARY_UTF16_ASSEMBLY
```

Therefore the v1 pre-change runtime authorization was suspended and the runtime remained untouched.

---

## 4. Exact ScriptRun closure — PASS

The planner source pins are:

```text
Script.java        = 155ab07d93cacf854c19187e020a66ef63921e52
ScriptRunData.java = e72c85624242ce7c486d78dbf800c91facb2cfbf
ScriptRun.java     = e719fc335605f957f6bd713da226700aba15b8c9
```

The staged diagnostic delta is package relocation only and compiles as Java 6 / class major 50.

Result:

```text
P2B_PLANNER_SCRIPTRUN_CASES=8260
P2B_PLANNER_SCRIPTRUN_FULL_CASES=4747
P2B_PLANNER_SCRIPTRUN_SLICE_CASES=3513
P2B_PLANNER_SCRIPTRUN_MISMATCH_COUNT=0
P2B_PLANNER_SCRIPTRUN_GENERIC_DIFFERENTIAL=PASS
```

This closes script segmentation without heuristic script tables or corpus-specific lookup data.

---

## 5. Exact Java6 Bidi closure — PASS

Exact JDK8 source/resource identity is pinned, including:

```text
Bidi.java      = 3d0e1381adb1cb11cbd45d2f8e09c4830aa1fba8
BidiBase.java  = 6485bea94e69f1cb3f054360fb5caad461a60ef8
BidiLine.java  = 1d54867ad42b486857693e63a3cf15fbe99354e9
BidiRun.java   = 07519db3934eb47a566ad0e597611bcfa8ed2b67
ubidi.icu blob = 3c545bd7a450e407f4755effb75f68886faa43e5
ubidi.icu size = 19924
ubidi.icu SHA256 = 38b96789a88870d20c0eb1392cb8fc2bd58e2c31cfff3326bea1e00a52ec9889
```

Permitted diagnostic adaptations were source-preserving closure work only: package/import relocation, Java6 multi-catch split with identical body, exclusion of an unreachable `UCharacterProperty` friend method, and source-extracted `UCharacter`/UTF16 helpers.

Result:

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

Evidence:

```text
RUN=37109167277
HEAD=364778e14a71f6842a364a60aad96dcfbbd65f77
ARTIFACT=11269112192
ARTIFACT_SHA256=f4f600fa14178b7e214f17aede92fc1d1f9fa6406c739ce24b996512da8816af
BYTE_LEAK=NO
```

Protected GNU Classpath `java.text.Bidi` is not required by this planner closure.

---

## 6. JDK8 mark classifier closure — PASS; protected glibj classifier rejected for parity

`GlyphLayout.EngineRecord` requires only the JDK8 predicate:

```text
General_Category in { Mn, Me, Mc } -> engineFlags |= 0x4
```

A compact classifier was generated from the pinned JDK8 UnicodeData source and compiled as Java6/class-major-50.

Result:

```text
P2B_PLANNER_MARK_CODEPOINT_COUNT=1645
P2B_PLANNER_MARK_RANGE_COUNT=204
P2B_PLANNER_MARK_CODEPOINTS_TESTED=1114112
P2B_PLANNER_MARK_JDK8_REFERENCE_TRUE=1645
P2B_PLANNER_MARK_LOCAL_TRUE=1645
P2B_PLANNER_MARK_MISMATCH_COUNT=0
P2B_PLANNER_MARK_DIFFERENTIAL=PASS
```

The same audit established that GNU Classpath 0.99 character-category data is not a valid JDK8 parity substitute for this predicate:

```text
P2B_GLIBJ_MARK_MEMBERSHIP_TRUE=1108
P2B_JDK8_MARK_MEMBERSHIP_TRUE=1645
P2B_GLIBJ_VS_JDK8_MARK_DIFF_COUNT=706
P2B_PROTECTED_GLIBJ_MARK_CLASSIFIER=NOT_EXACT_JDK8
```

Therefore the runtime planner must use the source-derived compact JDK8 predicate and must not patch or depend on protected glibj category data for this semantic.

Evidence:

```text
RUN=37111149098
HEAD=f0278855b96f171de07a527528eeb36bad4e4d91
ARTIFACT=11269014042
ARTIFACT_SHA256=4a6a4f754784dcd7b831d53a7d61503182909be44e22f3daa9844ba0e33990a
BYTE_LEAK=NO
```

---

## 7. Expanded exact JDK8 component-plan reference — PASS

The planner corpus was expanded beyond the original 14-string backend corpus. It explicitly exercises multi-component, mixed-script, mixed-bidi, RTL line/component behavior, visual reordering, combining marks, controls, numbers in RTL contexts, and supplementary characters.

Reference result:

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
P2B_JDK8_EXPANDED_PLAN_REFERENCE_RESULT=PASS
```

Reference evidence:

```text
RUN=37109625862
HEAD=ef1b6c0a3eb8519b777642226189fec158c2eae8
ARTIFACT=11269820088
ARTIFACT_SHA256=ee35a561f840273dffa9525d69f1ae1d8478dec67d326364d8545bf558084d62
BYTE_LEAK=NO
```

---

## 8. Independent local full component-plan differential — PASS

The local planner combines only the source-derived JDK8 closure:

```text
Bidi / BidiBase / BidiLine / BidiRun
UBiDiProps + pinned ubidi.icu
JDK8 UTF16 closure
Script / ScriptRunData / ScriptRun
BidiUtils
source-derived JDK8 Mn/Me/Mc classifier
TextLine firstVisualChunk rule
TextLabelFactory level/line-direction layout flags
GlyphLayout EngineRecord 0x4 rule
```

It independently rebuilds, from UTF-16 input only:

```text
LINE_LTR
LEVELS
CHAR_L2V
COMPONENT_VISUAL_ORDER
COMPONENT_START_LIMIT_LEVEL_FLAGS
SCRIPT_RUN_START_LIMIT_SCRIPT_ENGINEFLAGS
```

The JDK8 reference is regenerated fresh in the same run; no expected plan table is hard-coded into the local implementation.

A correction removed the last hidden host/protected `java.lang.Character` dependency from supplementary assembly. The final diagnostic uses the already source-derived JDK8 `UTF16.isLeadSurrogate`, `UTF16.isTrailSurrogate`, and `UTF16.charAt` closure instead.

Final corrected result:

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

Final evidence:

```text
RUN=37111651688
HEAD=ff450a96473c3fcd48aa8a86b9ab29e0a4089bfe
ARTIFACT=11269648705
ARTIFACT_SHA256=6c48b4f7fd1aa159764a5d9c35093df12b866fd3efc6323fba028d468c9366f6
```

The ordinary P2B audit also passed on the same HEAD:

```text
P2B_FONT_TEXT_AUDIT_RUN=37111651686
RESULT=SUCCESS
```

---

## 9. Runtime planner gap v1 classification update

The historical gap document remains valid as the reason the first runtime authorization was suspended. Its required planner gate is now satisfied for the established expanded corpus:

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

The prior 336 width/raster backend evidence remains retained and is the regression target for the host candidate. No corpus lookup table, heuristic Bidi path, glibj patch, or game-specific code is used to close the planner gap.

Classification:

```text
P2B_GENERIC_RUNTIME_LAYOUT_PLANNER=CLOSED_FOR_EXPANDED_PLANNER_CORPUS
P2B_RUNTIME_PLANNER_GAP_V1=SUPERSEDED_BY_EXACT_DIAGNOSTIC_EVIDENCE
P2B_PRECHANGE_V1_SUSPENSION_REASON=CLOSED
```

This is a bounded host-diagnostic claim, not an exhaustive Unicode conformance certification.

---

## 10. Minimum candidate boundary remains unchanged

The boundary from `P2B-FONT-TEXT-BOUNDARY-DESIGN-AUDIT-v1.md` remains authoritative. The first host candidate may only replace the missing RG35XX raw/headless font backing:

```text
pinned Miyoo Font / PlatformGraphics semantics
        -> raw-only RG35XX route
        -> one thin RG35XXFontText Java adapter
        -> one exact JDK8-derived native font backend
        -> existing accepted RG35XXCore2D.blit composition
```

The planner closure adds one Java6 source-derived planning component inside that same owner boundary; it does not enlarge the graphics boundary.

Protected JamVM/glibj, `RG35XXCore2D`, input, video, audio, presenter, RMS, lifecycle, upstream gitlink and game behavior remain outside the candidate delta.

---

## 11. Current authorization state

The evidence is now sufficient for a new pre-change lock to authorize exactly one owner-scoped **host candidate** from the accepted production parent.

It is not sufficient to authorize packaging or physical testing before host/module gates.

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
MIYOO_BUILD_BASE=PRESERVED
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY

P2B_BACKEND_SEMANTICS=CLOSED_FOR_ESTABLISHED_P2B_CORPUS
P2B_GENERIC_RUNTIME_LAYOUT_PLANNER=CLOSED_FOR_EXPANDED_PLANNER_CORPUS
P2B_PROTECTED_JAMVM_GLIBJ_CHANGE=NO
P2B_RUNTIME_CANDIDATE_ELIGIBILITY=YES_SUBJECT_TO_PRECHANGE_LOCK_V2

P2B_DEVICE_PACKAGE=FORBIDDEN
P2B_PHYSICAL_TEST=FORBIDDEN_UNTIL_HOST_MODULE_GATE_PASS
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
```

---

## 12. Next authorized engineering sequence

```text
P2B PRE-CHANGE LOCK v2
        ↓
CREATE ONE HOST CANDIDATE FROM 77a36526e0f6d875c57c7e9a973e0c1a05573721
        ↓
OWNER-SCOPED IMPLEMENTATION ONLY
        ↓
JAR ENTRY-SET / PROTECTED-HASH / JAVA6 / NATIVE-DEPENDENCY GATES
        ↓
P2B HOST MODULE EXERCISER + CANONICAL BACKEND/PLANNER DIFFERENTIALS
        ↓ PASS REQUIRED
PACKAGE / FONT-PROVISIONING REVIEW
        ↓
ONE ORIGINAL-RG35XX P2B PHYSICAL MODULE TEST
        ↓ PASS REQUIRED
PROMOTION REVIEW
```

No commercial game is a gate or owner for this phase.
