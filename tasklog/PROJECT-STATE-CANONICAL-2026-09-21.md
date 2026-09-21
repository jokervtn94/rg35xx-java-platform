# RG35XX Java Platform — Canonical Project State

Date: 2026-09-21
Rules: RG35XX Hard Project Rules 1.0.0 / strict
Active branch: b4-screenshot-r1-ab
Foundation: verified-clean-platform-v1
Overall: BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO
FULL_PLATFORM_STABLE=NO

## Current SD baseline

Canonical launch path:
GarlicOS -> Roms/JAVA/<game>.jar -> RetroArch -> FreeJ2ME core -> JamVM -> glibj -> freej2me-lr.jar -> MobilePlatform -> MIDlet.

Current device hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34 [DEVICE-PASS / LOCKED]
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea [IMMUTABLE]
- B4-HOTPATH-R2 runtime: 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c [DEVICE-PASS / INSTALLED]
- B4 core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c [BUILD-PASS / INSTALLED]
- B3 runtime deterministic content identity: 52e809ecf5d23f4c2c0989075270680248299bbc02e7cb8ca665bee002942783
- Roms/JAVA count in latest evidence: 20
- APP wrappers: NO

Latest real-game evidence covers Zombie Infection, Asphalt Nitro, NinjaSchool1 and Real Football. Each captured native session reached B4 CORE_DEINIT, so the current “freeze after some time” symptom is not yet proven to be a native core deadlock.

Current Java log is unhealthy:
- ~25,452 lines / ~1.18 MB
- RG35XX-JAVA-DIAG: 25,018
- requestFrame SIGNALED: 2,502
- FrameWorker WAKE: 2,502
- IPC FLUSH PASS: 2,498
- NoSuchMethodError getSequencer: 2
- LineUnavailableException: 2
- NullPointerException: 23

The current stall/hang report must therefore be split into at least:
1. hot-path diagnostic overhead;
2. actual media/text exceptions.

## Current active checkpoint

B4-SCREENSHOT-R1-AB

Primary variable:
NATIVE_PRESENTATION_CANVAS_LIFETIME_ONLY

Protected/admitted state entering this checkpoint:
- B4-VIDEO-MASK-R2 green-tint fix: DEVICE-PASS
- B4-HOTPATH-R2 cleanup: DEVICE-PASS
- JamVM L: DEVICE-PASS / locked
- glibj.zip: immutable
- current Java runtime SHA256: 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c
- current installed core before R1 screenshot test: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c

Screenshot defect evidence:
- physical LCD is complete and green tint remains fixed;
- RG35XX screenshot PNGs are 640x480 but capture only narrow horizontal strips;
- Real Football 240x320 Smart-Fit target is exactly 360x480 at x=140,y=0;
- capture 1 non-black bbox: x=140..499,y=0..33;
- capture 2 non-black bbox: x=140..499,y=35..40.

R1 hypothesis:
the single native 640x480 presentation canvas is reused for the next memset+blit while the frontend screenshot path may still read the previously presented pointer.

R1 change:
- core-only double-buffered presentation canvas;
- build complete next frame into alternate buffer;
- swap before video_cb;
- do not modify Java runtime, protocol, Smart-Fit, audio, font, PNG or input.

Build:
- commit: 63b6392c1344df1303f06a7ad754b2fe5d77abdd
- run: 35559834092
- job: 106210465825
- artifact: 10622120535
- artifact digest: d65c5368f28f34f8de8fc5d2cac0f3f2c6bddaab860d0f71ff3e94e64ca41d1e
- candidate core: f6eb57bd38a021fd1ef1936293492ce21bb02dfc4d06a1a8f5cb7e47016310ca
- required runtime: 4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c
- BUILD-PASS=YES
- DEVICE-PASS=NO_DEVICE_TEST_PENDING
- STABLE=NO

## Evidence hierarchy

0 UNVERIFIED
1 BUILD-PASS
2 DEVICE-EVIDENCE
3 DEVICE-PASS
4 STABLE

CI/build/source inspection must never be promoted to DEVICE-PASS or STABLE.

## Admission matrix

The repository contains historical and experimental code. Presence in repo does not mean admitted into current B4.

Admitted:
- pinned FreeJ2ME foundation
- JamVM L
- immutable glibj
- Lazy Media boot
- RG35XXGoldenFrameTransport
- RGB565 receiver-thread native video + Smart-Fit
- B4 early lifecycle observability

Not admitted into installed B4:
- no-mask fix (candidate R1 only)
- VC7R22 hot-path cleanup
- VC7R2 dynamic logical view
- PNG iCCP compatibility
- PNG tRNS/transparency chain
- reconstructed font stack
- exact Golden font
- Golden/CN worker-ring audio
- standalone M1 input/RMS/Image fixes

## Completed / protected facts

### JamVM L
DEVICE-PASS and protected.
Do not replace with diagnostic variants without dedicated checkpoint/rollback.

### GNU Classpath
SHA d7abe888...f2bea, immutable.
Do not casually patch glibj to work around JavaSound/Graphics2D limitations.

### B3 Runtime
BUILD-PASS.
Use deterministic content identity, not only whole-JAR SHA.

### B4 Core
BUILD-PASS.
Run 34317318204, artifact 10090552777.
B4 intentionally excluded PNG/font/audio/resolution experiments.

### No-mask green tint
Historical DEVICE-PASS for that symptom only.
Current B4 installed runtime lacks the fix; R1 is its clean re-admission test.

### Raw input
M1.7 historical DEVICE-PASS for 12 raw controls.
MobilePlatform remains sole owner of MIDP keyPressed/keyReleased/keyRepeated. Never add a duplicate dispatcher.

