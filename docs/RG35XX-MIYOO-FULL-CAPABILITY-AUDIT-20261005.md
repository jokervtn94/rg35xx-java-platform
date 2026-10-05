# RG35XX Miyoo Full Capability Audit — 2026-10-05

## Status

```text
AUDIT_DESIGN=PASS
HOST_BUILD=IN_PROGRESS
ORIGINAL_RG35XX_PHYSICAL=NOT_TESTED
MODULE_DECISIONS=PARTIAL
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

Branch:

```text
audit/rg35xx-miyoo-capability-20261005
```

Audit parent checkpoint:

```text
4fab682c15b4944b0d87952e164190a8bd784a30
```

Canonical Miyoo/Aweigit pin:

```text
ca11dfe8ea1cc273d92460f9a83bbf192023fa63
```

## Purpose

Before continuing the full Miyoo port, measure what the original RG35XX / GarlicOS platform actually exposes and then map those measured capabilities to the pinned Miyoo source requirements.

This audit is deliberately broader than the previous P4 3D probe. It must answer platform-substrate questions once so later port decisions can reuse the same evidence instead of creating a new physical package for each class or module.

The audit is diagnostic only:

```text
RUNTIME_SEMANTIC_DELTA=NONE
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
DEVICE_PASS=NO
STABLE=NO
```

## Pinned Miyoo source requirements already established

From the exact pinned Miyoo source:

- Java package groups include MIDP IO, LCDUI, M3G, media, MIDlet, PIM, PKI, RMS and Sensor APIs.
- Vendor groups include MascotCapsule, Nokia, Samsung and Siemens APIs.
- `org.lwjgl` is present.
- the Miyoo native frontend is SDL2 + pthread;
- the Miyoo audio JNI library links SDL2 + SDL2_mixer;
- M3G ARM32 links EGL + GLES1 + zlib;
- MascotCapsule/Micro3D ARM32 links EGL + GLES2;
- Miyoo ARM32 native build flags assume an ARMv7 hard-float/NEON-style target.

These are requirements of the pinned source, not proof that original RG35XX provides the same substrate.

## Existing accepted RG35XX evidence that must not be needlessly repeated

The current project already has accepted physical evidence for:

```text
P1_CORE_2D=PASS
P2_IMAGE_FONT_FRONTEND=PASS
P3_RUNTIME_SERVICES=PASS
```

Therefore the full capability audit does not initialize SDL video or SDL audio merely to repeat accepted physical behavior. It inventories those providers and preserves the accepted RG35XX boundary evidence.

The unresolved 3D capability remains different: the existing P4 EGL/GLES inventory/context/platform probes are included and reused inside this one audit package.

## Evidence levels

A capability must be recorded at the strongest level actually proven:

```text
PRESENT
  A file, class, device node or sysfs provider exists.

LOADABLE
  A native provider can be dlopen'd and required symbols are visible.

ACTIVE_PASS
  A controlled local operation succeeds on the original device.

REVIEW_REQUIRED
  Pinned Miyoo source requirements still have to be mapped to the measured provider.
```

`PRESENT` or `LOADABLE` alone is never permission to enable a module.

## Probe coverage

The single launcher collects:

1. kernel / OS / CPU / ABI / memory / mounts;
2. framebuffer, input, audio, GPU, Bluetooth, sensor and related device nodes/sysfs;
3. SDL1, SDL2, SDL_mixer, EGL, GLES1, GLES2, OpenGL-related, zlib, PNG, JPEG, FreeType, ALSA, Bluetooth, OpenSSL and C++ runtime providers;
4. JamVM / glibj / protected runtime identities and selected class-library availability;
5. safe active native tests for pthread, mmap/mprotect, SD filesystem operations, TCP/UDP loopback and `localhost` resolver support;
6. dlopen/dlsym checks for the providers above;
7. the existing P4 EGL/GLES provider, context and platform/device probes;
8. network interface/route/resolver inventory without contacting an external host.

## Preliminary module map before physical evidence

| Miyoo area | Current RG35XX position | Next decision evidence |
|---|---|---|
| MIDlet/core Java semantics | preserve pinned Miyoo semantics | JamVM/glibj substrate + source mapping |
| LCDUI/Canvas/GameCanvas/Core2D | accepted RG35XX P1/P2 boundary exists | preserve accepted evidence; no broad rewrite |
| Image/font/text | accepted RG35XX P2 evidence exists | preserve unless exact regression proves otherwise |
| Physical input/frontend | accepted RG35XX P2 boundary exists | preserve RG35XX acquisition/mapping boundary |
| RMS/FileConnection | accepted RG35XX P3 evidence exists | preserve semantics; active FS probe is supplementary |
| MMAPI/audio | accepted RG35XX P3 audible boundary exists | preserve; Miyoo SDL2 audio JNI is not assumed reusable as-is |
| IO/network | unresolved full support level | loopback sockets/DNS + exact Connector source audit |
| PKI/TLS | unresolved | glibj classes + native crypto provider + exact source audit |
| Bluetooth/JSR-82 | unresolved | device/sysfs + libbluetooth + exact source audit |
| Sensor/JSR-256 | unresolved | input/IIO/sysfs + exact source audit |
| PIM | unresolved | exact source/provider audit; generic filesystem is not enough |
| M3G/JSR-184 | deferred capability | EGL + GLES1 + zlib + active P4 context + pinned native call mapping |
| MascotCapsule/Micro3D | deferred capability | EGL + GLES2 + active P4 context + pinned native call mapping |
| LWJGL/OpenGL | deferred capability | provider/API/ABI mapping; no blind re-enable |
| Nokia/Samsung/Siemens vendor APIs | preserve canonical portions | source audit; only measured hardware-dependent calls may adapt |

## Physical package

One SD package:

```text
RG35XX-MIYOO-CAPABILITY-AUDIT.zip
```

One launcher:

```text
/mnt/mmc/Roms/APPS/RG35XX-MIYOO-CAPABILITY-AUDIT.sh
```

One evidence directory:

```text
/mnt/mmc/RG35XX-MIYOO-CAPABILITY-AUDIT-EVIDENCE/
```

Expected evidence files:

```text
00-SUMMARY.log
10-SYSTEM.log
20-DEVICE-NODES.log
30-LIBRARIES.log
40-JAVA-RUNTIME.log
50-NATIVE-ACTIVE.log
60-P4-WRAPPER.log
61-P4-CAPABILITY-DECISION.log
62-P4-EGL-GLES-PROBE.log
63-P4-EGL-GLES-CONTEXT.log
64-P4-EGL-PLATFORM.log
70-NETWORK.log
MIYOO-REQUIREMENTS.tsv
```

## Decision output after original-RG35XX evidence

Each Miyoo module will be classified independently as one of:

```text
KEEP_MIYOO_AS_IS
KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY
NEEDS_MINIMUM_RG35XX_BOUNDARY
DEFER_CAPABILITY
NEEDS_SOURCE_MAPPING
```

Only an exact measured gap may enter `NEEDS_MINIMUM_RG35XX_BOUNDARY`.

After the matrix is complete, the next integration candidate should assemble the full port from the pinned Miyoo lineage plus only the proven RG35XX boundaries. This audit is intended to reduce later physical-test cycles, not add another development phase per method.
