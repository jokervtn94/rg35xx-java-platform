# RC1 Reproducible Source Assembly Audit

Task: RGJ-RC1-011J
Status: STATIC-AUDIT-PASS. BUILD-READY / BUILD-PASS / DEVICE-TEST-PASS are not claimed.

## Result

A deterministic assembly driver now exists at `scripts/rc1_assemble.sh`. It requires the exact FreeJ2ME pin, runs the existing `--build-ready` external-input gate, copies the upstream tree into a disposable assembly directory, overlays registered RG35XX Java sources, copies the exact native support graph and exact vendored TML/TSF headers, then applies only active integration contracts in a fixed order.

The upstream checkout is never modified in place.

## Supersession correction

The assembly set intentionally excludes historical patch 0009 because 0021 owns the pinned multi-file RMS baseline. It also excludes historical 0012 and 0013 because their current pinned graphics/input/lifecycle responsibilities are consolidated by 0020. Applying both historical and consolidated contracts would risk duplicate/conflicting call sites.

The exact current patch-tree names were audited before closing this stage. In particular:

- `0004-libretro-dedicated-audio-pipe.patch`
- `0006-platformplayer-native-backend.patch`
- `0016-libretro-java-audio-fd-exact.patch`
- `0018-manager-platformplayer-rg35xx-direct-media.patch`
- `0019-platformplayer-tonecontrol-rg35xx.patch`

An initial draft of the assembly driver used descriptive-but-nonexistent aliases for several of these files. That draft was corrected before this gate was closed. Future assembly must use repository identities, never remembered aliases.

## Native graph output

The assembly emits `src/libretro/rg35xx/rc1_sources.mk` containing exactly the ten native support translation units locked by 011I and the two required include roots. This is an input to the next Makefile reconciliation stage; the script does not silently rewrite upstream Makefile logic yet.

Structural post-checks require exactly one upstream `freej2me_libretro.c`, no `RG35XXFontEngine.java`, and exactly one TSF/TML implementation owner.

## Deliberate stop conditions

The driver fails instead of guessing when an active patch does not dry-run cleanly against the exact pinned source. Patch divergence is a source reconciliation task, not permission to concatenate helpers or create duplicate classes/functions.

Patch 0022 is deliberately not applied to FreeJ2ME because it targets the separate GNU Classpath 0.99 tree. GNU Classpath assembly remains an explicit runtime/toolchain step.

## Remaining before first compile

1. Materialize all external inputs so `rc1_prebuild_gate.sh --build-ready` can actually pass.
2. Apply/reconcile 0022 to the exact GNU Classpath 0.99 target tree and materialize the pinned DejaVu resource.
3. Integrate `rc1_sources.mk` into the exact pinned `src/libretro/Makefile` without creating a second core entrypoint or duplicate source list.
4. Execute the assembly driver and resolve any patch hunk that fails against the pin.
5. Run Ant Java compilation and ARMv5TE/uClibc native compile/link. Only successful real builds may advance to BUILD-PASS.

This stage closes the assembly-policy/source-driver design only.