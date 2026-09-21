# B4-DRAGON-RESOURCE-LOAD-TRACE-R1-AB

Status: BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO

Primary variable:
BOUNDED_RESOURCE_AND_IMAGE_DECODE_OBSERVABILITY_ONLY

## Mandatory preflight

CURRENT_SYMPTOM:
- dragon-mania-s40v6 remains visually stuck at the Gameloft startup logo.
- Display/Canvas repaint continues.
- input down/up is delivered.
- GameCanvas source content makes an early transition, then remains static.

HISTORY_FOUND:
- RMS zero-length corruption was real and its exception storm was removed, but the logo stall remained.
- media request path, network path, Display/Canvas deadlock, serviceRepaints deadlock, PNG iCCP in the observed Dragon runs, stale framebuffer binding and GameCanvas->frontbuffer copy have all been separately tested/deprioritized.
- historical real-device evidence from 2026-09-06 shows Dragon Mania once reached a substantially later state: thousands of video frames plus native MIDI PLAY/PRIMED/END activity.

PREVIOUS_FIX:
- B4-DRAGON-GAMECANVAS-FLUSH-R1-AB proved full-screen source->frontbuffer copies complete with equal sparse hashes.
- source and destination are distinct arrays, but every observed full-copy result exactly matches the source.

PREVIOUS_EVIDENCE_LEVEL:
- GameCanvas/frontbuffer bridge: DEVICE-EVIDENCE / DIAGNOSTIC-PASS.
- Dragon compatibility: FAIL.
- full platform: STABLE=NO.

REGRESSION_RISK:
- restoring an entire historical RC1/CJ/VC7 stack is forbidden: those stacks combine unrelated audio/graphics/lifecycle experiments and later-known regressions.
- protected JamVM L, glibj.zip, B4 core, Video Mask R2, Hotpath R2, canonical framebuffer binding and current RMS state must not change.

MINIMAL_PROPOSED_CHANGE:
- add bounded BEGIN/END timing and thread/resource metadata around MIDlet resource reads.
- add bounded BEGIN/END timing around actual PlatformImage ImageIO decode constructors.
- no path-resolution change.
- no stream-read algorithm change.
- no image normalization change.
- no cache change.
- no PNG semantic change.
- no render/GameCanvas/framebuffer/native/audio/font/RMS/network change.

EXPECTED_DEVICE_TEST:
- unmatched RESOURCE BEGIN without END => identify the exact resource boundary that stalls.
- unmatched IMAGE_DECODE BEGIN without END => identify the exact decode boundary that stalls.
- very large elapsedMs => identify a blocking/slow preload boundary.
- all BEGIN/END pairs complete => resource/image preload is deprioritized; next investigation moves to game-owned timer/background-thread state.

## Entering device evidence

B4-DRAGON-GAMECANVAS-FLUSH-R1 evidence:
- runtime SHA256: fa953382169425b087418a09a6d496c142a86f5e2e5c75af760d0b8d263a41f0
- protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- MOBILE_FLUSH_LINES=33
- PG_BEFORE=33
- PG_FULLCOPY_DONE=33
- PG_ALIAS_RETURN=0
- FRAME_BIND_MISMATCH_TRUE=0
- seq 3 source hash changes from c67c4940 to 8545ff47.
- seq 3 destination changes to 8545ff47 and equalHash=true.
- seq 4..32 and 64 remain source=destination=8545ff47.
- all sampled rectangles are 0,0,240,320.
- paused=false and terminated=false.
- media/network/PNG exception counters remain zero for the Dragon session.

Interpretation:
- Case E: Java full-copy bridge works.
- Case C: game-owned source content itself becomes static.
- do not introduce a GameCanvas copy fix.

## Instrumentation contract

MIDletLoader:
- getMIDletResourceAsStream:
  STREAM_BEGIN / STREAM_END / STREAM_FALLBACK
- getMIDletResourceAsByteArray:
  BYTES_BEGIN / BYTES_END / BYTES_FAIL

PlatformImage:
- resource-name constructor:
  NAME_BEGIN / NAME_END
- InputStream constructor:
  STREAM_BEGIN / STREAM_END
- byte-array constructor:
  BYTES_BEGIN / BYTES_END

Each record includes as applicable:
- bounded sequence
- current thread name
- original/resolved resource
- byte count or decoded WxH
- elapsedMs

Logging budget:
- first 128 events
- then powers of two only
- exceptions/fallbacks remain visible
- no unbounded per-frame logging

Markers:
- RG35XX-B4-RESOURCE-TRACE
- RG35XX-B4-IMAGE-DECODE

## Preserved

- FreeJ2ME pin 13ec186903087156c145268f8706eecfaf9f1e50
- JamVM L
- GNU Classpath glibj.zip
- protected B4 native core
- Video Mask R2
- Hotpath R2
- lazy media boot
- existing media/network/Display/Canvas diagnostics
- PNG iCCP compatibility
- canonical framebuffer binding
- GameCanvas flush diagnostics
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
If a reset is required, checkpoint is FAIL and cannot be DEVICE-PASS.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.


## Build result — 2026-09-21

Source/head commit:
1fa21f0743dff859d9aa449e6d98a55fe7f4b990

Workflow:
- name: B4 Dragon Resource Load Trace R1 A-B
- run: 35590268671
- job: 106302834637
- conclusion: SUCCESS

Artifact:
- id: 10634595413
- name: b4-dragon-resource-load-trace-r1-ab
- artifact ZIP SHA256/digest: 86a6b2479a1fe302ea87925fe82ba78b58840c6c2260655f7e022545c750740e

Runtime:
- freej2me-lr.jar SHA256: ac027e8ac5f5cf0360aa509d966d7f7c40323a595b34fea85003d2c80d0c7c10
- previous required runtime: fa953382169425b087418a09a6d496c142a86f5e2e5c75af760d0b8d263a41f0
- Java classes: 1334
- Java major 50 gate: PASS

Protected native foundation:
- core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- core packaged: NO
- JamVM L expected: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj expected: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

Gates:
- exact current B4 trace source reproduction: PASS
- resource/image trace source scope gate: PASS
- Java 6-compatible build: PASS
- bytecode marker gate: PASS
- fail-closed installer package: PASS
- package SHA256SUMS verification: PASS

Exact scope of change:
- bounded resource read BEGIN/END/FALLBACK diagnostics.
- bounded PlatformImage decode BEGIN/END diagnostics.
- no resource-path behavior change.
- no image decode/normalization behavior change.
- no GameCanvas/render/framebuffer/native/audio/font/network/RMS behavior change.

BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
