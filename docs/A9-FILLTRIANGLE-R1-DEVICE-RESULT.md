# A9 fillTriangle R1 physical-device result

## Identity

- Device: original RG35XX
- Game: `Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar`
- Game SHA256: `b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b`
- A9 R1 platform SHA256: `c4a5adff83c89c891531b2693558583a773a8f8297386f4d36a3cb21ee65f201`
- Input native SHA256: `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`
- Video native SHA256: `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d`
- Audio native SHA256: `4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`
- Protected JamVM/glibj gate: PASS
- Original game identity gate: PASS
- Install mode: side-by-side; accepted A8 not modified
- A8 payload on SD during this run: not present / not required by R3 installer

## Device observation

- Early splash/loading backgrounds before menu: **FAIL** — still missing.
- Menu graphics: **PASS**.
- Menu/input controls: **PASS**.
- Gameplay load: **PASS** — R1 no longer exits at `PlatformGraphics.fillTriangle()`.
- Race/gameplay: **PARTIAL** — playable but visibly laggy.
- Input during gameplay: **PARTIAL/FAIL** — delayed or lagged with gameplay.
- Audio: **PARTIAL/FAIL** — only some effects audible; expected broader game audio/music is absent.
- Exit/lifecycle: **FAIL** — normal exit could not be completed; hard reset was required.
- Overall result: **FAIL / NOT STABLE**.

## Runtime evidence

The previous swallowed-exception failure at `PlatformGraphics.fillTriangle()` did not recur. The game reached gameplay and continued beyond 600 submitted frames.

Performance markers:

```text
RG35XX_PERF_A1_QUEUE SUBMITS=300 PRESENTED=297 DROPPED=1 COPY_AVG_MS=1 LAST_RC=0
RG35XX_PERF_P3_FRAME=300 ELAPSED_MS=16291 FPS_X100=1841
RG35XX_PERF_A1_QUEUE SUBMITS=600 PRESENTED=595 DROPPED=3 COPY_AVG_MS=1 LAST_RC=0
RG35XX_PERF_P3_FRAME=600 ELAPSED_MS=37784 FPS_X100=1587
```

Interpretation:

- Presenter queue drops are low (3 by submit 600).
- Frame-copy average remains 1 ms.
- Effective cumulative FPS declines from about 18.41 to 15.87, far below the game's configured 30 FPS target.
- Therefore the observed lag is not explained by presenter queue saturation; the active Java/render/game path before submission is the current performance owner candidate.

Audio markers show the backend initializes and media objects load/play:

```text
RG35XX_A7_AUDIO_INIT=PASS BACKEND=SDL1_MIXER ...
RG35XX_A7_AUDIO_MIDI_LOAD=PASS
RG35XX_A7_AUDIO_MIDI_PLAY=PASS LOOPS=1
RG35XX_A7_AUDIO_WAV_LOAD=PASS
RG35XX_A7_AUDIO_WAV_PLAY=PASS LOOPS=0
ALSA ... underrun occurred
```

This is a technical media-path pass, but not an audible device pass. The device observation remains authoritative: audio is incomplete.

The log ends while the game is still running because a hard reset was required. Therefore there is no normal runtime exit code or post-run protected-hash footer for this device run.

## R1 disposition

```text
A9_R1_FILLTRIANGLE_CRASH_FIX=PASS
A9_R1_GAMEPLAY_ENTRY=PASS
A9_R1_PERFORMANCE=FAIL
A9_R1_AUDIO=FAIL_PARTIAL
A9_R1_EARLY_BACKGROUNDS=FAIL
A9_R1_EXIT=FAIL_HARD_RESET_REQUIRED
A9_R1_DEVICE_PASS=NO
A9_R1_STABLE=NO
```

R1 must not be promoted.

## R2 scope

R1 filled every triangle scanline by calling the accepted Java `drawLine()` implementation. That proves correctness well enough to reach gameplay, but each span then loops over its pixels again in Java.

R2 keeps the same evidence-owned six-argument `Graphics.fillTriangle()` scope and the same scanline geometry, but writes each clipped horizontal span directly into the Raw2D framebuffer with `Arrays.fill()`. Translation and clip are handled explicitly. Canonical/AWT fallback, the seven-argument DirectGraphics overload, audio, input, presenter, PNG/image paths, and protected native binaries remain unchanged.

R2 is a performance candidate only. Missing early backgrounds, incomplete audible audio, and exit/lifecycle remain separate open observations unless R2 device evidence shows they were secondary to frame starvation.
