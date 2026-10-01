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

The direct `ib = -1` assignments found inside `e.class` are:

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

## Full seven-class call-graph analysis

The exact JAR contains only these seven Java classes:

```text
a.class
b.class
c.class
d.class
e.class
f.class
GloftASP4.class
```

Static call-graph inspection establishes:

- `GloftASP4` extends `MIDlet`.
- `f` extends `e`.
- `f.a() throws Exception` is the concrete implementation of the abstract game-frame method `e.a()` invoked by the paint wrapper.
- Only two bytecode locations in the seven-class JAR call `e.l()` with no arguments:
  1. `GloftASP4.destroyApp(boolean)`; and
  2. `f.a()` when game state `p == -1`.
- `e.l()` itself only sets `e.ib = -1`.
- `e.run()` then observes `ib < 0`, cleans up, and calls `notifyDestroyed()`.

Therefore the device exit has now been reduced to two behavior classes:

1. **intentional/state-driven exit**: the MIDlet is destroyed externally or `f` reaches state `p == -1`, causing `e.l()` -> `ib=-1`; or
2. **swallowed game exception**: `f.a()` or another operation inside the `e.run()` protected region throws `java.lang.Exception`, the built-in catch silently sets `ib=-1`, and the game exits through the same clean lifecycle path.

The current device evidence did not show an external user-requested exit, and the failure reproduces specifically on menu -> gameplay load. Static analysis therefore makes the swallowed-exception path the next highest-value diagnostic target, but does not yet claim it as proven.

## Diagnostic game-copy trace

A diagnostic `e.class` transformation was prepared from the exact extracted class. It changes only the two existing swallowed-exception handlers so they call `Throwable.printStackTrace()` before retaining the original `ib=-1` behavior.

```text
ORIGINAL_E_CLASS_SHA256=3dc2e0a872411ea661919ef74c3da22c73684e1b0d7360ff812769572ad226b4
PATCHED_E_CLASS_SHA256=08a10009bac32b425fdb997c7ac70d521730ff7753c71494a9aa1b7d6011bfdd
PATCH_SCOPE=e.class only
CANONICAL_A8_RUNTIME_MODIFIED=NO
ORIGINAL_GAME_JAR_OVERWRITTEN=NO
```

The testpack makes a side-by-side copy of the exact game JAR, replaces only `e.class`, verifies every other ZIP entry remains byte-identical, and launches that diagnostic copy through the accepted A8 compatibility harness.

Testpack:

```text
RG35XX-A8-COMP02-SWALLOWED-EXCEPTION-TRACE-R1.zip
SHA256=38086b70f095fad2a54e65d0948eb03aa48edac39177b7a196a78cd8e0c5740d
```

## Interpretation

The immediate application exit is initiated from the game thread `Thread-1`, in the obfuscated game class/method `e.run()`, which explicitly calls `MIDlet.notifyDestroyed()` after `ib` becomes negative.

This rules out the launcher/JVM spontaneously terminating the process at the observed boundary. The trace also does not support direct heap exhaustion: the VM reported a current heap of about 8.55 MB with about 2.36 MB free and a configured maximum near 64 MB when `notifyDestroyed()` was invoked. No uncaught Java exception or `OutOfMemoryError` escaped into the trace before the destroy call.

Static bytecode shows that `e.class` deliberately hides exceptions in both the run loop and game-paint/frame path by converting them into `ib = -1`, followed by the same normal destruction path. Therefore the current `RUNTIME_EXIT_CODE=0` is not evidence of successful gameplay shutdown.

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
DIRECT_E_L_CALLERS=GloftASP4.destroyApp(boolean),f.a() state p==-1
CONCRETE_GAME_FRAME=f.a() throws Exception
A8_CANONICAL_MODIFIED=NO
FAILURE_OWNER=UNRESOLVED_INTENTIONAL_STATE_EXIT_OR_SWALLOWED_GAME_EXCEPTION
A8_RUNTIME_REGRESSION=NOT_ESTABLISHED
A9_RUNTIME_CHANGE=NOT_JUSTIFIED_YET
DEVICE_PASS=NO
```

## Next diagnostic boundary

Run the side-by-side swallowed-exception trace copy on the original RG35XX and reproduce only menu -> gameplay load.

- If a stack trace is emitted immediately before exit, assign the failure to the exact thrown game/API/resource path shown by that trace.
- If no swallowed-exception stack trace is emitted, investigate the state-driven path to `p == -1` / `e.l()` instead.

Do not modify A8 production semantics, suppress `notifyDestroyed()`, or broaden into graphics/audio/input fixes without that evidence.
