# RG35XX Golden Binary Baseline

This branch rebuilds the platform from a pair of binaries that were already proven to run real Java games correctly on the RG35XX. These binaries are treated as the behavioral baseline, not the current RC patch stack.

## Golden artifacts

- `freej2me-lr.jar`
  - SHA-256: `de510e978ee0b601ac25c496197197676f86725662c434316825e00a86b497b8`
  - Main class: `org.recompile.freej2me.Libretro`
  - Java class version: 50 (Java 6 compatible)
- `freej2me_plus_libretro.so`
  - SHA-256: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
  - ELF32 ARM EABI5, soft-float
  - Runtime dependencies: `libstdc++.so.6`, `libgcc_s.so.1`, `libc.so.0`

The binary files themselves are not committed here. Their hashes define the immutable device-proven reference.

## Golden architecture recovered from the binaries

### 1. Java-side video producer

`org.recompile.freej2me.Libretro` contains a dedicated `RG35XX-FrameWorker` and does not serialize the whole frame synchronously on the libretro command parser thread.

The working design includes:

- `rg35xxFrameSignal`
- `rg35xxFramePending`
- `rg35xxFrameWorkerRunning`
- `rg35xxFrameWorker`
- `rg35xxArgbSnapshot`
- `rg35xx565High[65536]`
- `rg35xx565Low[65536]`
- `rg35xxAsyncFrameHeader[16]`

The producer snapshots the Java frontbuffer under the frontbuffer lock, converts ARGB to RGB565 with lookup tables, and writes a complete frame transaction asynchronously.

This is intentionally different from a blocking `retro_run -> request -> read full frame` architecture.

### 2. Native video consumer

The golden core contains these concrete native owners:

- `rg35xx_video_receiver_main`
- `rg35xx_video_read_exact`
- `rg35xx_video_front`
- `rg35xx_video_back`
- `rg35xx_video_mutex`
- `rg35xx_video_generation`
- `rg35xx_presented_generation`
- `freej2me_present`

Observed diagnostics include:

- `RG35XX-VIDEO: receiver thread START`
- `RG35XX-VIDEO: invalid header %ux%u r=%d; resync`
- `RG35XX-VIDEO: RX frame ...`
- `RG35XX-VIDEO: receiver thread STOP`
- `RG35XX-VIDEO: SMART-FIT source=%ux%u -> %ux%u at %u,%u cached`

Therefore the clean rebuild must use a receiver-thread + validated front/back snapshot model. `retro_run()` must present the latest valid generation and must never block waiting for Java to produce a new frame.

### 3. Pixel format contract

Golden diagnostic contract:

`fixed=%ux%u RGB565 ... video=RXTHREAD-recovery ipc=RGB565-LUT`

Required invariant:

```text
Java ARGB frontbuffer
        -> snapshot
        -> RGB565 LUT conversion
        -> binary frame transaction
        -> native receiver thread
        -> validated back buffer
        -> atomic front/back publish
        -> libretro RGB565 presentation
```

Do not reintroduce an XRGB8888 device boundary on RG35XX.

### 4. Dynamic game view / smart fit

The golden native core has a `SMART-FIT source -> output` path. Source MIDlet dimensions and RG35XX output dimensions are separate concepts.

The new platform must therefore:

- keep the MIDlet logical LCD size authoritative for Java APIs;
- validate width/height in each frame transaction;
- fit/center the source frame into the RG35XX output surface in native code;
- never resize the Java logical LCD merely to match the physical screen;
- cache fit calculations until source geometry changes.

### 5. IPC integrity

The golden native side exposes `rg35xx_video_read_exact`. The clean rebuild must use exact-length reads for every framed payload and reject partial or impossible transactions.

Rules:

- exact 5-byte commands;
- exact variable payload reads;
- explicit maximum lengths;
- frame header validation before payload allocation/copy;
- width/height/rotation validation;
- payload length derived from validated geometry;
- incomplete frame discarded without replacing the last good frame;
- stdout remains binary IPC only.

### 6. Font path

The golden JAR contains a real embedded font bitmap resource:

- path: `/org/recompile/mobile/rg35xx-font.bin`
- size: 727008 bytes
- SHA-256: `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`

