# RG35XX Miyoo Full Capability Audit — 2026-10-05

## Status

```text
AUDIT_DESIGN=PASS
HOST_BUILD=PASS
ORIGINAL_RG35XX_PHYSICAL=PASS
CAPABILITY_MATRIX=PARTIAL
P4_DEFERRED_CAPABILITY_DECISION=PASS
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

`ORIGINAL_RG35XX_PHYSICAL=PASS` means the diagnostic capability package ran and returned the required evidence. It does **not** mean every optional capability is supported and does not promote the platform baseline.

The detailed evidence-backed module classification is recorded in:

```text
docs/RG35XX-MIYOO-CAPABILITY-DEVICE-ANALYSIS-20261005.md
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

Host build evidence:

```text
WORKFLOW_RUN=37252555593
BUILD_HEAD=3fcfa09a2185eb8ae5294e6dc00a0d65ab42ee99
WORKFLOW_CONCLUSION=success
ARTIFACT_ID=11321446871
ARTIFACT_NAME=RG35XX-MIYOO-CAPABILITY-AUDIT-3fcfa09a2185eb8ae5294e6dc00a0d65ab42ee99
ARTIFACT_DIGEST=sha256:7352ad4a20e1a4c967ab94c98484d64e3a816dcdf23011e9472d0e917d322bf5
```

Physical evidence received and analyzed:

```text
EVIDENCE_ZIP_SHA256=167dd113cba1cb88d2a664bfaaf22c8e1d8e5fcb911b33d764f75596196bfb4c
NATIVE_ACTIVE_PROBE_RC=0
P4_COMPONENT_RC=0
AUDIT_RESULT=REVIEW_REQUIRED
```

`AUDIT_RESULT=REVIEW_REQUIRED` was the intentional device-side marker. Host/source review has now converted the collected evidence into the module decisions documented separately.

## Purpose

Before continuing the full Miyoo port, measure what the original RG35XX / GarlicOS platform actually exposes and then map those measured capabilities to the pinned Miyoo source requirements.

This audit is deliberately broader than the previous P4 3D probe. It answers platform-substrate questions once so later port decisions can reuse the same evidence instead of creating a new physical package for each class or module.

The audit remains diagnostic only:

```text
RUNTIME_SEMANTIC_DELTA=NONE
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
DEVICE_PASS=NO
STABLE=NO
```

## Pinned Miyoo source requirements established

From the exact pinned Miyoo source:

- Java package groups include MIDP IO, LCDUI, M3G, media, MIDlet, PIM, PKI, RMS and Sensor APIs.
- Vendor groups include MascotCapsule, Nokia, Samsung and Siemens APIs.
- `org.lwjgl` is present.
- the Miyoo native frontend is SDL2 + pthread;
- the Miyoo audio JNI library links SDL2 + SDL2_mixer;
- M3G ARM32 links EGL + GLES1 + zlib;
- MascotCapsule/Micro3D ARM32 links EGL + GLES2;
- Miyoo ARM32 native build flags assume Cortex-A7 / ARMv7VE / NEON-VFPv4 hard-float style targeting.

These are requirements of the pinned source, not proof that original RG35XX provides the same substrate.

## Existing accepted RG35XX evidence preserved

The current project already has accepted physical evidence for:

```text
P1_CORE_2D=PASS
P2_IMAGE_FONT_FRONTEND=PASS
P3_RUNTIME_SERVICES=PASS
```

The audit therefore did not reinitialize SDL video/audio merely to repeat accepted physical behavior. It inventories those providers and preserves the accepted RG35XX boundaries.

## Key physical findings

```text
CPU=ARMv7 Cortex-A9 family
NEON=YES
VFP=v3
FBDEV=/dev/fb0 owlfb
INPUT=/dev/input/js0 RG35XX Gamepad
ALSA=AVAILABLE
SDL1=LOADABLE
SDL2=LOADABLE
SDL_MIXER1=LOADABLE
SDL2_MIXER=NOT_FOUND_OR_UNLOADABLE
EGL=LOADABLE
GLES1=LOADABLE
GLES2=LOADABLE
EGL_DEFAULT_INITIALIZE=FAIL
EGL_GBM_INITIALIZE=FAIL
DRI_CARD0=ABSENT
MALI_NODE=ABSENT
BLUETOOTH_USERSPACE_PROVIDER=NOT_FOUND_OR_UNLOADABLE
IIO_SENSOR_DEVICES=NONE_MEASURED
FS_ACTIVE_OPERATIONS=PASS
TCP_UDP_LOOPBACK=PASS
EXTERNAL_NETWORK_INTERFACE=NOT_MEASURED
```

The audit Java-runtime search did not find `java`, `jamvm` or glibj in the launcher environment. This is a probe-path limitation, not a runtime failure, because accepted P1-P3 physical evidence already proves the protected Java runtime executes. Unresolved Java-class-library questions such as JSSE/TLS are carried into the full integration gate rather than causing repeat tests.

## Final planning decisions

```text
CORE_JVM=KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY
LCDUI_CORE2D=KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY
IMAGE_FONT=KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY
INPUT_FRONTEND=KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY
RMS_FILECONNECTION=KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY
MMAPI_AUDIO=KEEP_CANONICAL_WITH_EXISTING_RG35XX_BOUNDARY
GENERIC_TCP_UDP=KEEP_MIYOO_AS_IS
HTTPS_TLS=NEEDS_SOURCE_MAPPING
PIM=KEEP_MIYOO_AS_IS
BLUETOOTH_JSR82=DEFER_CAPABILITY
SENSOR_JSR256=DEFER_CAPABILITY
M3G_JSR184=DEFER_CAPABILITY
MASCOTCAPSULE_MICRO3D=DEFER_CAPABILITY
LWJGL_OPENGL=DEFER_CAPABILITY
NATIVE_ABI=NEEDS_MINIMUM_RG35XX_BOUNDARY
```

PIM is kept as-is because the pinned source explicitly stubs device PIM access. The 3D stacks remain disabled because the exact default/GBM EGL routes used by pinned Miyoo do not initialize on the measured original RG35XX.

## Next action

The capability audit is sufficient to continue with a full port integration candidate without another capability test cycle:

```text
NEXT_BRANCH_ROLE=platform-integration/rg35xx-miyoo-full-port-r1
NEXT_BUILD=GENERIC_INSTALLER_PLUS_FULL_PLATFORM_EXERCISER
```

Full integration must preserve the pinned Miyoo lineage and accepted P1-P3 boundaries, rebuild native components for the exact RG35XX ABI/toolchain, keep M3G/Micro3D/LWJGL disabled, and avoid any game-specific compatibility work.