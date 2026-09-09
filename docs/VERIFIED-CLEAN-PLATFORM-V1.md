# RG35XX Verified Clean Platform v1

This branch is a clean reconstruction track that only admits changes with direct RG35XX device evidence.

## Goal

Rebuild the Java platform as one coherent system, instead of continuing the patch/test chain that accumulated interacting regressions.

## Admission rule

A subsystem may enter this branch only when it is one of:

1. Exact behavior recovered from the device-proven Golden binaries.
2. A change that already passed a real RG35XX device test.
3. A source reconstruction whose output is then validated on a real RG35XX before the next subsystem is admitted.

Synthetic/unit/build success alone is not enough to call a subsystem stable.

## Verified components to keep

### JamVM

Use JamVM L Production behavior:
- remove the invalid direct-interpreter ALOAD_0 + GETFIELD -> GETFIELD_THIS folding;
- preserve local slot 0 semantics after ASTORE_0;
- no diagnostic low-pointer guards in production.

Device-proven production SHA:
`eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`

### Boot / media

Keep lazy media boot:
- MIDlet starts before media initialization;
- no eager `Manager.prepareMediaEngine()` during boot;
- no background `RG35XX-MediaWarmup` thread at boot.

This change passed device testing and removed the ALSA `/dev/snd/seq` boot failure path.

### Video / IPC

Keep the Golden architecture:
- Java snapshots the ARGB framebuffer asynchronously;
- Java converts to RGB565;
- dedicated Java frame worker;
- framed binary IPC;
- native exact-length receiver thread;
- native front/back buffers;
- atomic generation publish;
- `retro_run()` presents only the latest valid frame and never waits for Java;
- source MIDlet dimensions stay authoritative;
- native Smart-Fit handles the RG35XX physical output.

### Golden runtime ABI / paths

Keep:
- Java class version 50;
- `/mnt/mmc/CFW/java/bin/jamvm`;
- runtime `freej2me-lr.jar`;
- BIOS `/mnt/mmc/BIOS`;
- `/mnt/mmc/freej2me-java-error.log`;
- `/mnt/mmc/freej2me-core.log`;
- headless Toolkit / GraphicsEnvironment properties.

### GNU Classpath

Keep the known baseline `glibj.zip` unchanged during the clean rebuild.
Do not byte-patch `glibj.zip`.

## Not admitted yet

The following are explicitly excluded from the initial clean baseline because they have not completed real-device acceptance in their current reconstructed form:

- PNG ICC v4 compatibility patches;
- N3/N3.1 PNGChunk bytecode patches;
- CV/CW boot-time resolution patches;
- CK metric-scaled font raster;
- RC/CD/CJ experimental presentation stacks;
- any installer labeled stable that was later shown to regress KDTT.

These may be reconsidered only after the clean baseline passes acceptance.

## Build order

The platform is rebuilt in fixed stages. A stage is frozen after device PASS before the next stage is admitted.

1. **VC0 Core baseline** — pinned upstream + Golden ABI/paths + immutable glibj.
2. **VC1 JamVM** — JamVM L production.
3. **VC2 Boot** — lazy media boot only.
4. **VC3 Video** — Golden async RGB565 receiver/double-buffer/Smart-Fit architecture.
5. **VC4 Font** — restore Golden Unicode font behavior only after VC3 device PASS.
6. **VC5 Audio** — restore Golden asynchronous audio/MIDI behavior only after VC4 device PASS.
7. **VC6 Compatibility** — add game-specific compatibility fixes one at a time (PNG ICC, duplicate class, etc.).
8. **VC7 Acceptance** — one installation, then representative real-game acceptance across resolutions and media.

## Acceptance policy

Do not install a new full platform for every source experiment.

During construction:
- compile and static-gate each stage in CI;
- package the complete platform only at stage checkpoints;
- test one coherent checkpoint on RG35XX;
- if a checkpoint fails, fix that stage before adding another subsystem.

Final acceptance must include at least:
- 240x320 game;
- 320x240 game;
- 352x416 game;
- 360x640 game;
- input;
- RMS persistence;
- font rendering;
- short tone;
- WAV;
- MIDI;
- clean exit/relaunch.

`STABLE` is forbidden until this acceptance passes on real hardware.
