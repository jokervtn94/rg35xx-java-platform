# FROM-ZERO FOUNDATION v1 — Build Checkpoint

Status: **BUILD-PASS / DEVICE-ACCEPTANCE-PENDING**

Workflow run: `34793967995`
Artifact ID: `10328966943`
Artifact digest: `52479e168fe703726dab066cf798ff250e91dbf2bc9624c4d5a42fea03918baf`

## Source identity

- Platform branch: `rg35xx-from-zero-rebuild-v1`
- Workflow head: `ae26909605ac436fb1c28f76093e25c11181a086`
- FreeJ2ME pin: `13ec186903087156c145268f8706eecfaf9f1e50`
- Upstream pristine gate: PASS

## Built binaries

- Java runtime SHA256: `ff2ed95a626b8b4663cad9b916d66625aee6a502bd7bd57f8589797db6a8b91a`
- Native core SHA256: `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`
- Java classes: 1334
- Java class major: 50 for all classes
- Core: ELF32 ARM, EABI5, soft-float
- Toolchain image: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`

## Required external device-proven components

- JamVM L SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- GNU Classpath glibj SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

JamVM L is pinned by binary identity but is not yet claimed source-reproducible because the exact production source commit is not present in the current repository.

## Admitted foundation behavior

- Lazy media boot; no startup MediaWarmup.
- Golden Java frame worker and asynchronous native RGB565 receiver.
- Complete-frame validation, double-buffer publish and Smart-Fit.
- Bounded early native observability.
- Source-level PNG iCCP compatibility at PlatformImage boundary.
- Proven dynamic logical view; no CV/CW architecture.
- Current-frontbuffer binding for every frame/control transport request.
- Headless-safe decoded image normalization through `BufferedImage.getRGB`.
- LCD-mask application gated by `Mobile.renderLCDMask`.
- Per-frame RG35XX-JAVA-DIAG writes removed; 20 writes removed in this build while error diagnostics remain.

## Explicitly not admitted

- reconstructed `rg35xx-font.bin`
- VC7R4-R23 diagnostic probes
- CV/CW boot-resolution experiments
- media warmup / eager media
- current VC7R22 audio reconstruction
- tRNS/legacy white-key compatibility extensions pending clean revalidation
- TransformCache as a required fix

## Build evidence

The first run passed, in order:

1. pristine upstream identity
2. clean allowlist assembly
3. Java compile
4. Java 6 bytecode gate
5. pinned ARM uClibc toolchain materialization
6. ARMv5TE soft-float core build
7. strict production contract gate
8. checkpoint packaging

This checkpoint must not be tagged STABLE until real RG35XX acceptance passes.
