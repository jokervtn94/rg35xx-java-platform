# B4-DRAGON-PNG-ICCP-R1-AB

Status: BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO

Primary variable:
PNG_ICCP_COMPATIBILITY_ONLY

## CURRENT_SYMPTOM

Dragon Mania remains visually stuck at the Gameloft startup logo.

Current clean diagnostic evidence:
- RMS exception storm removed;
- recreated RMS metadata is structurally valid;
- Display/Canvas repaint and input paths remain alive;
- media path is not reached;
- network path is not reached;
- no current Java exception explains the static logo.

## HISTORY_FOUND

The clean B4 foundation intentionally excludes PNG iCCP compatibility.

Historical device evidence for the same dragon-mania-s40v6 session contains:
RG35XX-PNG-ICCP: stripped ancillary iCCP chunk

Historical project evidence separately proved GNU Classpath ImageIO can abort when PNG assets contain ICC v4 profiles:
java.lang.IllegalArgumentException: Wrong major version number:4

Call path previously observed:
PNGICCProfile -> ICC_Profile.getInstance -> ImageIO.read -> PlatformImage -> Image.createImage -> game thread

Project rules list PNG iCCP compatibility among accepted video compatibility knowledge.

## PREVIOUS_FIX

Retained implementation:
scripts/vc6_apply_png_iccp_compat.py

Behavior:
- intercept only PlatformImage ImageIO boundaries;
- read PNG bytes;
- if valid PNG, remove only complete ancillary iCCP chunks;
- preserve all other chunks and the encoded pixel stream;
- leave non-PNG data unchanged;
- do not patch glibj.zip.

Historical marker:
RG35XX-PNG-ICCP: stripped ancillary iCCP chunk

## PREVIOUS_EVIDENCE_LEVEL

- PNG ICC v4 crash path: DEVICE-EVIDENCE
- same Dragon Mania historically exercising iCCP strip: DEVICE-EVIDENCE
- PNG iCCP compatibility appears in accepted project video knowledge
- current Dragon logo freeze causality: UNRESOLVED

## REGRESSION_RISK

This checkpoint changes image decode compatibility at three PlatformImage ImageIO boundaries.

It must preserve:
- native core
- B4 Video Mask R2
- B4 Hotpath R2
- RMS behavior
- network behavior
- media behavior
- Display/Canvas semantics
- JamVM L
- glibj.zip

No other historical graphics fix is bundled.

## MINIMAL_PROPOSED_CHANGE

Apply only:
scripts/vc6_apply_png_iccp_compat.py

on top of the exact current traced source.

Do not add:
- headless image normalization
- GameCanvas frontbuffer changes
- transform changes
- PNG tRNS changes
- audio restore
- font changes

## EXPECTED_DEVICE_TEST

Precondition runtime:
e92ac328772f0ed5aa359435b37a30aa58f5b490714b290ea2e5bb19b91dd8a0

Run ONLY:
dragon-mania-s40v6

Observe:
1. Does RG35XX-PNG-ICCP marker occur?
2. Does the game progress past the Gameloft logo?
3. Is the visible logo/render still correct before transition?
4. Does the game exit normally?
5. Are RMS/media/network exception counts still clean?

Interpretation:
- marker + progression => strong causal DEVICE-EVIDENCE for missing iCCP compatibility;
- marker + no progression => compatibility fix may still be valid but is insufficient for this startup stall;
- no marker + no progression => iCCP is not exercised in this run and cannot explain the symptom.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.


## Build result — 2026-09-21

- source commit: b87c4cbfd0a5dbbb97ee020494884502bd8eace1
- workflow/run: 35577843290
- job: 106263603953
- artifact: 10628563274
- artifact SHA256: ccc4bea976f2e10720237707eaa19327c420ae892fdae040d77747ba57835f31
- runtime SHA256: f4b88b2ee0787a74949732a0d5a754301ba49c707de726fab428930f98d33e92
- required current runtime before install: e92ac328772f0ed5aa359435b37a30aa58f5b490714b290ea2e5bb19b91dd8a0
- protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java classes: 1334
- Java major 50 gate: PASS
- PNG iCCP source gate: PASS
- PNG iCCP bytecode marker gate: PASS
- network/display/media diagnostics preserved: YES
- headless image normalization: NOT ADMITTED
- GameCanvas/frontbuffer historical fix: NOT ADMITTED
- audio/font/native-core behavior: unchanged
- BUILD-PASS: YES
- DEVICE-PASS: NO / DEVICE-TEST-PENDING
- STABLE: NO


