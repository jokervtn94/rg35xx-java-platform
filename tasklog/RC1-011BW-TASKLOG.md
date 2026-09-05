# RGJ-RC1-011BW — Golden Baseline Reconciliation + Comprehensive Device Matrix

## Why this task exists
The device evidence shows the pre-project RG35XX Java stack had already reached a stable working state across real games. Recent RC work introduced useful architecture and diagnostics, but also regressed boot because several assumptions drifted away from the proven device runtime. The strategy is therefore changed from patch-by-patch debugging to baseline-first reconciliation.

## Golden-device evidence to preserve
- JamVM executable: `/mnt/mmc/CFW/java/bin/jamvm`.
- FreeJ2ME working directory: `/mnt/mmc/BIOS`.
- Runtime JAR historically used on device: `/mnt/mmc/BIOS/freej2me-lr.jar`.
- Core: `/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so`.
- Video: fixed 640x480 frontend, RGB565 IPC, receiver thread, SMART-FIT.
- Input: direct numeric mapping was proven in real games.
- Font: historical working builds reported `bitmap-fallback`, `VN-raster`, then `Unicode8x12`; GTK was not part of the proven target runtime.
- Audio: native worker ring, SoundFont synth, MIDI, looping and native END_OF_MEDIA/BGM resume were observed working.
- stdout must remain binary video IPC only. Human-readable diagnostics go to stderr/file.
- No aggressive Java restart watchdog; historical READY text contamination demonstrated why protocol purity matters.

## Project features to reconcile on top, one layer at a time
1. persistent JamVM stderr diagnostics;
2. absolute JamVM launch;
3. lifecycle coordination;
4. frame scheduler/dirty tracking;
5. bounded input repeat engine;
6. image/transform cache;
7. native media registry/event queue/ToneControl;
8. RMS policy (keep pinned upstream multi-file RecordStore authoritative until device evidence justifies more);
9. font modernization only after the historical no-GTK baseline is restored.

## Test strategy
A single comprehensive MIDlet JAR must expose independent PASS/FAIL/WARN/PENDING results for:
- boot/video cadence;
- primitives, drawRGB alpha, PNG tRNS, sprite transforms;
- font metrics/rendering;
- key press/release/repeat;
- RMS read/write/reopen and persistence across app restart;
- worker thread and memory/GC probe;
- playTone, PCM/WAV, MIDI, ToneControl, Player close/reopen cycles;
- presence of project classes/properties.

One optional subsystem failure must never abort the rest of the MIDlet. Results are persisted to `/mnt/mmc/Java/test-evidence/rg35xx-comprehensive-test.log` and a summary file.

## Current action
- Reverted the unproven HeadlessToolkit experiment from patch 0010 so the repository returns to the last known clean project assembly baseline.
- Keep 011BR persistent stderr and 011BU absolute JamVM launcher because real-device evidence proved both useful/correct.
- Do not claim the current project font path is fixed; the historical renderer source is not present in repository history and must be recovered/reconstructed from the proven baseline, not guessed.
- Build and use `RG35XX_Comprehensive_Platform_Test.jar` as the shared device matrix for subsequent reconciliation.

## Pass policy
BUILD-PASS and DEVICE-TEST-PASS remain separate. The comprehensive JAR may mark subsystem diagnostics PASS, but DEVICE-TEST-PASS requires review of the full mandatory hardware matrix and lifecycle evidence.
