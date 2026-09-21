# B4-SCREENSHOT-R1-AB — Stable native presentation buffer for RG35XX screenshots

Status: BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO
Primary variable: NATIVE_PRESENTATION_CANVAS_LIFETIME_ONLY

## Preflight

### CURRENT_SYMPTOM

Physical RG35XX LCD:
- game image is visually complete;
- previous global green tint is fully fixed.

RetroArch/GarlicOS screenshot output:
- PNG size is 640x480;
- screenshot does not contain the complete image visible on the LCD;
- only a narrow horizontal strip of the Smart-Fit game viewport is captured.

Real Football 2015 source geometry is 240x320.
Golden Smart-Fit maps this exactly to:
- destination width = 360
- destination height = 480
- destination x = 140
- destination y = 0

Observed screenshot 1:
- non-black bbox: x=140..499, y=0..33
- all 34 visible rows span the full expected 360px game width.

Observed screenshot 2:
- non-black bbox: x=140..499, y=35..40
- rows 35..39 span the full expected 360px game width;
- row 40 is only partially populated.

This is not a green-tint regression. It is a screenshot/frame-capture consistency defect.

### HISTORY_FOUND

The current Golden native presenter owns a single output surface:

uint16_t canvas[RG35XX_GOLDEN_MAX_PIXELS];

Every present does:
1. memset(canvas, black)
2. blit_nearest() into the same canvas
3. video_cb(canvas, 640, 480, pitch)

The same memory that was just handed to the frontend is immediately reused to construct the next frame.

The G1 contract requires a complete valid generation to be presented and preserves the latest image when Java stalls, but it does not currently guarantee that the memory supplied in the previous video callback remains immutable while the next frame is being composed.

Historical VC7R12 addressed a different Java frontbuffer ownership problem and is not admitted here. Current evidence points to the native 640x480 presentation surface, because:
- the screenshot strips have the exact Smart-Fit x/width generated natively;
- the physical LCD remains correct;
- current Java/runtime/video-mask behavior is already device-accepted.

### PREVIOUS_FIX

No prior admitted B4 fix exists for RG35XX screenshot capture consistency.

### PREVIOUS_EVIDENCE_LEVEL

- B4-VIDEO-MASK-R2 green-tint fix: DEVICE-PASS.
- B4-HOTPATH-R2 diagnostic cleanup: DEVICE-PASS.
- Current screenshot defect: DEVICE-EVIDENCE from two 640x480 captures plus direct physical-LCD comparison.

### ROOT-CAUSE HYPOTHESIS

The strip pattern is consistent with a read/write race on the single native presentation canvas.

A screenshot reader can observe the current 640x480 framebuffer while the core is concurrently clearing and repopulating that same memory for the next frame. Because blit_nearest writes top-to-bottom, the captured PNG can contain only the scanlines that happened to be populated when the reader crossed them.

This is a hypothesis to test, not yet a DEVICE-PASS conclusion.

### REGRESSION_RISK

This checkpoint changes native core presentation memory ownership, so rollback is mandatory.

Preserve unchanged:
- B4-HOTPATH-R2 Java runtime
- B4-VIDEO-MASK-R2 software color-mask bypass
- JamVM L
- GNU Classpath
- Java RGB565 producer
- native receiver thread
- frame header/payload protocol
- RGB565 decode
- front/back logical frame publication
- Smart-Fit geometry/math
- input
- audio
- font
- PNG
- resolution
- game JARs

### MINIMAL_PROPOSED_CHANGE

Replace the single native presentation canvas with two static canvases:

- present_canvas: the complete frame most recently handed to video_cb
- build_canvas: the alternate buffer used for memset + Smart-Fit blit

Per frame:
1. build the entire next 640x480 frame into build_canvas;
2. swap present_canvas/build_canvas;
3. call video_cb with present_canvas.

The previous callback buffer is therefore not modified while the next frame is being constructed.

No Java/runtime change is included.
No screenshot-specific frontend API or RetroArch patch is included.

### EXPECTED DEVICE TEST

Use Real Football 2015 first.

Acceptance:
1. Installer only accepts exact B4-HOTPATH-R2 runtime, exact protected JamVM/glibj, and exact current B4 core.
2. Physical LCD remains visually identical and green tint remains fixed.
3. Input remains usable.
4. Normal game exit works; no hard reset.
5. Take at least 3 screenshots at different moments.
6. Screenshot PNGs must contain the complete 360x480 Smart-Fit viewport rather than isolated horizontal scanline strips.
7. Runtime/JamVM/glibj hashes remain unchanged.
8. New core hash matches the build artifact.
9. Hotpath logging remains bounded.

