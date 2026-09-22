# RG35XX Device-Pass Rebuild v1

Branch: `rg35xx-device-pass-rebuild-v1`
Architecture: Miyoo-derived STANDALONE only
Full platform status: `STABLE=NO`

## Mandatory preflight

CURRENT_SYMPTOM:
Historical RC/VC/R2/standalone build families were mixed, repeatedly reintroducing already-fixed display, input, font, audio and freeze regressions.

HISTORY_FOUND:
YES. The clean rebuild is grounded in the locked real-device checkpoints M1.6, M1.7, M1.8, M1.9E, M1.9F, M1.10, M1.14 scoped font semantics, M1.15-r1, M1.15-r1.1 and M1.16-r1.2.

PREVIOUS_FIX:
Use fresh FreeJ2ME-Plus at pin `13ec186903087156c145268f8706eecfaf9f1e50`, preserve JamVM L and immutable glibj, use SDL1/fbcon and raw /dev/input/js0 ownership, then apply only the patch/helper allowlist proven by the standalone checkpoints.

PREVIOUS_EVIDENCE_LEVEL:
- M1.6 display: DEVICE-PASS
- M1.7 raw js0: DEVICE-PASS
- M1.8 input dispatch: DEVICE-PASS
- M1.9E SDL1 presenter: DEVICE-PASS
- M1.9F Canvas E2E: DEVICE-PASS
- M1.10 GameCanvas E2E: DEVICE-PASS
- M1.14 font semantics: DEVICE-PASS scoped; resource EXPERIMENTAL_NOT_GOLDEN
- M1.15-r1 RMS lifecycle: DEVICE-PASS scoped
- M1.15-r1.1 RMS persistence: DEVICE-PASS scoped
- M1.16-r1.2 blank PlatformImage dimensions: DEVICE-PASS scoped

REGRESSION_RISK:
HIGH if Libretro/R2/VC7, SDL2, JavaSound media, MediaWarmup, unbounded hot-path logging, GNU Classpath byte patches, transform-cache experiments or unverified font resources are imported.

MINIMAL_PROPOSED_CHANGE:
No new runtime semantics. Rebuild one consolidated standalone foundation from the pinned upstream plus the exact locked historical patch/helper snapshot. The consolidation itself is a new assembly and therefore remains DEVICE-TEST-PENDING until real RG35XX regression testing.

EXPECTED_DEVICE_TEST:
Re-run the affected locked boundaries on original RG35XX: Canvas, GameCanvas, 36-font matrix, RMS lifecycle, RMS cross-process/reboot persistence and blank PlatformImage dimensions; confirm normal exit/no hard reset and protected JamVM/glibj hashes unchanged.

## Project separation

### Project A — STANDALONE FOUNDATION (active)
Ownership:
`JamVM -> GNU Classpath -> FreeJ2ME -> /dev/input/js0 JNI -> MIDP -> Java ARGB -> SDL1/fbcon -> physical LCD`

This branch is the only active clean source foundation.

### Project B — LIBRETRO / R2 / VC7 (reference only)
May be consulted for historical contracts such as RGB565, Smart-Fit, PNG iCCP and worker-ring audio, but no code or DEVICE-PASS claim crosses into Project A without a new isolated RG35XX device checkpoint.

### Project C — COMPATIBILITY EXTENSIONS (later)
Sprite/TiledLayer/LayerManager, audio, transparency, dynamic dimensions beyond proven tests and commercial game regression. Each is a separate checkpoint.

## External Miyoo reference policy

Miyoo handheld FreeJ2ME repositories are useful as architectural/behavior references, especially for handheld lifecycle, input and avoiding desktop-only assumptions. Modern variants commonly use SDL2 and newer JDKs, so they are not binary/drop-in baselines for the original RG35XX. The original RG35XX real-device evidence in this repository keeps SDL1/fbcon as the display backend.

## Protected identities

- FreeJ2ME pin: `13ec186903087156c145268f8706eecfaf9f1e50`
- Upstream tree: `ad47ab16e9025f0eb3d2067bc3b1897dc71987df`
- Toolchain: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj.zip: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- Locked standalone source snapshot used only to materialize proven patches/helpers: `faa49f9b941db5394265d9b13413e4576ef4694f`

## Classification

This branch may reach BUILD-PASS in CI. It MUST NOT be called DEVICE-PASS or STABLE until the consolidated artifact is tested on the original RG35XX.
