# RG35XX Miyoo Capability Device Analysis — 2026-10-05

## Scope and evidence identity

This document classifies the pinned Miyoo/Aweigit modules against one original-RG35XX capability audit run.

```text
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
AUDIT_BRANCH=audit/rg35xx-miyoo-capability-20261005
EVIDENCE_ZIP_SHA256=167dd113cba1cb88d2a664bfaaf22c8e1d8e5fcb911b33d764f75596196bfb4c
CAPABILITY_AUDIT_PHYSICAL=PASS
RUNTIME_SEMANTIC_DELTA=NONE
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

This is a capability/port-planning result, not baseline promotion.

## Measured original-RG35XX substrate

### CPU / ABI

Measured device:

```text
Linux 3.10.37
Buildroot 2018.02
armv7l
CPU part 0xc09 = Cortex-A9 family
32-bit little endian
NEON present
VFPv3 present
4 CPU cores
~232 MiB RAM usable
```

The pinned Miyoo ARM32 makefiles are built around Cortex-A7 / ARMv7VE / NEON-VFPv4 hard-float style flags. Therefore Miyoo ARM32 native binaries are not treated as reusable binary artifacts on the original RG35XX. Native code may remain source-lineage-compatible, but it must be compiled for the exact RG35XX ABI/toolchain and only when the required backend exists.

### Display / input

Measured:

```text
/dev/fb0=present/readable/writable
fb driver=owlfb
virtual_size=640,960
bpp=32
stride=2560
/dev/input/js0=present
RG35XX Gamepad=present
/dev/input/event1=present
```

This agrees with the existing accepted RG35XX framebuffer/input boundary. It is not evidence to replace that accepted boundary with the Miyoo SDL2 frontend.

### Audio

Measured:

```text
ALSA device nodes=present
libasound=loadable + required symbols PASS
SDL_mixer 1.2=loadable + required symbols PASS
SDL2=loadable
SDL2_mixer=NOT_FOUND_OR_UNLOADABLE
```

Pinned Miyoo `libaudio.so` links SDL2 + SDL2_mixer. Therefore the Miyoo audio native backend cannot be used as-is against the measured RG35XX system libraries. The already accepted RG35XX SDL1_mixer audio boundary remains the correct production owner unless later exact evidence invalidates it.

### Filesystem / native process substrate

Measured active operations:

```text
pthread create/join=PASS
mmap RW=PASS
mprotect RX=PASS
SD create/write/fsync/rename/read/delete=PASS
TCP socket=PASS
UDP socket=PASS
loopback listen=PASS
getaddrinfo(localhost)=PASS
```

This is sufficient hardware/OS substrate for the existing RMS/FileConnection boundary and for preserving canonical socket logic where the Java class library supports it.

### Network availability

Measured current network state:

```text
lo=UP
no external network interface recorded
no default route
/etc/resolv.conf=absent
```

Kernel socket capability exists, but the audit does not establish external Internet connectivity on the original RG35XX. Do not add game/network-specific workarounds. Keep canonical protocol code and classify external networking as device capability dependent.

### Graphics/3D provider inventory

Present and loadable:

```text
libEGL
libGLESv1_CM
libGLESv2
libGL
zlib
```

Required EGL/GLES symbols are visible. However active EGL initialization fails:

```text
eglGetDisplay(default)=NON_NULL
eglInitialize(default)=FAIL EGL_NOT_INITIALIZED (0x3001)
GBM display=NON_NULL
eglInitialize(GBM)=FAIL EGL_NOT_INITIALIZED (0x3001)
/dev/dri/card0=absent
/dev/mali=absent
/dev/ump=absent
/dev/gpu=absent
EGL_EXT_platform_device=absent
```

Pinned Miyoo M3G and Micro3D native code uses either `eglGetDisplay(EGL_DEFAULT_DISPLAY)` or, under `USE_GBM`, `/dev/dri/card0` + GBM. Both measured routes are unavailable as working contexts on the original RG35XX in this audit. Library presence alone is therefore not enough to enable 3D.

### Optional hardware

Measured:

```text
/sys/class/bluetooth directory exists but has no device entries
/sys/class/rfkill directory exists but has no entries
libbluetooth=NOT_FOUND_OR_UNLOADABLE
/sys/bus/iio/devices exists but contains no sensor devices
```

The ALSA `BLUETOOTH PCM` DAI is not proof of a usable Bluetooth controller/JSR-82 stack.

## Java-probe limitation

`40-JAVA-RUNTIME.log` reports `java` and `jamvm` not found in the launcher's PATH and did not locate glibj. This is a probe-environment limitation, not evidence that Java is absent: accepted P1-P3 physical runs already prove the protected Java runtime executes on the device.

Do not repeat P1-P3 physical tests because of this audit-path issue. Java-class-specific unknowns such as JSSE/TLS should be resolved from the protected runtime image/source or during the later full-platform integration gate.

## Pinned source notes used in classification

- `Connector` delegates schemes through MicroEmu `ImplFactory` / `ConnectorImpl`; the pinned tree contains `datagram`, `file`, `http`, `https`, `resource`, `sms`, `socket`, and `ssl` protocol implementations.
- Pinned HTTPS uses Java `javax.net.ssl.SSLContext` / `HttpsURLConnection`; absence of native OpenSSL alone is not a valid reason to remove HTTPS.
- PIM is explicitly stubbed by the pinned source (`PIM.getInstance()` throws a SecurityException stating PIM is stubbed).
- M3G and Micro3D use EGL default-display or optional GBM routes as described above.

## Module decision matrix

| Miyoo module/area | Device result | Port decision | Production action |
|---|---|---|---|
| CORE JVM / MIDlet semantics | Existing accepted runtime; audit Java PATH incomplete | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Preserve protected JamVM/glibj and pinned semantics |
| LCDUI / Canvas / GameCanvas / Core2D | Existing P1/P2 physical PASS; framebuffer present | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Keep accepted Raw2D/video boundary; no broad rewrite |
| Image decode / transform | Existing P2 PASS; PNG/JPEG/zlib providers present | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Preserve accepted implementation |
| Font / text | Existing P2 PASS; FreeType/SDL_ttf providers present | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Preserve accepted implementation |
| Input / key semantics | `/dev/input/js0` + gamepad present; P2 PASS | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Keep J2ME key semantics; RG35XX hardware acquisition only |
| RMS / FileConnection | active filesystem PASS; P3 PASS | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Preserve semantics and device path boundary |
| MMAPI / audio | ALSA + SDL1_mixer available; SDL2_mixer absent; P3 audible PASS | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Keep RG35XX SDL1_mixer bridge; do not restore Miyoo SDL2_mixer backend blindly |
| SDL2 Miyoo frontend | SDL2 library/symbols loadable; actual frontend display path not proven; accepted RG35XX frontend exists | `KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY` | Do not replace accepted SDL1/fbcon/input boundary merely because SDL2 exists |
| Generic TCP/UDP socket substrate | active local sockets PASS | `KEEP_MIYOO_AS_IS` for Java protocol semantics | Compile unchanged first; external connectivity remains capability-dependent |
| HTTP | kernel socket substrate exists; no external interface in audit | `KEEP_MIYOO_AS_IS` initially | No RG35XX patch unless exact full-integration failure proves runtime gap |
| HTTPS / SSL / PKI | pinned source uses JSSE; native OpenSSL absent; Java JSSE not measured in this run | `NEEDS_SOURCE_MAPPING` | Preserve source; verify protected glibj JSSE during integration, no speculative replacement |
| PIM | pinned source explicitly stubbed | `KEEP_MIYOO_AS_IS` | Keep canonical stub; do not invent contacts/calendar backend |
| Bluetooth / JSR-82 | no controller/rfkill entries, no libbluetooth | `DEFER_CAPABILITY` | Keep API/canonical stubs; no RG35XX Bluetooth backend |
| Sensor / JSR-256 | no IIO sensor devices measured | `DEFER_CAPABILITY` | Keep canonical API/stub behavior; no synthetic sensor backend |
| M3G / JSR-184 | EGL/GLES1 loadable but active EGL init fails on default and GBM paths | `DEFER_CAPABILITY` | `M3G_REENABLED=NO`; do not build into production path yet |
| MascotCapsule / Micro3D | EGL/GLES2 loadable but active EGL init fails on exact relevant routes | `DEFER_CAPABILITY` | `MICRO3D_REENABLED=NO` |
| LWJGL / OpenGL | GL/EGL libraries exist but no working EGL platform/context proven | `DEFER_CAPABILITY` | `LWJGL_OPENGL_REENABLED=NO` |
| Nokia vendor APIs | canonical source + accepted 2D/input/audio boundaries cover hardware portions | `KEEP_MIYOO_AS_IS` / existing boundary where already proven | No vendor/game-specific changes |
| Samsung vendor APIs | no measured hardware requirement justifying a change | `KEEP_MIYOO_AS_IS` | Compile pinned source unchanged first |
| Siemens vendor APIs | no measured hardware requirement justifying a change | `KEEP_MIYOO_AS_IS` | Compile pinned source unchanged first |
| Native loading / JNI ABI | ARM32 works but Miyoo CPU/toolchain assumptions differ from Cortex-A9/uClibc target | `NEEDS_MINIMUM_RG35XX_BOUNDARY` | Rebuild native components with exact RG35XX toolchain/ISA; never substitute Golden identities silently |

## P4 decision

The capability question is now answered sufficiently for full-port planning:

```text
P4_DEFERRED_CAPABILITY_DECISION=PASS
M3G=DEFER_CAPABILITY
MICRO3D=DEFER_CAPABILITY
LWJGL_OPENGL=DEFER_CAPABILITY
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
```

This does not mean that 3D functionality passed. It means the platform decision is evidence-backed: the pinned Miyoo 3D route is not currently usable as-is on the measured original RG35XX.

## Legal next integration model

The next full-port candidate should be assembled from the pinned Miyoo lineage with the following policy:

```text
1. Keep Java/J2ME semantics from pinned Miyoo unchanged by default.
2. Preserve accepted RG35XX P1-P3 boundaries for framebuffer/Raw2D/input/audio/filesystem.
3. Rebuild native code only with exact RG35XX ABI/toolchain flags.
4. Exclude/defer M3G, Micro3D and LWJGL/OpenGL production enablement.
5. Keep PIM as the canonical pinned stub.
6. Keep network protocol source intact; do not promise external networking hardware.
7. Verify JSSE/TLS from the protected Java runtime during full-platform integration.
8. Build one generic installer + one full platform exerciser before another broad physical cycle.
```

Recommended next branch role:

```text
platform-integration/rg35xx-miyoo-full-port-r1
```

No game-specific compatibility work is authorized by this capability audit.