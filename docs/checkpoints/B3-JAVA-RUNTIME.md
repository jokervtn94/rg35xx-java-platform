# B3 — Verified Clean Java Runtime

Status: `SOURCE/GATE COMMITTED — BUILD/DEVICE ACCEPTANCE PENDING`

## Purpose

B3 rebuilds the Java runtime from pinned FreeJ2ME upstream while admitting only behavior already supported by RG35XX device evidence.

## Pinned source

- FreeJ2ME upstream: `13ec186903087156c145268f8706eecfaf9f1e50`
- Java compatibility target: class major 50.

## Admitted Java changes

1. Lazy media boot in `MobilePlatform.runJar()`:
   - `loader.start()` is the boot path.
   - no eager `Manager.prepareMediaEngine()`.
   - no `RG35XX-MediaWarmup` background prewarm.
2. `org.recompile.freej2me.RG35XXGoldenFrameTransport`:
   - non-daemon frame worker;
   - snapshots the Java framebuffer;
   - converts ARGB to RGB565;
   - writes exact framed binary transactions to preserved IPC stdout.
3. `Libretro` integration requests frames asynchronously through the Golden transport.

## Explicit exclusions

B3 must fail if any of these reappear:
- PNG ICC compatibility experiments;
- `rg35xxStripPngICCP`;
- CV/CW resolution launcher code;
- media warmup thread;
- PlatformImage RG35XX compatibility code;
- font rework;
- audio rework;
- lifecycle/Beta helpers not separately admitted.

## Reproducible gate

Run after clean VC0-VC3 assembly and `ant` build:

```sh
B3_ASSEMBLY=/path/to/assembly sh scripts/b3_verified_runtime_gate.sh
```

The gate verifies class major 50, lazy boot semantics, Golden asynchronous frame transport, negative experiment markers, JAR contents, and writes `b3-evidence/` with `STATUS.txt` and a SHA256 manifest that deliberately excludes the manifest itself.

## Acceptance rule

A successful CI/build gate changes B3 only to `BUILD-PASS`. It must not be called stable or device-pass until installed as part of the clean foundation and accepted on real RG35XX hardware without per-game patching.
