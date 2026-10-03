# A8 Production Consolidation

A8 converts the accepted A7+A1P5 device-proven runtime boundary into one generic production launcher without changing accepted Java/native runtime semantics.

## Source of truth

- **A8 stable baseline:** `rg35xx-aweigit-r1-stable`
- A8 consolidation branch: `rg35xx-aweigit-r1-a8-consolidation`
- A7 accepted adapter checkpoint: `5b7a8e88bd32a735a1342715e718eecf8cf10fad`
- Exact A1P5 evidence is preserved under `packaging/a8/reference/`.
- A8 CI production candidate: commit `80113f50e5db59e372f02722e3ff362263490b2c`.

## Production launcher

`RG35XX-AWEIGIT-R1.sh` accepts the selected JAR as argument 1. It validates the protected JamVM/glibj and accepted platform/input/video/audio/prime identities, performs the exact accepted A1P5 pre-Java zero-PCM prime, and then launches `org.recompile.rg35xx.RG35XXLauncher`.

Expected production installation layout:

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

Commercial game JARs are external inputs and are not part of the production package.

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

## A8 real-device acceptance

**STATUS: DEVICE-PASS**

The A8 production candidate passed original-RG35XX real-device acceptance.

### Automated/technical gates

- A8 production CI: PASS.
- Runtime identity and protected JamVM/glibj checks: PASS.
- A1P5 zero-PCM pre-Java audio prime: PASS.
- Vua Cướp Biển regression: PASS.
- God of War regression: PASS.
- PERF-A1/runtime execution: PASS.
- Normal exit: PASS.
- Protected runtime hashes: PASS.

### Human device confirmation

The operator confirmed on the physical RG35XX:

- Vua Cướp Biển displays correctly.
- Vua Cướp Biển controls work.
- Vua Cướp Biển gameplay is normal.
- Vua Cướp Biển does not hang.
- God of War displays correctly.
- God of War controls work.
- God of War gameplay is normal.
- God of War does not hang.
- God of War audio is audible and normal.

Therefore A8 is no longer a candidate. It is the accepted RG35XX production baseline.

## Maintenance rules

1. Treat the A8 stable commit as the production source of truth.
2. Do not alter protected JamVM/glibj or accepted runtime identities as part of routine feature work.
3. Keep commercial game JARs outside the production package.
4. Any future runtime-semantic change must start a new A-series checkpoint and repeat CI plus real-device acceptance.
5. Do not replace this baseline with an older A7/A1P5 build unless a regression is explicitly demonstrated.
