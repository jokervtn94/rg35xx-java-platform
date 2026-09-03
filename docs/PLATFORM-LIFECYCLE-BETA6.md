# Platform 1.0 Beta 6 — Integration & Lifecycle

## Purpose
Beta 6 does not add another emulator feature. It makes the already-developed subsystems obey one deterministic lifecycle before the consolidated RC build.

## Ownership
`RG35XXLifecycle` coordinates ordering only. Image/font/graphics/input/media/RMS/frame/audio modules retain their own state and implementation.

## Platform start
1. initialize target runtime policy
2. start the single low-priority RMS coordinator
3. audio transport remains attached by the Libretro/JamVM bootstrap path

## Before game load
1. if another game is active, unload it first
2. clear immutable decoded-image cache
3. clear Sprite transform geometry cache
4. reset input held/repeat state
5. reset Java media registry
6. reset dirty-frame generation
7. mark new game active

No persistent RMS files are deleted at game load.

## Pause / destroy barriers
RMS is force-flushed. These barriers are persistence boundaries, not global subsystem destruction.

## Game unload
Ordering is strict:

```text
force RMS flush
      ↓
release/reset Java media registry
      ↓
RESET native media transport/cache/mixer
      ↓
reset input
      ↓
clear image + transform caches
      ↓
reset frame scheduler
```

The audio pipe itself remains attached across game changes; only media state is reset. This avoids repeated process/FD setup while preventing stale voices from leaking into the next MIDlet.

## Platform shutdown
1. unload current game using the same ordered barrier
2. detach/shutdown Java audio transport
3. force-flush and stop RMS writer
4. mark platform inactive

Shutdown is idempotent at the coordinator level. First failure is preserved while later cleanup is still attempted.

## Native side contract
The consolidated libretro integration must mirror Java ordering:
- create dedicated audio pipe before JamVM fork
- initialize media cache/mixer before accepting commands
- game RESET clears mixer before media blobs
- deinit stops/drains worker ownership before pipe/cache destruction
- never close/reuse stdout as audio transport

## Invariants
- PNG tRNS repair survives every lifecycle reset.
- Font resource is immutable and need not be reloaded per game.
- Image/transform caches are per-game disposable acceleration state.
- Held keys/repeat timers never survive game changes.
- RMS persistence survives game changes and is flushed before RAM state disappears.
- Media player IDs/voices/blobs never survive game changes.
- Dirty frame generation restarts cleanly so first frame of a new game is emitted.
- No aggressive watchdog is introduced.

## Consolidated RC gate after Beta 6
Before build/device test, assemble the exact FreeJ2ME source tree and apply all integration patches. Then run static checks for Java 6 syntax/API compatibility, native symbol resolution, protocol parity, lifecycle call sites, no stdout collision, no hot-path SD media staging, and compatibility coverage against the six-game corpus.
