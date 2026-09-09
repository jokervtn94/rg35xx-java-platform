# B6 real-device acceptance evidence — 2026-09-09

Status: PARTIAL DEVICE ACCEPTANCE / FOUNDATION NOT YET FROZEN

This checkpoint records the first real-device evidence from the B6 atomic package using the B4 early-native logger.

## Games exercised

1. `/mnt/mmc/Roms/JAVA/KDTT-Tam_Quoc_Chi_320x240_vh_by_zeplaovn.jar`
2. `/mnt/mmc/Roms/JAVA/NinjaSchool1.jar`
3. `/mnt/mmc/Roms/JAVA/Qix_352x416_S60v3-376072-mobiles24.jar`

## Native launch evidence

All three sessions reached the complete early launch chain:

`CORE_INIT -> RUNTIME_PATH -> JAVA_OPEN_BEGIN -> PIPE_CREATE -> FORK_RESULT -> CHILD_PRE_EXEC -> JAVA_READY -> LOAD_GAME_ENTER -> GAME_PATH -> IPC_LOAD_SENT -> IPC_RUN_SENT -> CORE_DEINIT`

Observed child PIDs: 152, 182, 210.

This proves on real RG35XX hardware that the B4 core is selected and loaded, JamVM exec/startup succeeds, the Java READY handshake succeeds, the requested JAR path reaches the core, LOAD and RUN IPC commands are sent, and RetroArch can deinitialize the core and launch subsequent Java games.

## Important interpretation

`read_errno=2`, `write_errno=2`, and `errno=2` printed beside successful `pipe()` / `fork()` results are stale errno values and are NOT failures because the corresponding return values are successful (`read_rc=0`, `write_rc=0`, parent fork pid > 0, child fork pid=0). Future logging should print errno only when the syscall fails, to avoid ambiguity.

## What this evidence DOES NOT prove yet

The current B4 early log does not record:

- first valid RGB565 frame header / first native frame publish;
- source dimensions / Smart-Fit result for each game;
- Java child exit status / signal at shutdown;
- distinction between normal frontend unload and child crash;
- gameplay/input/font/audio correctness.

Therefore this evidence is sufficient to mark the native startup/IPC/deinit chain DEVICE-PASS, but is NOT sufficient to mark the complete B6 foundation DEVICE-PASS or STABLE.

## Next gate

Before freezing the first recovery checkpoint, extend observability only (no Java/runtime/video/media semantic changes) with:

- `FIRST_FRAME_HEADER w=... h=... payload=...`
- `FIRST_FRAME_PUBLISH generation=...`
- `SMART_FIT source=... output=...`
- child `waitpid`/exit/signal reason at shutdown where available.

Then perform one final acceptance pass using representative 240x320, 320x240, 352x416 and 360x640 games. Only after that evidence plus manual boot/render/input/exit/relaunch acceptance may B6 be tagged/frozen as DEVICE-PASS.

## Foundation hashes under test

- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- GNU Classpath glibj.zip: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- B4 runtime JAR build file SHA: `e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed`
- B3/B4 deterministic runtime content identity: `52e809ecf5d23f4c2c0989075270680248299bbc02e7cb8ca665bee002942783`
- B4 native core: `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`
