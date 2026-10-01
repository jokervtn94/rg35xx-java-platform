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

One ALSA underrun recovery message appeared during playback. This did not stop the runtime and later audio operations continued, so it is recorded as an observation rather than a blocking failure.

## Missing manual device observation

The generated `OBSERVATION.txt` still contains `NOT_TESTED` for visual display, controls, gameplay, audible audio, lifecycle, performance, hang/crash, and exit review.

Therefore the runtime log is strong technical evidence, but it does not by itself establish that the game was visually correct, controllable, audibly correct, or acceptable during real gameplay.

## Result

```text
BOOT=TECHNICAL_PASS
GRAPHICS=DEVICE_REVIEW_REQUIRED
INPUT=DEVICE_REVIEW_REQUIRED
GAMEPLAY=DEVICE_REVIEW_REQUIRED
AUDIO=TECHNICAL_PASS_DEVICE_AUDIBILITY_REVIEW_REQUIRED
MEDIA=TECHNICAL_PASS
RMS=TECHNICAL_PASS
LIFECYCLE=TECHNICAL_PASS_DEVICE_REVIEW_REQUIRED
PERFORMANCE=TECHNICAL_EVIDENCE_PRESENT_DEVICE_REVIEW_REQUIRED
HANG_CRASH=NO_RUNTIME_EXCEPTION_OBSERVED_DEVICE_REVIEW_REQUIRED
EXIT=TECHNICAL_PASS

RESULT=PARTIAL
FAILURE_OWNER=UNASSIGNED
A8_RUNTIME_REGRESSION=NO_EVIDENCE
A9_RUNTIME_CHANGE=NOT_JUSTIFIED
DEVICE_PASS=NO_PENDING_MANUAL_OBSERVATION
```

## Next action

Use the original RG35XX to confirm display, controls, actual gameplay progression, audible audio quality, hang/crash behavior, and normal exit. If those observations pass, this candidate can be promoted from `PARTIAL` to `PASS` without changing A8 runtime code.
