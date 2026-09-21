# B4-SCREENSHOT-R1-AB — Stable native presentation buffer for RG35XX screenshots

Status: SOURCE-CREATED / BUILD-PENDING / DEVICE-TEST-PENDING / STABLE=NO
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
