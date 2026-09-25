# A8 Production Consolidation

A8 converts the accepted A7+A1P5 device-proven runtime boundary into one generic production launcher without changing accepted Java/native runtime semantics.

## Source of truth

- Stable parent: `rg35xx-aweigit-r1-stable`
- A8 development branch: `rg35xx-aweigit-r1-a8-consolidation`
- A7 accepted adapter checkpoint: `5b7a8e88bd32a735a1342715e718eecf8cf10fad`
- Exact A1P5 evidence is preserved under `packaging/a8/reference/`.

## Production launcher

`RG35XX-AWEIGIT-R1.sh` accepts the selected JAR as argument 1. It validates the protected JamVM/glibj and accepted platform/input/video/audio/prime identities, performs the exact accepted A1P5 pre-Java zero-PCM prime, and then launches `org.recompile.rg35xx.RG35XXLauncher`.

Expected installation layout:

```text
Roms/APPS/RG35XX-AWEIGIT-R1.sh
Roms/APPS/RG35XX-AWEIGIT-R1/
  freej2me-rg35xx.jar
  librg35xx_input.so
  librg35xx_video.so
  libaudio.so
  a7-a1p5-rw-silence-prime.s32le
  data/
```

Commercial game JARs are external inputs and are not part of this package.

## A8 allowed delta

A8 is package/launcher consolidation only. It must not modify:

- canonical Aweigit pin
- protected JamVM/glibj
- accepted platform JAR semantics
- A6 graphics/input/PERF-A1/ClipTranslate behavior
- A7 Java 6 media compatibility
- SDL1_mixer native backend
- A1P5 prime command or PCM identity

The only intentional launcher correction relative to the preserved A1P5 regression launchers is logging order: the result file is truncated once at startup, before identity checks and audio prime. Therefore the final log retains the prime BEGIN/exit/PASS evidence instead of erasing it afterward.

## Acceptance state

This launcher is an A8 candidate until it passes original-RG35XX device testing. A successful repository commit or build is not DEVICE-PASS.

Required A8 real-device sanity:

```text
launcher starts selected external JAR
identity gate passes
A1P5 prime passes and remains visible in final log
boot/render/input remain correct
audio remains audible where present
basic gameplay remains usable
normal exit returns without hard reset
protected runtime hashes remain unchanged
```

After the consolidated launcher passes device testing, run the accepted Vua Cướp Biển and God of War parent sanity checks using external copies of those JARs. Only then may A8 be promoted back to the stable reference branch.
