# A8-COMP-02 notifyDestroyed Trace Evidence

## Exact candidate

- Candidate: `A8-COMP-02`
- Game: Asphalt 4 : Elite Racing
- JAR: `Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar`
- JAR SHA256: `b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b`
- Device: original RG35XX
- Trace build: `A8-COMP02-NOTIFYDESTROYED-TRACE-R1`
- Canonical A8 production runtime modified: `NO`

## Trace identity

The side-by-side trace install reported:

- canonical A8 platform JAR: `057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c`
- trace platform JAR: `27238644f8095b751547f16d716529a1430627980dce4bc24e522a816fe0ff79`
- changed JAR entry: `javax/microedition/midlet/MIDlet.class`
- trace semantics: `NOTIFYDESTROYED_CALLER_MEMORY_ONLY`
- install result: `PASS`

## Reproduced device result

The exact menu -> gameplay transition reproduced the prior exit. The trace captured:

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

Immediately after the trace, the existing runtime path continued unchanged:

```text
RG35XX_A7_AUDIO_SHUTDOWN=PASS VIDEO_SDL_OWNER_PRESERVED=YES
MIDlet sent Destroyed Notification
TRACE_RUNTIME_EXIT_CODE=0
```

## Static `e.class` analysis

The exact extracted `e.class` has SHA256:

```text
3dc2e0a872411ea661919ef74c3da22c73684e1b0d7360ff812769572ad226b4
```

It is an abstract `Canvas` / `Runnable` class. Static bytecode inspection shows that `notifyDestroyed()` is not guarded by a special gameplay branch. `e.run()` loops while static state `ib >= 0`; when that loop terminates it always executes cleanup followed by `MIDlet.notifyDestroyed()`.

The only direct `ib = -1` assignments found inside `e.class` are:

1. constructor initialization before the game thread starts;
2. helper `e.l()` which explicitly sets `ib = -1`;
3. the catch-all `java.lang.Exception` handler around the main body of `e.run()`; and
4. the catch-all `java.lang.Exception` handler around the abstract frame/game method invoked from the paint wrapper.

The two exception handlers construct fatal-error strings but discard them instead of printing them:

```text
!!FATAL ERROR!! in cGame.run().<exception>
!!FATAL ERROR!! in Game_paint().<exception>
```

Both handlers then set `ib = -1`. On the next loop boundary, `e.run()` performs cleanup and calls `MIDlet.notifyDestroyed()`, which explains how a gameplay exception can appear externally as a clean exit with process code 0 and no Java exception in the normal log.

Relevant `run()` flow:

```text
while (ib >= 0) {
    repaint();
    serviceRepaints();
    ...
}
cleanup();
midlet.notifyDestroyed();
```

Equivalent catch behavior from bytecode:

```text
catch (java.lang.Exception ex) {
    new StringBuffer("!!FATAL ERROR!! in cGame.run().").append(ex).toString();
    // string is discarded
    ib = -1;
}
```

The paint wrapper has the same pattern around the game's abstract frame method:

```text
try {
    gameFrameMethod();
} catch (java.lang.Exception ex) {
    new StringBuffer("!!FATAL ERROR!! in Game_paint().").append(ex).toString();
    // string is discarded
    ib = -1;
}
```

This materially strengthens the swallowed-exception hypothesis. It does not yet prove which of the two exception handlers fired, because another class in the game can also call protected static `e.l()` to request an intentional shutdown.

## Interpretation

The immediate application exit is initiated from the game thread `Thread-1`, in the obfuscated game class/method `e.run()`, which explicitly calls `MIDlet.notifyDestroyed()` after `ib` becomes negative.

This rules out the launcher/JVM spontaneously terminating the process at the observed boundary. The trace also does not support direct heap exhaustion: the VM reported a current heap of about 8.55 MB with about 2.36 MB free and a configured maximum near 64 MB when `notifyDestroyed()` was invoked. No uncaught Java exception or `OutOfMemoryError` escaped into the trace before the destroy call.

Static bytecode now shows that `e.class` deliberately hides exceptions in both the run loop and game-paint/frame path by converting them into `ib = -1`, followed by the same normal destruction path. Therefore the current `RUNTIME_EXIT_CODE=0` is not evidence of successful gameplay shutdown.

The remaining decision is narrow: determine whether another game class calls `e.l()` intentionally, or whether the gameplay transition triggers one of the swallowed exception handlers.

## Result update

```text
GAMEPLAY=FAIL_EXIT_ON_GAMEPLAY_LOAD
LIFECYCLE=FAIL_GAME_THREAD_CALLS_NOTIFYDESTROYED
EXIT_CALLER=e.run() -> MIDlet.notifyDestroyed()
EXIT_THREAD=Thread-1
EXIT_TRIGGER_STATE=ib < 0
DIRECT_OOM_EVIDENCE=NO
UNCAUGHT_EXCEPTION_EVIDENCE=NO
SWALLOWED_EXCEPTION_PATH_PRESENT=YES
E_RUN_EXCEPTION_SETS_IB_NEGATIVE=YES
GAME_PAINT_EXCEPTION_SETS_IB_NEGATIVE=YES
EXPLICIT_EXIT_HELPER=e.l() SETS ib=-1
A8_CANONICAL_MODIFIED=NO
FAILURE_OWNER=UNRESOLVED_GAME_CONTROLLED_EXIT_OR_SWALLOWED_GAME_EXCEPTION
A8_RUNTIME_REGRESSION=NOT_ESTABLISHED
A9_RUNTIME_CHANGE=NOT_JUSTIFIED_YET
DEVICE_PASS=NO
```

## Next diagnostic boundary

Do not modify A8 production semantics and do not suppress `notifyDestroyed()`.

Inspect the remaining six classes from this exact seven-class JAR (`a`, `b`, `c`, `d`, `f`, `GloftASP4`) to find any call to `e.l()` and to identify the concrete implementation of the abstract game-frame method. If no intentional `e.l()` call explains the gameplay transition, instrument only the two swallowed-exception handlers in `e.class` to print the caught exception and stack trace on the original RG35XX.

Do not broaden into graphics/audio/input fixes without direct evidence.