BUILD-PASS does not imply DEVICE-PASS.
STABLE remains NO.


## Build result — 2026-09-21

- source commit: 63b6392c1344df1303f06a7ad754b2fe5d77abdd
- workflow/run ID: 35559834092
- job ID: 106210465825
- artifact ID: 10622120535
- artifact digest / ZIP SHA256: d65c5368f28f34f8de8fc5d2cac0f3f2c6bddaab860d0f71ff3e94e64ca41d1e
- old B4 core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- new screenshot-R1 core SHA256: f6eb57bd38a021fd1ef1936293492ce21bb02dfc4d06a1a8f5cb7e47016310ca
- required B4-HOTPATH-R2 runtime SHA256: 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c
- B4_SCREENSHOT_R1_PATCH: PASS
- PRESENTATION: DOUBLE_BUFFERED
- core ELF32 / ARM EABI5 / soft-float gates: PASS
- Golden receiver / RGB565 / B4 lifecycle markers: PRESERVED
- Java runtime packaged: NO
- BUILD-PASS: YES
- DEVICE-PASS: NO / DEVICE-TEST-PENDING
- STABLE: NO

Exact scope:
- only native 640x480 presentation-canvas lifetime changed;
- receiver front/back logical frames are unchanged;
- Java frame protocol is unchanged;
- Smart-Fit geometry/scaling is unchanged;
- B4-HOTPATH-R2 runtime remains the required runtime and is not packaged;
- JamVM/glibj/audio/font/PNG/game JARs are unchanged.


## Device evidence — 2026-09-21 11:15

Evidence package:
B4-SCREENSHOT-R1-EVIDENCE-20260921-111537.zip

Installed/protected hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- B4-HOTPATH-R2 runtime: 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c
- B4-SCREENSHOT-R1 core: f6eb57bd38a021fd1ef1936293492ce21bb02dfc4d06a1a8f5cb7e47016310ca

Installer result: PASS.

### Screenshot target result

Real Football 2015 screenshot 1:
- PNG: 640x480
- non-black bbox: x=140..499, y=0..479
- visible width: 360 px
- visible rows: 480
- this matches the expected full Smart-Fit viewport 360x480 at x=140,y=0.

Real Football 2015 screenshot 2:
- PNG: 640x480
- non-black bbox: x=140..499, y=35..473
- visible width: 360 px
- the previous narrow scanline-strip failure is not present.

Direct user report:
- Real Football continues to run normally.
- Other games are reported to freeze visually immediately after Run.

### Native lifecycle evidence

Real Football:
- FIRST_FRAME_HEADER 240x320
- FIRST_FRAME_PUBLISH generation=1
- FIRST_PRESENT 360x480 at x=140,y=0
- CORE_DEINIT
- VIDEO_DEINIT generation=1490 presented=1490

dragon-mania-s40v6:
- FIRST_FRAME_HEADER 240x320
- FIRST_FRAME_PUBLISH generation=1
- FIRST_PRESENT 360x480 at x=140,y=0
- CORE_DEINIT
- VIDEO_DEINIT generation=221 presented=221

There is no RG35XX-VIDEO JAVA error in the captured Java log.

### Java-side evidence for dragon-mania session

The second Java session contains:
- StringIndexOutOfBoundsException: 102 occurrences
- stack path repeatedly reaches javax.microedition.rms.RecordStore.loadRecordStore / openRecordStore
- no RG35XX-VIDEO JAVA error

This means the currently captured dragon-mania freeze cannot yet be attributed solely to the new native double-buffer core: native publish/present generations continue to advance, while the game is simultaneously hitting a repeated Java RMS exception.

However, the user's broader report that multiple other games visually freeze is a regression signal and blocks promotion.

### Classification

- screenshot strip symptom on Real Football: TARGET-IMPROVED / DEVICE-EVIDENCE
- full checkpoint DEVICE-PASS: NO
- compatibility regression report: UNRESOLVED
- STABLE: NO

Do not promote R1.

### Required next A/B

Use the built-in R1 rollback with no other changes:
1. run RESTORE-B4-SCREENSHOT-R1.cmd;
2. confirm core returns exactly to 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c;
3. keep runtime 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c unchanged;
4. rerun the same non-Real-Football game(s), preferably dragon-mania-s40v6 plus NinjaSchool1;
5. collect logs after each.

Interpretation:
- if the same games resume normally after rollback, reject R1 as a native presentation regression;
- if they still freeze and reproduce the same Java-side exceptions, treat the game freeze as a separate compatibility blocker rather than a screenshot-R1 regression.

No new code checkpoint should be opened until this rollback A/B is resolved.