## Device evidence — 2026-09-21 16:31

Evidence package:
B4-DRAGON-PNG-ICCP-R1-EVIDENCE-20260921-163104.zip

Evidence ZIP contents:
- DEVICE-HASHES.txt
- freej2me-java-error.log
- freej2me-vc3-early.log
- PNG-ICCP-SUMMARY.txt
- install result
- RMS current-state report

Installed state:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- protected B4 core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- PNG-iCCP runtime: f4b88b2ee0787a74949732a0d5a754301ba49c707de726fab428930f98d33e92
- installer RESULT=PASS

RMS current state:
- RMS_PRECONDITION=PASS
- Dragon metadata count=7
- ffffffff9c61314e09vhjlzvf1zxn0.rms remains 387-byte structurally-valid recreated metadata
- second previously corrupt basename remains absent
- no RMS mutation by checkpoint

Java summary:
- total lines=709
- PNG_ICCP_STRIP=0
- PNG_WRONG_MAJOR_VERSION=0
- NETWORK_TRACE_LINES=0
- MEDIA_TRACE_LINES=0
- DISPLAY_EVENT_TRACE_LINES=124
- CANVAS_LOOP_TRACE_LINES=575
- STRING_INDEX_OOB=0
- NULL_POINTER_EXCEPTION=0

Session correlation:
- native early log contains two sequential launches of the same dragon-mania-s40v6.jar
- Java log contains two corresponding FrameTransport sessions
- session 1: 347 lines; 0 PNG iCCP markers; 0 network; 0 media; 0 exceptions
- session 2: 362 lines; 0 PNG iCCP markers; 0 network; 0 media; 0 exceptions
- both sessions continue Canvas repaint/paint/flush/service activity through the bounded seq=120 sample
- second session also delivers one action key down/up completely through the input callback path

Conclusion:
- PNG iCCP sanitizer is installed but NOT EXERCISED in either observed Dragon session.
- Therefore missing iCCP compatibility does not explain the currently observed startup stall in this evidence.
- The historical iCCP compatibility remains a valid independent compatibility fix, but this checkpoint provides no causal signal for Dragon's current logo behavior.
- No current Java exception explains the stall.

Checkpoint classification:
- B4-DRAGON-PNG-ICCP-R1: DEVICE-EVIDENCE / NO-EXERCISE
- iCCP as current logo-stall cause: DEPRIORITIZED
- Dragon compatibility DEVICE-PASS: NO
- STABLE: NO

Next evidence-driven candidate:
Canonical framebuffer binding.

Current B4 Golden transport still passes the cached Libretro.lcdData int[] while separately fetching the current MobilePlatform LCD frontbuffer object as the frame lock. Historical VC7R11 device evidence proved that after JAR load these can diverge: PlatformGraphics can render into the current frontbuffer backing int[] while transport serializes a stale cached int[].

Historical VC7R12 corrected exactly that ownership mismatch by fetching the current PlatformImage and its backing int[] together for each transport request.

This directly matches the present symptom class:
- Canvas/game paint remains alive;
- flush calls complete;
- input remains alive;
- visible content can nevertheless remain stale if transport serializes an old backing array.

Next checkpoint:
B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-AB

Primary variable:
CURRENT_FRONTBUFFER_OBJECT_AND_DATA_BOUND_TOGETHER_AT_TRANSPORT_REQUEST

Do not add headless image normalization yet. Historical VC7R10 already showed varied decoded ARGB while presentation still remained wrong, and current evidence is more directly consistent with the later VC7R11/VC7R12 ownership finding.
