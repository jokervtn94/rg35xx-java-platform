# RG35XX Java Platform

Optimized Java ME / J2ME runtime platform for the original Anbernic RG35XX running GarlicOS 1.x.

## Project goal

Build a stable, compatible and efficient Java ME platform specifically for the original RG35XX (Actions ATM7059A), using FreeJ2ME Plus as the compatibility base, JamVM + GNU Classpath on uClibc, and a libretro frontend integration optimized for the device.

The project is developed from static analysis of real Java ME game JARs plus controlled device testing. Game JARs are reference/compatibility inputs and are not distributed by this repository.

## Target

- Device: Anbernic RG35XX Original
- SoC: Actions ATM7059A / Cortex-A9 platform
- Firmware: GarlicOS 1.x
- ABI: ARM32 EABI5, soft-float
- libc: uClibc
- JVM: JamVM 2.0.0
- Class library: GNU Classpath 0.99
- Frontend: RetroArch/libretro
- Video: fixed 640x480 RGB565 frontend, SMART-FIT aspect-preserving presentation
- Java/native video IPC: RGB565
- Audio: asynchronous native worker/ring/libretro callback

## Development principles

1. Do not optimize by repeatedly patching and testing one symptom at a time.
2. Audit real game JAR API/package/resource usage before changing platform semantics.
3. Keep Java/native IPC stable unless a protocol change has a documented reason and rollback path.
4. Keep platform responsibilities in dedicated RG35XX classes; reduce business logic in Libretro.java and PlatformPlayer.java.
5. Every ADD/MODIFY/REMOVE/DISABLE/REPLACE decision receives a Task ID.
6. Never erase Tasklog history. Reverts are new tasks.
7. Game JARs are never committed; only compatibility reports/hashes/metadata may be stored.
8. Build/device testing begins after a stage is statically audited, not after every small patch.

## Current Platform 1.0 roadmap

- Alpha 1: platform profile + dirty frame scheduler
- Beta 1: image cache, deterministic input engine, WAV decoder/media profile, runtime stats
- Beta 2: JAR compatibility baseline + unified font metrics/rendering engine
- Beta 3: Media Engine 2.0 / player registry / mixer capability truth
- Beta 4: optimized graphics paths
- Beta 5: RMS/storage backend
- RC: full static audit, compatibility matrix, rollback map and RG35XX device test matrix

## Stable compatibility foundations retained

- Headless AWT; no GTK/X11 dependency
- PNG indexed-palette tRNS alpha repair
- fixed 640x480 RGB565 frontend
- aspect-preserving SMART-FIT
- RGB565 Java/native IPC
- native video receiver pthread/double buffer
- asynchronous native audio architecture
- native MIDI END_OF_MEDIA command path
- direct numeric keypad mapping
- stdout reserved for binary Java/native protocol
- Manager.prepareMediaEngine() remains disabled on the libretro path

## Repository policy

This repository does not contain commercial game JARs, ROMs, proprietary game assets, BIOS files, SoundFonts, or the RG35XX runtime binaries. Compatibility work is documented using API/resource inventories and non-content metadata.

See `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `compatibility/BASELINE.md`, and `tasklog/TASKLOG.md` for the engineering record.
