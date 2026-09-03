# Supplemental immutable RC1 task record

## RGJ-RC1-010I — Exact upstream core native-media runtime integration
- Action: ADD INTEGRATION PATCH / AUDIT
- Status: IMPLEMENTED
- File: `patches/0015-libretro-native-media-runtime.patch`.
- Pre-change reload: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current native tree and exact upstream core owner were inspected.
- Exact upstream basis: `TASEmulators/freej2me-plus` devel `src/libretro/freej2me_libretro.c`, blob `534b26cc97129c4fe7b04ea9a6b07fb8945d33b0`.
- Ownership proof: project repository has no parallel `freej2me_libretro.c`; registry reserves the existing upstream core as integration owner. Therefore this task adds a patch contract, not another core entrypoint.
- Exact findings: upstream `retro_init()` calls `javaOpen()` after system/config setup; `javaOpen()` creates the Java stdin/stdout pipes and forks on Linux; `retro_load_game()` sends save path, ROM path, options and opcode 13; `retro_unload_game()` is empty; Linux `retro_deinit()` currently uses SIGKILL + wait; `retro_reset()` chains deinit/init/load.
- Integration decision: native media runtime is process/platform lifetime. Initialize media cache/mixer/SF2->TSF runtime and dedicated audio transport before Java can register media; do not initialize from `retro_run()` or per JAR.
- Game-switch decision: RESET mixer before media cache; keep shared SoundFont/TSF runtime alive across ordinary game switch.
- Final shutdown decision: Java shutdown/RMS barrier where protocol permits -> stop audio writer/worker ownership -> close audio pipe -> reset mixer/cache -> `rg35xx_media_runtime_shutdown()` -> release authoritative SF2 bytes.
- Event decision: typed native media events are encoded through the existing opcode-14 return-channel contract from patch 0014; Java stdout remains video IPC only.
- SoundFont decision: authoritative SF2 asset/provider remains unresolved. Do not use a guessed BIOS path or TinySoundFont example asset.
- Dependency decision: pinned `tml.h`/`tsf.h` remain byte-identical vendor build gates.
- Remaining blockers: apply process/FD edits to assembled core; reconcile exact media-cache init/free names; implement graceful Java shutdown handshake before replacing SIGKILL-only behavior; vendor pinned headers; resolve authoritative SF2 provider.
- BUILD-PASS, STATIC-AUDIT-PASS for the complete media facade, and DEVICE-TEST-PASS are not claimed.

This supplemental file exists because the connector can truncate the large main RC1 tasklog. It must be merged/appended to the authoritative immutable RC1 history when the full file can be safely updated without dropping prior entries.
