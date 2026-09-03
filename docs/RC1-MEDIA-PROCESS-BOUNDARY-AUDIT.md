# RC1 Media Process Boundary Audit

Status: **STATIC-AUDIT-PASS for the media process-boundary stage only.** This is not a whole-platform STATIC-AUDIT-PASS, BUILD-PASS, or DEVICE-TEST-PASS.

Task: `RGJ-RC1-010K`.

## Scope closed by this stage

This stage consolidates four previously separate risk areas into one process-boundary contract: dedicated Java→native audio FD inheritance, typed native media completion return, bounded cross-thread event handoff, and graceful final Java shutdown/RMS barrier.

It intentionally does not solve the still-external TinySoundFont vendor/SF2 asset gate or the Java Manager/PlatformPlayer facade routing gate.

## Exact source basis

The native core integration owner remains upstream `TASEmulators/freej2me-plus` devel `src/libretro/freej2me_libretro.c`, audited at blob `534b26cc97129c4fe7b04ea9a6b07fb8945d33b0`.

The current upstream core owns `javaOpen()` and its stdin/stdout pipes, writes control commands on `pWrite[1]`, reads Java stdout from `pRead[0]`, leaves `retro_unload_game()` empty, and on Linux currently terminates JamVM with `SIGKILL` from `retro_deinit()`.

The Java control owner remains upstream `org.recompile.freej2me.Libretro`. RG35XX integration must modify this parser/facade rather than create a second parser.

## Dedicated audio FD gate

`rg35xx_audio_pipe` remains the only Java→native audio transport owner. Its API already provides create, parent-after-fork, child-after-fork, child-fd lookup, drain, and close.

Patch 0016 locks the exact process rule: create before fork; child closes read end and inherits only the write descriptor; parent closes write end; the JVM property appears before `-jar`; fd 0/1/2 are never repurposed; fork/deinit cleanup is explicit.

No audio data is routed over Java stdout.

## Native event producer gate

`rg35xx_media_events.h` is the typed callback declaration owner. The callback type is exactly:

`void (*)(int event_type, uint32_t player_id, uint64_t media_time_us)`.

Patch 0017 was corrected during audit so the proposed core callback uses `int event_type`; this avoids a function-pointer signature mismatch at compile time.

Mixer/MIDI/PCM producers emit only the typed LOOPED/END contract. Loop counting remains in the actual playback owner, not in the event adapter.

## Cross-thread event handoff gate

Direct writes to `pWrite[1]` from the audio callback are forbidden because the same pipe is used for normal variable-length core→Java commands.

`native/rg35xx_media_event_queue.h/.c` therefore owns a fixed 32-record handoff queue. It contains only primitive event data and performs no heap allocation. A pthread mutex protects push/pop/reset; the mutex is touched only when a LOOPED/END event occurs or when the control side drains events, not for normal audio frames.

Overflow discards the oldest stale event and retains the newest state. Reset clears all indices/records under the same mutex so no event survives a game reset.

This design deliberately avoids ARMv5 lock-free memory-ordering assumptions.

## Opcode-14 serialization gate

Only the existing libretro control-writer context drains the native event queue. The audio callback only enqueues.

Each event is encoded as one 18-byte packet: a 5-byte libretro control header followed by the fixed 13-byte media payload. It is submitted to the existing `write_to_pipe()` in one call, and code must not compare its return value because project variants include a void-return helper.

The 13-byte payload remains byte-compatible with patch 0014:

- event type: 1 byte;
- player id: big-endian 32-bit;
- media time: big-endian 64-bit microseconds.

## Java event gate

`Libretro.java` retains stdin-parser ownership. Case 14 performs an exact 13-byte read loop, validates the event type, reconstructs player id/time, and queues the result into `RG35XXMediaRegistry` without invoking MIDlet/vendor listeners from the parser thread.

Existing case 15 is the bounded drain cadence. `RG35XXMediaRegistry.drainNativeEvents()` ultimately returns events through the existing PlatformPlayer listener/fan-out path. No timer, executor, or additional Java event thread is introduced.

## Graceful shutdown gate

A new shutdown opcode is unnecessary and would enlarge protocol surface. The existing parent→Java pipe already has EOF as a terminal condition.

Final Linux deinit policy is therefore:

1. close parent `pWrite[1]` to deliver EOF;
2. Java parser leaves its loop and executes a `finally` barrier;
3. `RG35XXLifecycle.platformShutdown()` performs game unload/RMS force flush/native reset/audio bootstrap shutdown/RMS worker shutdown;
4. Java exits;
5. core waits only for a bounded deinit grace interval;
6. if Java does not exit, retain upstream hard-kill fallback and reap it;
7. native audio worker/pipe, mixer, native event queue, media cache, TSF runtime and SF2 bytes are then torn down in dependency order.

The bounded wait is a shutdown-only fallback, not a gameplay watchdog.

## Reset vs process lifetime

Ordinary game switch resets player/mixer/cache/event state but keeps the shared process-lifetime SF2/TSF runtime alive.

Full `retro_reset()` follows upstream deinit→init→load behavior, so Java EOF shutdown and native media teardown must be idempotent. The replacement process receives a fresh dedicated audio descriptor.

## Static findings closed

The following process-boundary failure modes are now explicitly prevented by source contract:

- audio on stdout;
- direct audio-thread writes into the normal Java control stream;
- partial/ambiguous case-14 payload ownership;
- duplicated native loop ownership;
- function-pointer signature mismatch for the mixer event callback;
- stale events crossing JAR reset;
- hard-killing Java before the RMS/media lifecycle gets any shutdown opportunity;
- inventing another shutdown opcode or reverse IPC channel.

## Remaining gates outside this stage

This stage does **not** claim that the platform can build yet. Remaining blockers include:

- pinned `tml.h` and `tsf.h` still need byte-identical vendoring into the assembled native build;
- an authoritative SoundFont asset/provider is still unresolved;
- patches 0014–0017 must be applied to one exact consolidated core/Java source tree;
- Manager/PlatformPlayer target routing, Tone conversion and capability gating remain to be reconciled;
- `RG35XXFontEngine` remains a registered missing source;
- remaining dirty-frame/input/RMS exact call sites must be assembled;
- Java Ant build and ARMv5TE/uClibc native link must actually run before BUILD-PASS.

## Gate result

`RGJ-RC1-010K`: **STATIC-AUDIT-PASS** for the media process boundary.

Do not promote `RGJ-RC1-010`, `RGJ-RC1-010F`, the whole RC, or the platform to BUILD-PASS/DEVICE-TEST-PASS from this result.
