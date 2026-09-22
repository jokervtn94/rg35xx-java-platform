# RG35XX-CLEAN-CONSOLIDATED-R1 — Tasklog

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r1`
Base: `verified-clean-platform-v1`
Base commit: `1cfce475cbede7bd995bb436926718ca1565702d`
Status: SOURCE-CONSOLIDATION-IN-PROGRESS / DEVICE-TEST-PENDING / STABLE=NO

## Goal

Build one consolidated RG35XX Java runtime candidate on the current clean base without rebuilding the platform from zero.

The candidate must:
- preserve all protected/device-proven foundations;
- selectively re-admit only compatibility fixes with real RG35XX evidence or narrowly understood root cause;
- keep production ownership simple;
- exclude legacy helper graphs, speculative caches and unproven source-reconstructed audio;
- produce one fail-closed install/restore/evidence package for real-game testing.

Official handheld reference used for architecture:
- `aweigit/freej2me-miyoomini` master
- audited commit `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

The official Miyoo code is reference material only. No JDK17/AWT/SDL2 source is copied into this Java-6/JamVM runtime.

---

## Protected foundation — MUST NOT CHANGE

- FreeJ2ME-Plus pin:
  `13ec186903087156c145268f8706eecfaf9f1e50`
- JamVM L SHA256:
  `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- GNU Classpath glibj.zip SHA256:
  `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- Protected B4 native core SHA256:
  `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`
- Java target: class major 50
- Lazy Media Boot
- Golden Java async RGB565 frame transport
- native Golden receiver/front-back publication/Smart-Fit
- B4 bounded early lifecycle/video observability

No native core is rebuilt or packaged by R1.

---

## Re-admitted components

### 1. B4 Video Mask R2 — DEVICE-PASS scoped

Source owner:
`PlatformGraphics.flushGraphics()`

Reason:
physical RG35XX LCD confirmed the historical global green tint was removed.

Behavior:
- software LCD color mask is not applied to RG35XX framebuffer pixels;
- FunLights slow-path behavior remains available;
- Mobile.renderLCDMask state/API is preserved.

Evidence:
`B4-VIDEO-MASK-R2-AB` DEVICE-PASS for green-tint symptom.

### 2. B4 Hotpath R2 — DEVICE-PASS scoped

Source owner:
`RG35XXGoldenFrameTransport`

Reason:
device test reduced RG35XX-JAVA-DIAG from 25,840 to 12 bounded startup markers and reduced total Java log volume by 98.13%.

Behavior:
- remove unbounded request/frame diagnostics;
- preserve lifecycle and real error diagnostics;
- no transport semantic change.

Evidence:
`B4-HOTPATH-R2-AB` DEVICE-PASS for diagnostic cleanup and preservation of display-color fix.

### 3. VC6 PNG iCCP source compatibility — DEVICE-EXERCISED

Source owner:
`PlatformImage`

Reason:
old GNU Classpath PNG ICC parser rejects newer ICC profiles.

Behavior:
- only complete ancillary PNG iCCP chunks are removed before ImageIO;
- encoded pixel data remains untouched;
- glibj.zip remains immutable.

Evidence:
real RG35XX evidence exercised the strip path and did not reproduce the old ICC-v4 blocker in that run.

### 4. VC7R2 dynamic logical view — DEVICE-PROVEN scoped

Source owner:
`Libretro.java`

Reason:
logical game resolution and physical 640x480 output are separate.

Behavior:
- infer a valid WxH token from JAR filename;
- preserve/reassert logical LCD across load/settings/run;
- physical scaling remains native Smart-Fit.

Device-proven:
KDTT 320x240 -> physical 640x480.
Historical evidence also exists for 240x320, 352x416 and 360x640 mappings, but R1 does not overclaim all cases.

### 5. Canonical framebuffer binding — DEVICE-EVIDENCE / ownership hardening

Source owner:
`Libretro.java`

Reason:
historical VC7R11 proved cached framebuffer data and current PlatformImage could diverge.

Behavior:
- fetch current PlatformImage and its backing int[] as one pair on every frame/control request;
- bind that exact pair to Golden transport;
- bounded first-N/identity-change diagnostics only.

Latest Dragon evidence did not reproduce a mismatch, but confirmed the corrected ownership path remains operational with protected core unchanged.

---

## Explicitly NOT admitted

These project files may remain in Git history/source repository but MUST NOT appear in the R1 runtime JAR:

- `RG35XXFrameScheduler`
- `RG35XXImageCache`
- `RG35XXTransformCache`
- old `RG35XXLifecycle`
- `RG35XXBitmapText` as production renderer
- `RG35XXRmsCoordinator`
- `RG35XXRmsAtomicFile`
- `RG35XXAudioBootstrap`
- `RG35XXAudioProtocol`
- `RG35XXAudioTransport`
- `RG35XXMediaProfile`
- `RG35XXMediaRegistry`
- `RG35XXNativePlayer`
- `RG35XXToneSequenceEncoder`
- `RG35XXWavDecoder`

