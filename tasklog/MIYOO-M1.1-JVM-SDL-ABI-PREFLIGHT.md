# MIYOO M1.1 JVM + SDL ABI BOOTSTRAP — PREFLIGHT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1

## Mandatory historical-first report

- CURRENT_SYMPTOM: Current R2.x platform remains not STABLE and has accumulated interacting Libretro/JamVM/audio/video compatibility layers. M1 device audit completed successfully and shows original RG35XX is ARMv7 (Cortex-A9 class), uClibc 1.0.28, ~232 MiB visible RAM, with system SDL2 2.0.8 but no SDL2_mixer and only JamVM Java 1.5.
- HISTORY_FOUND: YES. Tasklogs confirm JamVM L, GNU Classpath baseline, NoMask and several video/audio pieces have real-device evidence, but the whole current reconstruction is not STABLE. Historical clean rebuild rules require new work to remain isolated and fail-closed.
- PREVIOUS_FIX: Existing platform uses Libretro + IPC + JamVM + worker/ring audio. Miyoo references instead use standalone SDL2 and SDL2_mixer with a modern JVM. No historical DEVICE-PASS exists for a Miyoo-style standalone build on original RG35XX.
- PREVIOUS_EVIDENCE_LEVEL: Current JamVM binary is DEVICE-PROVEN only for the existing Java 1.5 platform. System SDL2 presence is DEVICE-EVIDENCE from the M1 audit; actual SDL2 initialization by our own standalone binary is not yet proven.
- REGRESSION_RISK: Replacing current Java files, linking Miyoo hard-float/glibc binaries, or changing audio/video/JVM simultaneously would violate project rules and could destroy the known fallback platform.
- MINIMAL_PROPOSED_CHANGE: Build one standalone native ABI probe only. It links only against the proven uClibc toolchain/libdl and dynamically loads the device's existing libSDL2-2.0.so.0 at runtime. It does not install or replace Java, Libretro, audio, video or fonts. In parallel, record that Miyoo Java source cannot be a drop-in on JamVM 1.5 because it uses java.nio.file/java.util.function.
- EXPECTED_DEVICE_TEST: Run the probe from GarlicOS Apps. It must start as an ELF executable, dlopen system SDL2, report SDL version and available video/audio drivers, call SDL_Init(0), and exit normally. The wrapper also records readelf/file/ldd-style evidence when available. No game is launched and current platform hashes must remain unchanged.

## M1 device evidence incorporated

- Kernel: Linux 3.10.37 armv7l
- CPU features: ARMv7, NEON, VFPv3
- libc: uClibc 1.0.28
- Memory: 237624 kB total, no swap
- JVM: JamVM 2.0.0 reporting Java 1.5.0
- SDL2: /usr/lib/libSDL2-2.0.so.0.8.0
- SDL2_mixer: NOT FOUND; only SDL_mixer 1.2 exists
- Current platform fallback hashes remain locked and must not be modified.

## M1.1 scope lock

Primary variable: native standalone SDL2 ABI compatibility only.

MUST NOT:
- replace /mnt/mmc/BIOS/freej2me-lr.jar
- replace freej2me_plus_libretro.so
- replace JamVM or glibj.zip
- import R2.x audio/video/font patches
- bundle SDL2_mixer yet
- launch any JAR yet
- claim DEVICE-PASS/STABLE from CI

## JVM direction

M1.1 does not select a new JVM yet. It records two candidate strategies for later A/B evaluation:

A. Modern JVM compatible with ARMv7/uClibc and <=256 MiB budget.
B. Backport the minimum Miyoo FreeJ2ME Java source away from modern java.nio.file/java.util.function APIs so the existing DEVICE-PROVEN JamVM/GNU Classpath baseline can be reused.

Neither strategy is admitted until the SDL standalone ABI gate passes on device.

## Status before implementation

SOURCE-PINS: LOCKED
DEVICE-INVENTORY: DEVICE-EVIDENCE
SDL2_LIBRARY_PRESENT: DEVICE-EVIDENCE
SDL2_STANDALONE_INIT: DEVICE-TEST-PENDING
JVM_STRATEGY: UNVERIFIED
BUILD-PASS: NO
DEVICE-PASS: NO
STABLE: NO
