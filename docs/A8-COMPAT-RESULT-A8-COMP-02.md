# A8-COMP-02 Compatibility Result

## Candidate identity

- Candidate ID: `A8-COMP-02`
- Game: Asphalt 4 : Elite Racing
- JAR: `Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar`
- JAR SHA256: `b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b`
- Device: original RG35XX
- Baseline: A8

## Runtime identity

All protected identities matched the accepted A8 baseline:

- JamVM: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- platform JAR: `057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c`
- input native: `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`
- video native: `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d`
- audio native: `4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`
- prime PCM: `8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e`

The runtime log reports `IDENTITY_GATE=PASS`, `A1P5_RW_SILENCE_PRIME=PASS`, `PROTECTED_HASHES=PASS`, and normal process exit.

## Technical runtime evidence

The candidate progressed substantially beyond boot:

- MIDlet created and `startApp()` reached.
- `Canvas` created at `240x320`.
- GLLib identifies the game build as MIDP2.
- RG35XX scaler path activated: `FAST_3_TO_2_240x320_TO_360x480`.
- Frame presenter remained active through at least 600 submits.
- RMS opened, created/updated a record, and closed successfully.
- SDL1_mixer audio backend initialized successfully.
- MIDI resources loaded and MIDI playback reported PASS.
- WAV resources loaded and WAV playback reported PASS.
- Audio shutdown completed with `VIDEO_SDL_OWNER_PRESERVED=YES`.
- MIDlet sent destroyed notification.
- Runtime exit code was 0 and launcher recorded `NORMAL_EXIT=PASS`.

Performance telemetry observed in the log:

- At 300 submits: 298 presented, 0 dropped, `FPS_X100=2060`.
- At 600 submits: 595 presented, 3 dropped, `FPS_X100=1623`.

One ALSA underrun recovery message appeared during playback. The runtime continued afterwards, but this remains relevant to the observed incomplete audio and short stalls.

## Manual original-RG35XX observation

The user subsequently confirmed the following on the original RG35XX:

- Graphics/menu presentation: visually correct.
- Input: controls operate normally in the menu.
- Gameplay: FAIL. The game reaches the menu, but attempting to load actual gameplay causes the game to exit.
- Audio: PARTIAL. Audible feedback is heard when selecting a menu item, but other expected game audio is not heard.
- Performance: PARTIAL/FAIL. The game can intermittently freeze/stall for several seconds.
- Lifecycle/exit: the gameplay transition results in the application leaving instead of entering the race/gameplay state.

This means the earlier technical log was not sufficient to describe real usability. The candidate cannot be considered DEVICE-PASS.

## Failure-boundary interpretation

The failure is now narrowed to the transition from working menu state into gameplay loading.

The current evidence does **not** show:

- a Java exception;
- an OutOfMemoryError;
- a protected runtime/hash failure;
- a graphics adapter failure during menu rendering; or
- an input adapter failure during menu navigation.

Instead, the runtime log shows audio shutdown followed by `MIDlet sent Destroyed Notification` and process exit code 0. Therefore the immediate exit cause is not yet assigned to the RG35XX adapter. Possible causes such as a game-controlled exit path, resource/load failure, hidden exception path, media/resource incompatibility, or another gameplay-only dependency require focused reproduction evidence before any runtime change is justified.

## Result

```text
BOOT=PASS
GRAPHICS=PASS_MENU
INPUT=PASS_MENU
GAMEPLAY=FAIL_EXIT_ON_GAMEPLAY_LOAD
AUDIO=PARTIAL_MENU_SELECT_ONLY
MEDIA=TECHNICAL_PASS_BUT_DEVICE_AUDIO_INCOMPLETE
RMS=TECHNICAL_PASS
LIFECYCLE=FAIL_GAMEPLAY_TRANSITION_EXITS
PERFORMANCE=PARTIAL_INTERMITTENT_MULTI_SECOND_STALLS
HANG_CRASH=PARTIAL_INTERMITTENT_STALLS_NO_LOGGED_EXCEPTION
EXIT=PROCESS_EXIT_0_AFTER_MIDLET_DESTROYED_NOTIFICATION

RESULT=FAIL
FAILURE_OWNER=UNRESOLVED_GAMEPLAY_TRANSITION
A8_RUNTIME_REGRESSION=NOT_ESTABLISHED
A9_RUNTIME_CHANGE=NOT_JUSTIFIED_YET
DEVICE_PASS=NO
```

## Next action

Do not advance to A8-COMP-03 yet and do not modify the protected A8 production runtime.

Use this exact JAR and reproduce only the menu -> gameplay transition while adding diagnostic evidence sufficient to identify why the MIDlet destroys/exits at that point. The diagnostic target should be narrow: capture the caller/reason for MIDlet destruction, uncaught thread failures, memory state around the transition, and resource/media operations immediately before exit. Any behavioral fix must wait until that evidence identifies the owner.
