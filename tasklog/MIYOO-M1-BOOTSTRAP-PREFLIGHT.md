# MIYOO M1 BOOTSTRAP — PREFLIGHT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1

## Mandatory historical-first report

- CURRENT_SYMPTOM: The current RG35XX Libretro/JamVM platform has accumulated multiple compatibility layers and still shows intermittent audio/ring anomalies and prior hard-hang reports. R2.3 localized no persistent worker/video deadlock in the latest long KDTT run, but the overall platform remains not STABLE.
- HISTORY_FOUND: YES. Existing tasklogs show device-proven pieces (JamVM L, Lazy Media, Golden video transport, NoMask green-tint fix, worker-ring audio architecture) but no single current reconstruction has reached STABLE.
- PREVIOUS_FIX: Incremental reconstruction through R2.x: async worker-ring audio, file-backed MIDI, bounded diagnostics, Golden-style video transport, bitmap-font bypass.
- PREVIOUS_EVIDENCE_LEVEL: Several subsystems have DEVICE-EVIDENCE; the whole current platform is not DEVICE-PASS/STABLE.
- REGRESSION_RISK: Continuing to stack patches on the existing Libretro/JamVM bridge increases interaction risk. Reusing Miyoo ARMv7/hard-float binaries directly on original RG35XX is unsafe and forbidden.
- MINIMAL_PROPOSED_CHANGE: Create a completely separate Miyoo-derived standalone platform branch. First checkpoint M1 is inventory/bootstrap only: verify original RG35XX runtime ABI, libc, SDL2/SDL2_mixer availability and usable JVM options before compiling or installing a new runtime.
- EXPECTED_DEVICE_TEST: A read-only device audit must report CPU/ABI/libc, available SDL libraries/drivers, JVM candidates and memory. Only after the report is reviewed may M1 compile a standalone SDL bootstrap.

## Source references

Primary upstream candidate:
- aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

Audio/lifecycle reference:
- bqcuong/miyoo-j2me (main; exact pin to be locked before build)

## Scope lock

M1 MUST NOT import current R2.x runtime patches into the Miyoo build. No Libretro core, no RG35XX audio pipe, no worker-ring, no Golden video IPC, no reconstructed font, no NoMask, no VC6/VC7 overlays.

M1 phase order:
1. Device ABI/JVM/SDL inventory (read-only).
2. Lock exact Miyoo source pins.
3. Cross-build a minimal standalone SDL frontend for original RG35XX ABI.
4. Boot one simple JAR.
5. Only then test KDTT / Real Football / Ninja School.

## Known incompatibilities that must be resolved before build

- Miyoo Mini build flags currently target Cortex-A7 / ARMv7VE / NEON / hard-float.
- Original RG35XX project toolchain currently targets arm-miyoo-linux-uclibcgnueabi / ARMv5TE-compatible / soft-float.
- Miyoo Java source uses modern Java APIs and the reference projects expect JDK 17.
- Miyoo SDL audio path links SDL2 + SDL2_mixer directly; availability/ABI on original RG35XX must be proven first.

## Status

SOURCE-AUDIT: PASS
DEVICE-INVENTORY: PENDING
BUILD-PASS: NO
DEVICE-PASS: NO
STABLE: NO