### RMS
Historical standalone M1.15 lifecycle/cross-process persistence evidence exists. Do not treat it as proof of every current B4 RMS edge case.

### Font
Reconstructed font SHA 20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9 is EXPERIMENTAL.
Exact Golden target SHA: 7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c.
Never call reconstructed font Golden or Stable.

## Open blockers

P1 GREEN TINT
R1 BUILD-PASS, device test pending.

P2 PERCEIVED FREEZE / LOAD STALL
Current log contains unbounded hot-path diagnostics. Historical VC7R22 cleanup is BUILD-PASS only and must be tested as a separate A/B after R1.

P3 MIDI
Current errors reach unsupported MidiSystem/getSequencer-style path. Production RG35XX must not depend on JavaSound sequencer.

P4 WAV/PCM
Current errors reach AudioSystem.getClip and LineUnavailableException. Production RG35XX must use native media path instead.

P5 TEXT
Repeated NullPointerException in GNU AbstractGraphics2D.renderScanline / drawGlyphVector / drawString. Treat as separate font/text checkpoint.

P6 AUDIO WORKER-RING
Historical device-proven contract:
- async callback
- dedicated worker
- ring 16384
- worker chunk 1470
- TSF 14700 Hz
- output 44100 Hz
- mono-x3
- PCM underrun re-prime
- native END_OF_MEDIA / BGM resume
- no retro_run audio pumping
CN short-prime 3072 has device evidence.
This path is not admitted in B4.

P7 LATER VC7 COMPATIBILITY
Dynamic resolution, PNG iCCP/tRNS, GameCanvas canonical frontbuffer, image normalization and related work must be re-admitted selectively from current evidence. Never bulk-merge history.

## Repository meaning

Key current files:
- .github/workflows/verified-clean-b4-build.yml
- .github/workflows/b4-video-mask-r1-ab.yml
- scripts/vc0_vc3_assemble.sh
- scripts/g1_apply_rg35xx_media_boot.py
- scripts/g1_apply_java_transport.py
- scripts/g1_apply_native_overlay.py
- scripts/b4_apply_early_native_log.py
- scripts/b4_verified_core_assemble.sh
- scripts/b4_apply_nomask_green_tint_fix.py
- src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java
- native/golden/rg35xx_golden_video.c/.h
- release/b4-video-mask-r1/
- tasklog/B4-VIDEO-MASK-R1-AB.md
- tasklog/VC7R15-LCD-MASK-GATE-FIX.md
- tasklog/VC7R22-GOLDEN-AUDIO-RESTORE-HOTPATH-CLEANUP.md
- tasklog/VC7R22-R1-GOLDEN-WORKER-RING-SOURCE-RECONSTRUCTION.md
- tasklog/VC7R23-AUDIO-WORKER-RING-RECONSTRUCTION.md

Only active assembly workflows/gates define what enters a checkpoint. Historical src/native/scripts files are not automatically part of production.

## Non-negotiable rules

1. TASKLOG FIRST:
   identify symptom -> search history -> compare prior occurrence -> check prior fix/evidence -> classify -> minimal change -> implement.

2. ONE PRIMARY VARIABLE PER A/B.
   Never bundle video + audio + font + transparency.

3. PRESERVE DEVICE-PASS SUBSYSTEMS.
   Touch only with current evidence and documented reason.

4. FAIL CLOSED.
   Abort on unknown hash/source layout/anchor count.

5. HASH + BACKUP + ROLLBACK.
   Every installer verifies precondition, payload and installed hashes; backs up before writing; supports restore.

6. BOUNDED LOGGING ONLY.
   No unbounded per-frame diagnostics. First-N or state-transition-only.

7. CANONICAL GARLICOS GAME PATH:
   /mnt/mmc/Roms/JAVA/
   No per-game Java APP wrappers unless architecture is intentionally changed.

8. AUDIO FORBIDDEN REGRESSIONS:
   no production MidiSystem.getSequencer,
   no AudioSystem.getClip,
   no eager MediaWarmup,
   no /dev/snd/seq boot probe,
   no 735-frames-per-retro_run pump,
   no audio lifecycle tied to video cadence.

9. FONT STATUS:
   reconstructed != Golden.

10. STATUS CLAIMS:
   CI != DEVICE-PASS;
   one short run != STABLE;
   symptom fixed != full platform fixed.

## Next steps

STEP 1 — B4-SCREENSHOT-R1-AB
Install the core-only candidate and test Real Football 2015.
Acceptance:
- physical LCD unchanged
- green tint remains fixed
- input/normal exit remain good
- at least 3 screenshots contain the complete 360x480 Smart-Fit viewport, not scanline strips
- runtime/JamVM/glibj remain unchanged
- core == f6eb57bd38a021fd1ef1936293492ce21bb02dfc4d06a1a8f5cb7e47016310ca

STEP 2 — AUDIO
Only after screenshot checkpoint is resolved.
Isolate getSequencer/getClip and compare against exact Golden/CN worker-ring history.

STEP 3 — TEXT/FONT
Address AbstractGraphics2D/renderScanline NPE separately. No glibj/media bundle.

STEP 4 — PNG ICC
Re-admit PNG iCCP compatibility only as its own A/B if current KDTT evidence still requires it.

STEP 5 — FINAL REAL-GAME ACCEPTANCE
Multiple games, long-duration sessions, normal exit/relaunch, audio/input/RMS/resolution, bounded logs and final SHA manifest. Only then consider STABLE.

## Final rule

History + real-device evidence outrank new inference.

Priority:
1. previous DEVICE-PASS for same symptom
2. previous DEVICE-EVIDENCE
3. previous BUILD-PASS implementation
4. new minimal A/B experiment
