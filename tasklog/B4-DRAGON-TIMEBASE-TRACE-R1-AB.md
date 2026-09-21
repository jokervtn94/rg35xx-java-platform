# B4-DRAGON-TIMEBASE-TRACE-R1-AB

Status: DEVICE-EVIDENCE / DIAGNOSTIC-PASS / STABLE=NO

Primary variable:
BOUNDED_GAME_VIRTUAL_TIME_AND_SLEEP_OBSERVABILITY_ONLY

## Mandatory preflight

CURRENT_SYMPTOM:
- dragon-mania-s40v6 remains visually stuck at the Gameloft startup logo.
- game-owned Thread-1 remains alive and continues serviceRepaints.
- EventProcessing-Thread continues paint callbacks and flushes.
- input down/up is delivered.
- source framebuffer remains static after an early transition.

HISTORY_FOUND:
- historical real-device evidence shows Dragon previously reached thousands of frames and native MIDI activity on RG35XX.
- current RMS corruption, Display/Canvas deadlock, network dependency, media request, stale framebuffer binding, GameCanvas copy and resource/image preload have been separately tested and deprioritized.
- pinned MIDletLoader instruments loaded game bytecode so calls to System.currentTimeMillis(), System.nanoTime(), Thread.sleep() and Thread.yield() are redirected through MIDletEnhancements.

PREVIOUS_FIX:
- B4-DRAGON-RESOURCE-LOAD-TRACE-R1 proved all observed startup resource reads complete.
- 18/18 STREAM_BEGIN entries have matching STREAM_END entries.
- no resource fallback/fail occurs.
- no PlatformImage/ImageIO decode is entered in the observed startup path.

PREVIOUS_EVIDENCE_LEVEL:
- resource/image preload: DEVICE-EVIDENCE / DIAGNOSTIC-PASS.
- GameCanvas/frontbuffer bridge: DEVICE-EVIDENCE / DIAGNOSTIC-PASS.
- Dragon compatibility: FAIL.
- full platform: STABLE=NO.

REGRESSION_RISK:
- virtual time is a high-impact compatibility layer shared by game code.
- no timing correction may be introduced without device evidence.
- protected JamVM L, glibj.zip, B4 core, Video Mask R2, Hotpath R2, canonical framebuffer binding, RMS state and prior diagnostics must remain unchanged.

MINIMAL_PROPOSED_CHANGE:
- instrument MIDletEnhancements only.
- observe currentTimeMillis returned values, wall time, last time, elapsed delta and virtual accumulator.
- observe nanoTime with the same fields.
- observe requested sleep/drawSleep duration versus wall-clock elapsed duration.
- observe yieldOverride duration.
- record thread name and active fast-forward/framerate flags.
- emit any negative time delta even outside the normal bounded sampling window.
- do not alter virtual-time arithmetic.
- do not alter sleep/yield behavior.

EXPECTED_DEVICE_TEST:
- negative elapsed or backward/abnormal virtual-time progression => timing layer becomes primary suspect.
- requested sleep differs materially from actual behavior under unlock=0/fast=false => sleep layer becomes primary suspect.
- time remains monotonic and approximately wall-clock while game remains at logo => timebase is deprioritized and next checkpoint moves to game-owned state/monitor synchronization.

## Entering device evidence

B4-DRAGON-RESOURCE-LOAD-TRACE-R1 evidence:
- runtime SHA256: ac027e8ac5f5cf0360aa509d966d7f7c40323a595b34fea85003d2c80d0c7c10
- core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- RMS_PRECONDITION=PASS
- RESOURCE_STREAM_BEGIN=18
- RESOURCE_STREAM_END=18
- RESOURCE_STREAM_FALLBACK=0
- IMAGE_DECODE_LINES=0
- minimum resource elapsed=34 ms
- maximum resource elapsed=222 ms
- total observed resource elapsed≈1934 ms
- Thread-1 continues after the last resource read
- source framebuffer remains static after resource completion

## Instrumentation contract

MIDletEnhancements.currentTimeMillis:
- wallNow
- lastBefore
- elapsed
- virtual accumulator before/after
- returned time
- unlockFramerateHack
- limitFPS
- fast-forward key state
- negativeElapsed

MIDletEnhancements.nanoTime:
- same corresponding fields in nanoseconds

MIDletEnhancements.sleep/drawSleep:
- requestedMs
- wallElapsedMs
- thread
- unlock/fast flags

MIDletEnhancements.yieldOverride:
- wallElapsedMs
- thread

Bounded logging:
- first 128 timing events
- then power-of-two timing sequence numbers
- negative elapsed deltas always logged

Marker:
RG35XX-B4-TIMEBASE

## Preserved

- FreeJ2ME pin 13ec186903087156c145268f8706eecfaf9f1e50
- JamVM L
- GNU Classpath glibj.zip
- protected B4 native core
- Video Mask R2
- Hotpath R2
- lazy media boot
- Display/Canvas diagnostics
- network diagnostics
- media diagnostics
- PNG iCCP compatibility
- canonical framebuffer binding
- GameCanvas flush diagnostics
- resource/image diagnostics
- current RMS semantics/state
- screenshot baseline state

