# G1 — Golden Video / IPC Contract

This document is the source-level reconstruction target for the device-proven RG35XX binaries recorded in `GOLDEN-RG35XX-BASELINE.md`.

## Scope

G1 owns only:

- Java -> native frame transport;
- frame validation and recovery;
- RGB565 device boundary;
- dynamic source geometry / smart fit;
- non-blocking libretro presentation;
- boot/restart behavior needed to keep video IPC recoverable.

Font, audio, RMS and higher-level lifecycle remain separate stages.

## Java producer recovered from the golden JAR

The device-proven `org.recompile.freej2me.Libretro` has these concrete fields/owners:

```text
byte[] frameBuffer                 = 1,280,000 bytes
int[]  rg35xxArgbSnapshot          =   640,000 ints
Object rg35xxFrameSignal
volatile boolean rg35xxFramePending
volatile boolean rg35xxFrameWorkerRunning
Thread rg35xxFrameWorker           = "RG35XX-FrameWorker"
byte[] rg35xxAsyncFrameHeader      = 16 bytes
byte[] rg35xx565High               = 65,536 bytes
byte[] rg35xx565Low                = 65,536 bytes
```

The worker is daemon + minimum priority. `rg35xxRequestFrameAsync()` only coalesces requests by setting one pending flag and notifying the worker. The libretro command parser never serializes the frame itself.

### RGB565 LUT

For each 16-bit half of an ARGB pixel:

```text
high[idx] = ((idx >> 8) & 0xF8) | ((idx >> 5) & 0x07)
low[idx]  = ((idx >> 5) & 0xE0) | ((idx >> 3) & 0x1F)
```

For an ARGB/XRGB int `p`, the wire bytes are:

```text
frameBuffer[o++] = rg35xx565High[(p >>> 8) & 0xFFFF]
frameBuffer[o++] = rg35xx565Low[p & 0xFFFF]
```

The golden implementation converts eight pixels per unrolled loop iteration and handles the tail separately. No per-frame allocation is allowed.

## Snapshot ownership

Before conversion, Java copies the current `lcdData[]` into `rg35xxArgbSnapshot[]` while synchronized on the current LCD frontbuffer object.

Required checks before snapshot/serialization:

- `pixelCount > 0`;
- `pixelCount <= rg35xxArgbSnapshot.length`;
- logical width/height match the snapshot generation being serialized;
- output payload length is exactly `pixelCount * 2`.

The worker then converts the private snapshot without holding the frontbuffer lock.

## Frame transaction

The golden Java frame header is exactly 16 bytes:

```text
[0]     = 0xFE
[1..2]  = source width, big-endian
[3..4]  = source height, big-endian
[5]     = rotation quarter-turn (0..3)
[6..9]  = vibration duration, big-endian int
[10..13]= vibration strength, big-endian int
[14]    = restart requested
[15]    = encoding requested
```

Immediately after the 16-byte header Java writes exactly:

```text
sourceWidth * sourceHeight * 2
```

RGB565 bytes, then flushes. Header + payload writes are synchronized on the preserved binary IPC `PrintStream` so no other producer can interleave bytes.

`System.out` must not be used for diagnostics. The golden JAR preserves the original stdout as a private `ipcOut` and replaces normal `System.out` with a sink.

## Command parser contract

Commands from native to Java retain the existing 5-byte command envelope:

```text
byte 0   command id
byte 1-4 big-endian argument/code
```

Any variable-length payload following that envelope must be read to its exact declared length. A single `InputStream.read(byte[])` is not a complete transaction contract.

Clean implementation requirement:

```text
readFully(input, buffer, 0, declaredLength)
```

with explicit maximum sizes and EOF/error handling. Partial payloads must terminate/recover the command transaction, never leak remaining payload bytes into the next 5-byte command.

## Native receiver recovered from the golden core

The core contains:

```text
rg35xx_video_read_exact
rg35xx_video_receiver_main
rg35xx_video_front
rg35xx_video_back
rg35xx_video_mutex
rg35xx_video_generation
rg35xx_presented_generation
freej2me_present
```

`rg35xx_video_read_exact(fd, dst, len)` loops until all bytes are read, tolerates EINTR/EAGAIN using bounded poll waits while the receiver remains active, returns failure on pipe termination/error, and never publishes a partial transaction.

### Receiver algorithm

The clean source implementation must behave as follows:

1. receiver thread owns all reads from Java video stdout after startup handshake;
2. scan/resync until `0xFE` is found;
3. exact-read remaining 15 header bytes;
4. decode and validate width, height, rotation;
5. require width/height > 0 and inside the fixed maximum surface contract;
6. derive payload bytes only after geometry validation;
7. exact-read the complete RGB565 payload into the back buffer;
8. under `rg35xx_video_mutex`, publish metadata and swap front/back;
9. increment `rg35xx_video_generation` only after a complete valid frame;
10. invalid/truncated frames never replace the last good front buffer.

The golden binary explicitly logs invalid headers and resynchronizes instead of killing the frontend.

## `retro_run()` presentation contract

`retro_run()` must never block waiting for a Java frame.

It may:

- poll input;
- send/coalesce a frame request to Java;
- run other bounded frontend work;
- call `freej2me_present()` using the newest published video generation.

If no new generation exists, it presents/retains the previous valid image. A stalled MIDlet is not allowed to stall RetroArch/frontend control.

## Dynamic viewport / Smart Fit

The logical MIDlet LCD and RG35XX output surface are separate.

Golden core diagnostic:

```text
RG35XX-VIDEO: SMART-FIT source=%ux%u -> %ux%u at %u,%u cached
```

Required rules:

- Java owns the source logical LCD size.
- Native owns physical output fitting.
- Preserve aspect ratio.
- Fit inside the fixed output surface; never crop accidentally.
- Center the result.
- Cache scaling geometry until source width/height/rotation changes.
- Clear unused output pixels deterministically (black) when geometry changes.
- Do not resize the Java MIDlet merely to match the physical RG35XX panel.

## G1 failure handling

A malformed frame may produce a diagnostic, but must not:

- publish partially converted pixels;
- change front-buffer generation;
- change source geometry;
- block `retro_run()`;
- kill JamVM immediately;
- require a hard reset to return to the frontend.

## G1 acceptance

G1 is not accepted by a synthetic test alone. All must pass:

1. Golden binary audit still passes.
2. New source build is Java 6 / ARM EABI5 soft-float compatible.
3. RGB565 boundary is reported/used.
4. Java frame worker and native receiver thread are present.
5. Exact-read contract is present on both variable command payloads and video frames.
6. A real game JAR boots without RGB flashing.
7. A real game JAR does not black-screen/hard-hang during boot or view changes.
8. Source game viewport is correctly fit/centered.
9. Frontend remains responsive if Java stops producing new frames temporarily.
10. Repeated start/exit cycles do not require a device reset.
