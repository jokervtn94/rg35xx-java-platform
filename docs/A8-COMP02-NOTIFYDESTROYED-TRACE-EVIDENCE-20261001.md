# A8-COMP-02 notifyDestroyed Trace Evidence

## Exact candidate

- Candidate: `A8-COMP-02`
- Game: Asphalt 4 : Elite Racing
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

## Interpretation

The immediate application exit is initiated from the game thread `Thread-1`, in the obfuscated game class/method `e.run()`, which explicitly calls `MIDlet.notifyDestroyed()`.

This rules out the launcher/JVM spontaneously terminating the process at the observed boundary. The trace also does not support direct heap exhaustion: the VM reported a current heap of about 8.55 MB with about 2.36 MB free and a configured maximum near 64 MB when `notifyDestroyed()` was invoked. No Java exception or `OutOfMemoryError` escaped into the trace before the destroy call.

The evidence does **not** yet explain why `e.run()` chooses the destroy path. The owner therefore remains unresolved inside the game/gameplay-transition path. Candidate explanations such as a swallowed resource-load failure, gameplay-only dependency, game-controlled fatal/exit condition, or another compatibility condition require inspection of the exact game's `e` class or a still narrower trace around the branch that reaches `notifyDestroyed()`.

## Result update

```text
GAMEPLAY=FAIL_EXIT_ON_GAMEPLAY_LOAD
LIFECYCLE=FAIL_GAME_THREAD_CALLS_NOTIFYDESTROYED
EXIT_CALLER=e.run() -> MIDlet.notifyDestroyed()
EXIT_THREAD=Thread-1
DIRECT_OOM_EVIDENCE=NO
UNCAUGHT_EXCEPTION_EVIDENCE=NO
A8_CANONICAL_MODIFIED=NO
FAILURE_OWNER=UNRESOLVED_INSIDE_GAME_THREAD_E_RUN
A8_RUNTIME_REGRESSION=NOT_ESTABLISHED
A9_RUNTIME_CHANGE=NOT_JUSTIFIED_YET
DEVICE_PASS=NO
```

## Next diagnostic boundary

Do not modify A8 production semantics and do not suppress `notifyDestroyed()`.

The next useful evidence must identify the decision path inside the exact JAR's obfuscated `e.run()` immediately before it calls `notifyDestroyed()`. Prefer bytecode inspection of the exact JAR if available; otherwise instrument only the relevant game-thread/lifecycle boundary. Do not broaden into graphics/audio/input fixes without direct evidence.
