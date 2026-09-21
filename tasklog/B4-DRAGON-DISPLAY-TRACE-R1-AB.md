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


## Device trace result — 2026-09-21 15:09

Evidence:
B4-DRAGON-DISPLAY-TRACE-R1-EVIDENCE-20260921-150956.zip

Installed hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- protected B4 core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- display-trace runtime: c6f2c8c71fdb120dac1b8193952d0839dc4cd6877ba8c2e120f606cfb087faab

RMS:
- RMS_PRECONDITION=PASS
- total Dragon metadata: 7
- previously corrupt basename ffffffff9c61314e09vhjlzvf1zxn0 recreated as structurally valid non-zero metadata
  length=387
  SHA256=b51f52e3639dfa6bfa09b550f4b281356d6b6b1a9c8a57885d36961160906c74
  ids=0
- second previously corrupt basename remains absent
- trace installer changed no RMS data

Dragon-only Java trace:
- Java log lines: 353
- media trace lines: 0
- display event trace lines: 69
- Canvas loop trace lines: 279
- NPE: 0
- StringIndexOutOfBoundsException: 0
- getSequencer errors: 0

Display/current-screen evidence:
- SETCURRENT_REQUEST=2
- SETCURRENT_RUN_BEGIN=2
- SETCURRENT_RUN_DONE=1
- first setCurrent executes showNotify, assignment, flush and completes
- second setCurrent reaches SC_PREV_READ_DONE then does not enter SC_PREP_BEGIN
- pinned Display.setCurrent has an immediate return at this exact boundary when next==null or current==next
- because aux shows a current object and the game requested another displayable, the observed pattern is consistent with current==next: a legal no-op, not a blocked setCurrent runnable

Canvas/render evidence:
- DISPLAY_PAINT_BEGIN/DONE = 17/17 in bounded sample
- REPAINT_REQUEST_BEGIN = 33
- PAINT_CALLBACK_BEGIN/DONE = 30/30
- REPAINT_FLUSH_BEGIN/DONE = 30/30
- REPAINT_REQUEST_DONE = 30
- sequence 120 is later reached for repaint, paint callback, flush, serviceRepaints and Display paint
- therefore rendering continues well after the Gameloft logo becomes visibly static

serviceRepaints/locking:
- SERVICE_LOCK_BEGIN/ACQUIRED = 20/20
- SERVICE_WAIT_BEGIN/WAKE = 5/5
- no unmatched sampled wait or lock acquisition
- no evidence of paintLock deadlock

Input:
- LR_RX_DOWN/UP = 1/1
- MP_POST_DOWN/UP = 1/1
- Display enqueue and dispatch both complete
- MP_DELIVER_DOWN_BEGIN/DONE = 1/1
- MP_DELIVER_UP_BEGIN/DONE = 1/1
- therefore the frozen-logo session still receives and delivers user input through the Java callback path

Conclusion:
- Display event thread: ALIVE
- Canvas paint callback: ALIVE / RETURNS
- framebuffer flush requests: CONTINUE
- serviceRepaints/paintLock: NO DEADLOCK EVIDENCE
- input path: ALIVE / DELIVERED
- media request path: NOT REACHED
- RMS exception storm: ABSENT
- visible Gameloft logo freeze: PERSISTS

The visible freeze is therefore a game-state/dependency stall rather than a Display/Canvas/render/input deadlock.

Checkpoint classification:
- B4-DRAGON-DISPLAY-TRACE-R1: DEVICE-EVIDENCE / DIAGNOSTIC PASS
- Display/Canvas as root cause: DEPRIORITIZED
- Dragon compatibility DEVICE-PASS: NO
- STABLE: NO

Next checkpoint:
B4-DRAGON-NETWORK-TRACE-R1-AB

Primary variable:
BOUNDED_NETWORK_DEPENDENCY_OBSERVABILITY_ONLY

Rationale:
Pinned FreeJ2ME exposes http/https/socket via Connector -> HttpConnectionImpl with stubbed behaviors including HTTP response code 200 and null input/output streams. The retained historical R13I trace can determine whether Dragon requests network connectivity while its game/display loop continues on the Gameloft logo.

No network behavior change is permitted.
