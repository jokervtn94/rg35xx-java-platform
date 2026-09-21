# B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1-AB

Status: BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO

Primary variable:
SERVICEREPAINTS_COMPLETION_WAKE_AND_ACTIVE_PAINT_SERIALIZATION

## Mandatory preflight

CURRENT_SYMPTOM:
- dragon-mania-s40v6 remains visually stuck at the Gameloft startup logo.
- Thread-1 remains alive.
- EventProcessing-Thread remains alive.
- paint callbacks and framebuffer flushes continue.
- input delivery remains alive.
- source framebuffer becomes and remains static at the same hash.
- no network/media request is reached.

HISTORY_FOUND:
- historical real-device evidence shows Dragon previously progressed beyond startup on RG35XX and reached native MIDI playback.
- RMS corruption, media, network, Display/Canvas deadlock, PNG iCCP, framebuffer binding, GameCanvas frontbuffer copy, resource loading and virtual time/sleep have been separately tested.
- the pinned FreeJ2ME Canvas.serviceRepaints implementation calls paintLock.wait(1000), then if needsRepaint remains true immediately invokes repaintRequest() on the caller thread.
- the implementation does not distinguish a normal notify caused by a just-completed paint callback from an actual one-second timeout.
- upstream current devel still contains the same fallback structure.

PREVIOUS_FIX:
- B4-DRAGON-TIMEBASE-TRACE-R1 proved currentTimeMillis is monotonic and matches wall clock in sampled calls.
- sleep/drawSleep completes within 0..2 ms of requested duration.
- no negative time delta, fast-forward, nanoTime or yield anomaly is observed.

PREVIOUS_EVIDENCE_LEVEL:
- timebase/sleep: DEVICE-EVIDENCE / DIAGNOSTIC-PASS.
- resource/image preload: DEVICE-EVIDENCE / DIAGNOSTIC-PASS.
- GameCanvas/frontbuffer bridge: DEVICE-EVIDENCE / DIAGNOSTIC-PASS.
- Dragon compatibility: FAIL.
- full platform: STABLE=NO.

DEVICE EVIDENCE FOR THIS HYPOTHESIS:
- R13H SERVICE_WAIT_WAKE count=13.
- 2 wakes return with needsRepaint still true (aux=1).
- both aux=1 wakes are immediately followed by REPAINT_REQUEST_BEGIN on Thread-1.
- observed service seq=2 -> repaint request seq=2 on Thread-1.
- observed service seq=7 -> repaint request seq=8 on Thread-1.
- in the second case EventProcessing-Thread is still completing the prior paint/flush while Thread-1 begins another paint callback.
- /16 resource ownership changes between runs depending on this race:
  - resource-load run: /16 on Thread-1.
  - timebase run: /16 initially on EventProcessing-Thread before caller-thread fallback.
- this is direct evidence that paint execution can migrate across threads due serviceRepaints fallback timing.

SPEC ALIGNMENT:
- MIDP Canvas.serviceRepaints is defined to block until pending repaint requests have been serviced.
- MIDP UI/event callbacks are serialized, with serviceRepaints being the special synchronous repaint mechanism.
- the checkpoint aims to preserve that serialization rather than alter game logic.

REGRESSION_RISK:
- Canvas.repaint/serviceRepaints is shared platform behavior.
- the existing one-second rescue path may help jars whose event thread truly stalls.
- therefore this checkpoint must preserve the rescue fallback when no paint completion occurs and no paint callback is active.
- no changes are permitted to normal EDT repaint scheduling, graphics copy, framebuffer ownership, media, network, RMS, timebase, audio, font or native core.

MINIMAL_PROPOSED_CHANGE:
- add per-Canvas paint-completion generation.
- add per-Canvas paint-callback-active state.
- publish completion generation before notifyAll in repaintRequest finally.
- after serviceRepaints wait returns:
  - if a paint completion generation changed and repaint remains pending, continue waiting for the newly pending repaint instead of forcing caller-thread paint.
  - if another paint callback is still active, continue waiting and never overlap a forced paint with it.
  - if no paint completed during the wait and no paint callback is active, preserve the existing rescue fallback and call repaintRequest.
- add bounded marker RG35XX-B4-SERVICE-SERIAL.
- preserve all previous diagnostics.

EXPECTED_DEVICE_TEST:
- SUPPRESS_AFTER_COMPLETION should appear where prior evidence showed caller-thread takeover.
- SUPPRESS_WHILE_PAINT_ACTIVE may appear if the 1-second wait expires while EDT is still painting.
- normal paint callbacks should remain serialized.
- FORCE_FALLBACK should occur only if no paint completion was observed and no paint callback is active.
- if Dragon progresses beyond the Gameloft logo, this checkpoint gains DEVICE-EVIDENCE for the compatibility fix.
- if Dragon remains stuck but caller-thread takeover disappears, the serialization bug is fixed locally but is not sufficient for Dragon; next analysis proceeds from the now-clean paint-thread model.

## Preserved foundation

- FreeJ2ME pin: 13ec186903087156c145268f8706eecfaf9f1e50
- JamVM L SHA256: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip SHA256: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- protected B4 core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- previous runtime SHA256: 86213649b09ce6fca7c55bd14131384a6f8eac07b9896c8a40d9fa1aa5538675
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
- timebase diagnostics
- current valid Dragon RMS state

## Device procedure after BUILD-PASS

1. install the fail-closed runtime-only package.
2. reboot RG35XX.
3. run ONLY dragon-mania-s40v6.
4. leave the Gameloft logo untouched for 30 seconds, unless it progresses.
5. if the game progresses, continue until the first interactive/menu screen and press one normal action key.
6. if it does not progress, press one normal action key once after 30 seconds.
7. wait about 5 seconds.
8. exit normally if possible.
9. do not launch another Java game.
10. collect evidence immediately.

Hard-hang rule:
If reset is required, checkpoint is FAIL and cannot be DEVICE-PASS.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.


## Build result — 2026-09-21

Source/head commit used for artifact:
9f1c94dfc8c338ea9fb0684586d9215db07323bf

Workflow:
- name: B4 Dragon Service Repaint Serialize R1 A-B
- run: 35623424954
- job: 106411801812
- conclusion: SUCCESS

Artifact:
- id: 10649299927
- name: b4-dragon-service-repaint-serialize-r1-ab
- artifact ZIP SHA256/digest: b9c4bc5f441505e5c4e5f49c8e9b479db9d2e5ecc31a9fd7f3b794312a58a90c

Runtime:
- freej2me-lr.jar SHA256: f4609edf503a326741f60238d0917a35998f3aa780a77b0730663888619d3f99
- required previous runtime: 86213649b09ce6fca7c55bd14131384a6f8eac07b9896c8a40d9fa1aa5538675
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
- timebase diagnostics preserved: PASS
- serviceRepaints serialization source scope gate: PASS
- Java 6-compatible build: PASS
- bytecode marker gate: PASS
- fail-closed runtime-only installer: PASS
- packaged SHA256SUMS verification outside CI: PASS (9/9)

Exact behavioral scope:
- Canvas.serviceRepaints rescue decision only
- normal EDT repaint path unchanged
- a paint-completion wake no longer transfers pending paint to caller thread
- forced rescue is suppressed while another paint callback is active
- one-second rescue fallback remains when no paint completes and no paint callback is active
- currentTimeMillis/nanoTime/sleep/yield behavior unchanged
- resource/image loading unchanged
- GameCanvas/frontbuffer behavior unchanged
- native core/audio/font/network/RMS/media behavior unchanged

BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