`PlatformGraphics` owns the renderer directly and includes:

- `rg35xxEnsureBitmapFont()`
- `rg35xxGlyphIndex(char)`
- `rg35xxWideChar(char)`
- `rg35xxBitmapScale()`
- `rg35xxBitmapWidth(String,int)`
- `rg35xxDrawBitmapString(...)`
- `rg35xxDrawSafeText(...)`

The working JAR therefore did **not** depend on the later 5x7 ASCII-only fallback as its normal game font path. The new platform must reproduce the golden Unicode/resource behavior first. A tiny ASCII fallback may exist only as a fail-safe.

### 7. Audio architecture

Golden native owners include:

- `rg35xx_audio_callback`
- `rg35xx_audio_worker`
- `rg35xx_audio_ring`
- `rg35xx_audio_mutex`
- `rg35xx_audio_cond`
- `rg35xx_async_audio_registered`
- MIDI worker/backend state

Observed diagnostics include underrun recovery, ring priming, SoundFont loading, MIDI playback, PCM replay, native END and BGM resume.

The clean rebuild must restore this asynchronous ring-buffer model. Audio production must not be hard-coupled to one fixed `735 samples per retro_run()` assumption.

### 8. Runtime paths proven by the baseline

Native strings prove the following paths/contracts:

- JamVM: `/mnt/mmc/CFW/java/bin/jamvm`
- runtime JAR: `freej2me-lr.jar`
- system/BIOS directory: `/mnt/mmc/BIOS`
- SoundFont: `/mnt/mmc/BIOS/freej2me.sf2`
- MIDI command bridge: `/mnt/mmc/BIOS/freej2me-midi.cmd`
- Java error log: `/mnt/mmc/freej2me-java-error.log`
- core log: `/mnt/mmc/freej2me-core.log`

JamVM is launched with headless AWT properties including:

- `-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit`
- `-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment`
- `-Djava.awt.headless=true`

### 9. Input

The golden Java runtime has an RG35XX-specific key resolver and direct numeric mappings before falling back to `Mobile.getMobileKey()`.

The rebuild must preserve device-proven key semantics, then layer repeat/debounce behavior on top without changing the base mapping.

## Clean rebuild policy

The current RC patch chain is not the architectural source of truth on this branch. The order of authority is:

1. real-device behavior of the two golden binaries;
2. structures, symbols, resources and paths recovered from those binaries;
3. the pinned upstream FreeJ2ME source used only as a clean source base;
4. later RC changes only when they do not contradict the golden behavior.

No subsystem is considered complete merely because a synthetic device test passes. A real game JAR must also boot, render, accept input and remain responsive.

## Rebuild stages

### G0 - Golden lock

- record immutable hashes and architecture;
- keep old RC main branch untouched;
- perform all rebuild work on `golden-clean-rebuild`.

### G1 - IPC + video baseline

Recreate the golden asynchronous Java frame worker, exact native receiver, RGB565 frame protocol, front/back snapshots and smart-fit presentation.

Acceptance: real game JAR must boot without RGB flashing, black-screen deadlock or forced reset.

### G2 - Golden font baseline

Restore the resource-driven Unicode bitmap font behavior and matching MIDP metrics. Remove the 5x7 fallback from the normal render path.

Acceptance: lowercase, punctuation, accented/Unicode samples and real-game HUD/menu text match the golden binary behavior.

### G3 - Golden audio baseline

Restore asynchronous audio callback + worker + ring buffering, native MIDI/PCM completion and underrun recovery.

Acceptance: no crackle caused by render cadence, no media hard hang, END_OF_MEDIA correct.

### G4 - Runtime/lifecycle/RMS/input

Port only the lifecycle, RMS and input fixes that preserve golden behavior. Remove duplicate owners and patch-era compatibility layers.

### G5 - Optimization

Optimize only after correctness:

- reuse buffers;
- avoid per-frame allocation;
- cache smart-fit geometry;
- cache transform/image data;
- dirty generation scheduling where it cannot stall animation;
- bounded logging on release builds.

### G6 - Device package

Build ARMv5TE/uClibc, package with the proven RG35XX paths, verify hashes, then test synthetic suite **and at least one real game JAR** before calling the new platform stable.
