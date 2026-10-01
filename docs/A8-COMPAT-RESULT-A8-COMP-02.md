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

## Device behavior

On the original RG35XX:

- Graphics/menu presentation: visually correct.
- Input: controls operate normally in the menu.
- Gameplay: FAIL. Loading actual gameplay causes the game to exit.
- Audio: PARTIAL. Menu-select feedback is audible, but other expected audio is not heard.
- Performance: intermittent multi-second stalls occur.

## Focused notifyDestroyed trace

A side-by-side trace candidate changed only `javax/microedition/midlet/MIDlet.class` and preserved canonical A8 plus all protected natives.

The exact menu -> gameplay transition reproduced the exit and captured:

```text
RG35XX_A8_COMP02_NOTIFYDESTROYED_THREAD=Thread-1
RG35XX_A8_COMP02_MEMORY_FREE=2361968
RG35XX_A8_COMP02_MEMORY_TOTAL=8554440
RG35XX_A8_COMP02_MEMORY_MAX=67108856
java.lang.Exception: RG35XX_A8_COMP02_NOTIFYDESTROYED_CALLER
   at javax.microedition.midlet.MIDlet.notifyDestroyed(MIDlet.java:70)
   at e.run(Unknown Source)
   at java.lang.Thread.run(Thread.java:745)
```

The existing runtime path then continued unchanged:

```text
RG35XX_A7_AUDIO_SHUTDOWN=PASS VIDEO_SDL_OWNER_PRESERVED=YES
MIDlet sent Destroyed Notification
TRACE_RUNTIME_EXIT_CODE=0
```

## Failure-boundary interpretation

The immediate exit is initiated by the game's own `Thread-1`: obfuscated class `e`, method `run()`, explicitly calls `MIDlet.notifyDestroyed()`.

This rules out the launcher or JVM spontaneously terminating the process at the observed boundary. The trace also does not support direct heap exhaustion at the destroy call: the VM still had about 2.36 MB free in its current approximately 8.55 MB heap and a maximum near 64 MB. No uncaught Java exception or `OutOfMemoryError` was recorded before `notifyDestroyed()`.

The remaining question is why `e.run()` takes the destroy branch. That cannot be assigned to A8 without inspecting the exact JAR bytecode or obtaining another equally focused trace around that branch.

## Result

```text
BOOT=PASS
GRAPHICS=PASS_MENU
INPUT=PASS_MENU
GAMEPLAY=FAIL_EXIT_ON_GAMEPLAY_LOAD
AUDIO=PARTIAL_MENU_SELECT_ONLY
MEDIA=TECHNICAL_PASS_BUT_DEVICE_AUDIO_INCOMPLETE
RMS=TECHNICAL_PASS
LIFECYCLE=FAIL_GAME_THREAD_CALLS_NOTIFYDESTROYED
PERFORMANCE=PARTIAL_INTERMITTENT_MULTI_SECOND_STALLS
EXIT_CALLER=e.run() -> MIDlet.notifyDestroyed()
EXIT_THREAD=Thread-1
DIRECT_OOM_EVIDENCE=NO
UNCAUGHT_EXCEPTION_EVIDENCE=NO

RESULT=FAIL
FAILURE_OWNER=UNRESOLVED_INSIDE_GAME_THREAD_E_RUN
A8_RUNTIME_REGRESSION=NOT_ESTABLISHED
A9_RUNTIME_CHANGE=NOT_JUSTIFIED_YET
DEVICE_PASS=NO
```

## Next action

Do not modify protected A8 semantics, do not suppress `notifyDestroyed()`, and do not advance to broad graphics/audio/input fixes.

Inspect the exact candidate JAR's obfuscated `e.class`, specifically `e.run()`, to identify the condition/branch that reaches `MIDlet.notifyDestroyed()`. A targeted extractor may be used so the full commercial game JAR does not need to be shared.
