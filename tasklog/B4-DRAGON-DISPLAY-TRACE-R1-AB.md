# B4-DRAGON-DISPLAY-TRACE-R1-AB

Status: BUILD-PASS / DEVICE-TRACE-PENDING / STABLE=NO

Primary variable:
BOUNDED_DISPLAY_CANVAS_GAME_LOOP_OBSERVABILITY_ONLY

## Current evidence

B4-DRAGON-MEDIA-TRACE-R1 device evidence established:
- Dragon Mania remains frozen at the Gameloft startup screen.
- Dragon's session emits no Manager.createPlayer / Player realize / prefetch / start media trace before exit.
- The later getSequencer failure belongs to 240x320-zombie_infection-s60, not Dragon.
- RMS StringIndexOutOfBoundsException storm remains absent.
- one previously zero-byte RMS basename has been recreated as structurally valid non-zero metadata (387 bytes), so filename alone is not a corruption criterion.

Therefore media is deprioritized for the Dragon logo freeze.

## Historical trace source

This checkpoint reuses existing trace-only instrumentation scripts already retained in the repository:
- vc7r22r13e_apply_midlet_event_trace.py
- vc7r22r13f_apply_setcurrent_trace.py
- vc7r22r13h_apply_service_repaints_trace.py

These scripts alter observability only.

## Trace scope

Display / current screen:
- setCurrent request and runnable boundaries
- showNotify
- current assignment / hideNotify
- initial repaint and flush
- Display paint dispatch

Canvas/game loop:
- repaintRequest entry
- game paint callback begin/done
- repaint flush begin/done
- serviceRepaints entry
- event-thread repaint
- paintLock acquisition
- paintLock wait/wake

Input:
- libretro Java receive
- MobilePlatform enqueue
- Display dispatch
- callback begin/done

Existing B4 media trace remains present only as a diagnostic control.

## Preserved subsystems

No behavioral changes are allowed to:
- native core
- B4 Video Mask R2
- B4 Hotpath R2
- media/audio behavior
- RMS behavior
- JamVM
- GNU Classpath
- game files
- screenshot behavior

## Device test

Install only from current Media Trace R1 runtime:
0c2f8658e7786cd3f97285c94c609623464cb8f04311b359bfd0a95a7109f11e

Then run ONLY:
dragon-mania-s40v6

At the Gameloft logo:
- wait approximately 20–30 seconds;
- press one normal action key once if the screen remains frozen;
- wait approximately 5 seconds;
- exit normally if possible;
- collect immediately without launching another Java game.

The trace should determine whether the game is:
- repeatedly painting the same logo;
- blocked inside the paint callback;
- blocked in serviceRepaints/paintLock;
- no longer requesting paint;
- or still receiving input while its display loop is stalled.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.


## Build result — 2026-09-21

- source commit: 4e1e34e817d3353e8838561bd3168b5436c6d647
- workflow/run: 35575304939
- job: 106255675564
- artifact: 10627995337
- artifact SHA256: 46cdea13e5b9b0815456378f97b93430d8dc5f121e50fe53dce89d9326bce39c
- runtime SHA256: c6f2c8c71fdb120dac1b8193952d0839dc4cd6877ba8c2e120f606cfb087faab
- required current runtime before install: 0c2f8658e7786cd3f97285c94c609623464cb8f04311b359bfd0a95a7109f11e
- protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java classes: 1334
- Java major 50 gate: PASS
- display/canvas source trace gate: PASS
- display/canvas bytecode marker gate: PASS
- media trace preserved: YES
- media behavior change: NONE
- RMS behavior change: NONE
- native core change: NONE
- BUILD-PASS: YES
- DEVICE-PASS: NO / DEVICE-TRACE-PENDING
- STABLE: NO