## Device procedure after BUILD-PASS

1. install the fail-closed runtime-only package.
2. reboot RG35XX.
3. run ONLY dragon-mania-s40v6.
4. leave Gameloft logo untouched for 30 seconds.
5. press one normal action key once.
6. wait about 5 seconds.
7. exit normally if possible.
8. do not launch another Java game.
9. collect evidence immediately.

Hard-hang rule:
If reset is required, checkpoint is FAIL and cannot be DEVICE-PASS.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.


## Build result — 2026-09-21

Source/head commit used for artifact:
bac82906ede5f2f48ba5af22dd8a3e29564c1c49

Workflow:
- name: B4 Dragon Timebase Trace R1 A-B
- run: 35616903674
- job: 106389806707
- conclusion: SUCCESS

Artifact:
- id: 10645809647
- name: b4-dragon-timebase-trace-r1-ab
- artifact ZIP SHA256/digest: 01141124cf8a22eb10872f0be0508eb898dcd3f09ea4c56cafb960e334c80e8c

Runtime:
- freej2me-lr.jar SHA256: 86213649b09ce6fca7c55bd14131384a6f8eac07b9896c8a40d9fa1aa5538675
- required previous runtime: ac027e8ac5f5cf0360aa509d966d7f7c40323a595b34fea85003d2c80d0c7c10
- Java classes: 1334
- Java major 50 gate: PASS

Protected foundation:
- core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- core packaged: NO
- JamVM L expected: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj expected: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

Gates:
- exact current B4 traced source reproduction: PASS
- resource/image diagnostics preserved: PASS
- timebase source scope gate: PASS
- Java 6-compatible build: PASS
- bytecode marker gate: PASS
- fail-closed runtime-only installer: PASS
- packaged SHA256SUMS verification outside CI: PASS

Exact behavioral scope:
- currentTimeMillis arithmetic unchanged
- nanoTime arithmetic unchanged
- sleep/drawSleep behavior unchanged
- yieldOverride behavior unchanged
- no native/core/audio/font/network/RMS/render behavior change

BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO


## Device result — 2026-09-21 22:52

Evidence:
B4-DRAGON-TIMEBASE-TRACE-R1-EVIDENCE-20260921-225245.zip

Protected/install hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- protected B4 core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- runtime: 86213649b09ce6fca7c55bd14131384a6f8eac07b9896c8a40d9fa1aa5538675
- RMS_PRECONDITION=PASS
- total Dragon metadata=7
- prior recreated store remains structurally valid

Timebase observations:
- TIMEBASE_LINES=151
- MILLIS samples=111
- NANOS=0
- SLEEP pairs=1
- DRAWSLEEP pairs=19
- YIELD=0
- NEGATIVE_ELAPSED=0
- every sampled currentTimeMillis returned exactly wallNow
- unlockFramerateHack=0 throughout sampled calls
- limitFPS=60 throughout sampled calls
- fast-forward=false throughout sampled calls
- sleep/drawSleep requested-vs-wall delta=0..2 ms
- no unmatched sleep begin/end
- no exception/error observed

Thread distribution for sampled currentTimeMillis:
- EventProcessing-Thread: 65
- Thread-1: 43
- Libretro-IO-Thread: 3

Interpretation:
- virtual currentTimeMillis is monotonic in the observed run.
- no negative/backward virtual-time delta is observed.
- sleep behavior is materially consistent with requested duration.
- timebase/sleep is DEPRIORITIZED as the Dragon logo blocker.
- Dragon compatibility remains FAIL.
- STABLE=NO.

Additional cross-check discovered from existing R13H evidence:
- SERVICE_WAIT_WAKE count=13
- wake with needsRepaint still true (aux=1)=2
- both aux=1 wakes are followed immediately by REPAINT_REQUEST_BEGIN on Thread-1.
- observed pairs:
  - service seq=2 wake aux=1 -> repaint request seq=2 on Thread-1
  - service seq=7 wake aux=1 -> repaint request seq=8 on Thread-1
- this behavior follows pinned Canvas.serviceRepaints fallback: after any wait return, if needsRepaint is true it calls repaintRequest() on caller thread without distinguishing normal paint-completion notification from timeout.
- during the second case EventProcessing-Thread is still completing a paint/flush while Thread-1 starts another paint path.
- resource /16 ownership changes between repeated runs depending on this scheduling race:
  - Resource-load checkpoint: /16 observed on Thread-1.
  - Timebase checkpoint: /16 observed on EventProcessing-Thread until service fallback transfers another repaint to Thread-1.
- source framebuffer remains static at 8545ff47.

Next checkpoint:
B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1-AB

Primary hypothesis:
serviceRepaints fallback decision allows caller-thread paint takeover after a normal completion wake, and may allow overlapping paint paths while another paint callback is active.

No unrelated rendering/media/resource/timebase behavior change is authorized.
