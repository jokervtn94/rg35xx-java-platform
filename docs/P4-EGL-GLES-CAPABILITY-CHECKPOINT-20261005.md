# P4 — EGL/GLES capability checkpoint

**Date:** 2026-10-05  
**Status:** `PARTIAL / P4.2_PACKAGE_BUILT / PHYSICAL_TEST=NOT_TESTED`  
**Predecessor:** P3 scoped runtime-service physical acceptance  
**Canonical:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

## Evidence completed

The read-only provider inventory on the original RG35XX found the device EGL
and GLES libraries and reported `P4_DECISION=REQUIRES_SYMBOL_AND_CONTEXT_REVIEW`.
The uClibc-compatible P4.1 context probe then ran on the device and produced:

```text
P4_CONTEXT_EGL_DISPLAY=NON_NULL ERROR=0x3000
P4_CONTEXT_EGL_INITIALIZE=FAIL ERROR=0x3001
P4_CONTEXT_RESULT=FAIL
P4_CONTEXT_DEVICE_RESULT=REVIEW_REQUIRED
```

This proves the rebuilt probe executes and can load the provider libraries. It
does not prove that GarlicOS/SDL exposes an EGL-native display that can be
initialized. `0x3001` is `EGL_NOT_INITIALIZED`.

## Current package

P4.2 adds a read-only probe for framebuffer/GPU nodes, SDL/EGL environment,
EGL client extensions, `eglGetPlatformDisplay`, and `EGL_EXT_platform_device`
enumeration where advertised. It does not load Java 3D classes or modify the
production runtime.

```text
P4_PLATFORM_WORKFLOW_RUN=37216707434
P4_PLATFORM_ARTIFACT=RG35XX-P4-PLATFORM-PROBE-23a79d5d8bdf024382890f8d347cf50c85c91203
P4_PLATFORM_ARTIFACT_SHA256=64d375fbc487ee5a49e7cb4834f287773fc3994f74b83445bb0eb4ece3d3c3ea
P4_PLATFORM_PHYSICAL_TEST=NOT_TESTED
```

## Next action

Run `Roms/APPS/RG35XX-P4-PLATFORM-PROBE.sh` on the original RG35XX and return:

```text
/mnt/mmc/RG35XX-P4-PLATFORM-EVIDENCE/P4-EGL-PLATFORM.log
```

Interpretation is bounded:

- a platform/device initialization PASS permits a targeted source-call mapping
  review; it does not authorize broad 3D re-enable;
- `REVIEW_REQUIRED` keeps deferred 3D disabled and records the missing native
  display/provider boundary;
- no runtime hashes or accepted P2C/P3 owners may be changed by this probe.