Reason:
the clean runtime already proves these helpers are not required for boot/video/input fundamentals, and reintroducing the old graph would recreate duplicate ownership.

---

## Deferred by design

### Canvas/serviceRepaints rewrite

Official Miyoo demonstrates a much simpler single-paint-owner model.
Current FreeJ2ME-Plus has a newer asynchronous event model.

R1 does NOT replace Canvas repaint semantics because the proposed serialization fix has not yet passed real-device acceptance.

R1 therefore preserves pinned Canvas behavior for the first consolidated candidate.

### RMS persistence rewrite

Device audit proved two zero-length Dragon metadata files caused a real RecordStore exception storm, and reversible quarantine removed the storm.

R1 does not redesign the on-disk RMS format yet.

Reason:
the corruption was real, but removing it did not resolve Dragon's startup-logo freeze. A new persistence format/atomic write policy should be a separately reviewable change.

### Font replacement

The project has a device-proven experimental bitmap Unicode semantics path, but its resource is still RECONSTRUCTED-NOT-GOLDEN.

R1 does not make that resource the production font.

### Audio

Historical worker-ring/TSF architecture remains valuable and device-proven in older binaries, but exact reproducible Golden/CN source/binary parity has not been recovered.

R1 MUST NOT:
- use MidiSystem.getSequencer as the final production backend;
- use AudioSystem.getClip as the final production backend;
- pump audio from retro_run();
- restore eager media warmup.

Audio remains a known pending subsystem for this candidate.

### 3D

M3G/micro3d from official Miyoo is reference-only.
No EGL/GLES dependency is added to R1.

---

## Official Miyoo principles retained

R1 uses Miyoo as an architecture reference, not as source replacement:

1. one display owner;
2. one physical input owner;
3. one MIDP event dispatcher;
4. native presentation outside game semantics;
5. audio outside the render loop;
6. persistent data isolated per suite;
7. no need for duplicate cache/scheduler owners on weak hardware.

Current Golden RG35XX video remains more appropriate for libretro than Miyoo's blocking SDL2 pipe.

---

## Build gates

The R1 CI must fail closed unless all are true:

1. exact FreeJ2ME pin;
2. Java class major 50 for every class;
3. Lazy Media marker present;
4. Golden transport present;
5. Video Mask R2 postconditions present;
6. Hotpath R2 hot markers absent and bounded/error markers preserved;
7. PNG iCCP helper guards exactly three decode boundaries;
8. dynamic-view source markers present;
9. canonical framebuffer request/control calls use current PlatformImage + current int[] pair;
10. stale cached-lcdData transport calls absent;
11. forbidden helper classes absent from the built JAR;
12. no native core packaged;
13. installer/restore/collector PowerShell parse successfully;
14. SHA256SUMS verifies.

---

## Device install policy

Installer changes runtime JAR aliases only.

Before installation it MUST verify:
- JamVM L exact SHA;
- immutable glibj exact SHA;
- protected B4 native core exact SHA;
- candidate runtime payload exact SHA.

It backs up all existing runtime aliases and logs before writing.

Unknown current runtime is allowed only because it is treated as replaceable data and is fully backed up; protected foundation hashes remain hard fail-closed preconditions.

Rollback restores the exact pre-install aliases.

---

## Real-game acceptance set

Run after INSTALL PASS:

1. **Real Football 2015**
   - physical LCD color remains normal;
   - input usable;
   - normal exit;
   - no hard reset.

2. **KDTT 320x240 build with filename WxH token**
   - logical size marker remains 320x240;
   - native presentation remains 640x480;
   - PNG iCCP old error absent or sanitizer marker observed;
   - assets/text/rendering inspected.

3. **Dragon Mania S40v6**
   - commercial-game stress case;
   - record whether it remains at Gameloft logo or progresses;
   - no RMS exception storm should reappear if quarantined stores remain absent/valid;
   - normal exit/no hard reset.

Optional:
- NinjaSchool1 for 240x320 no-token baseline.

Do not run another Java game after a failure that requires hard reset; collect evidence first.

---

## Expected evidence

Collector must preserve:
- install result;
- JamVM/glibj/core/runtime hashes;
- freej2me-java-error.log;
- freej2me-vc3-early.log;
- freej2me-core.log;
- freej2me-java-control.log when present;
- summarized counts for PNG iCCP, ICC-v4 errors, dynamic view, framebuffer-bind mismatches, audio exceptions, Java exceptions, native lifecycle.

Physical-LCD observation is authoritative for display color because the known RG35XX screenshot path can be incomplete.

---

## Status vocabulary

- BUILD-PASS != DEVICE-PASS
- candidate installed != stable
- one real-game pass != full platform pass
- STABLE=NO until multi-game device acceptance is complete

