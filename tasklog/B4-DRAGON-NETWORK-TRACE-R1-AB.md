# B4-DRAGON-NETWORK-TRACE-R1-AB

Status: BUILD-PASS / DEVICE-TRACE-PENDING / STABLE=NO

Primary variable:
BOUNDED_NETWORK_DEPENDENCY_OBSERVABILITY_ONLY

## Current evidence

B4-DRAGON-DISPLAY-TRACE-R1 established on device:
- Dragon Mania remains visually frozen at the Gameloft startup logo;
- Display event processing remains alive;
- Canvas paint callbacks continue and return;
- repaint flushes continue;
- serviceRepaints/paintLock has no sampled deadlock;
- input is received, queued, dispatched and delivered;
- no media request is reached;
- RMS exception storm is absent.

Therefore the visible freeze is a game-state/dependency stall, not a Display/Canvas/render/input deadlock.

## Network candidate

Pinned FreeJ2ME routes http/https/socket through:
Connector -> HttpConnectionImpl

Current pinned behavior includes:
- network branch object construction;
- HTTP connect stub;
- HTTP response code stub returning 200;
- openInputStream returning null;
- openOutputStream returning null.

A game can therefore remain alive/rendering while waiting on or mishandling a network-dependent startup state without a Display deadlock.

## Historical trace source

Reuse retained trace-only script:
scripts/vc7r22r13i_apply_network_dependency_trace.py

It adds bounded/transition diagnostics only and changes no network semantics.

## Trace scope

- Connector.open begin
- network protocol branch
- connection construction/done
- HttpConnectionImpl constructor
- connect
- response code stub
- null input stream request
- null output stream request

Existing media and Display/Canvas traces remain present as controls.

## Device test

Precondition runtime:
c6f2c8c71fdb120dac1b8193952d0839dc4cd6877ba8c2e120f606cfb087faab

Run ONLY:
dragon-mania-s40v6

At Gameloft logo:
- wait 20-30 seconds;
- press one normal action key once;
- wait 5 seconds;
- exit normally if possible;
- do not launch another Java game;
- collect immediately.

Interpretation:
- any RG35XX-R13I-NET record before/while logo is frozen => network dependency is active and next checkpoint can localize exact stub behavior;
- zero network trace while display/game paint stays alive => network is deprioritized and the next dependency trace moves deeper into game state/thread/timing/resource startup.

No network behavior change.
No RMS behavior change.
No display behavior change.
No media behavior change.
No native core change.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.


## Build result — 2026-09-21

- source commit: 6bfeb289a7443a0d201f29ac933a1406fe416a4a
- workflow/run: 35576780017
- job: 106260296452
- artifact: 10628707308
- artifact SHA256: 252cd07d9c01cdff69996936465d2d90dd8973f26382f4b23fe8b39c210b192b
- runtime SHA256: e92ac328772f0ed5aa359435b37a30aa58f5b490714b290ea2e5bb19b91dd8a0
- required current runtime before install: c6f2c8c71fdb120dac1b8193952d0839dc4cd6877ba8c2e120f606cfb087faab
- protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java classes: 1334
- Java major 50 gate: PASS
- network trace source gate: PASS
- network trace bytecode gate: PASS
- Display/Canvas trace preserved: YES
- media trace preserved: YES
- network behavior change: NONE
- RMS behavior change: NONE
- native core change: NONE
- BUILD-PASS: YES
- DEVICE-PASS: NO / DEVICE-TRACE-PENDING
- STABLE: NO


## Device trace result — 2026-09-21 15:19

Evidence:
B4-DRAGON-NETWORK-TRACE-R1-EVIDENCE-20260921-151925.zip
ZIP SHA256: 309be99944681a8b5de62a890df360ff3a0fa87e89b4b7e8915a4a98d6e68abb

Installed hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- protected core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- network-trace runtime: e92ac328772f0ed5aa359435b37a30aa58f5b490714b290ea2e5bb19b91dd8a0

RMS:
- precondition PASS
- total Dragon metadata: 7
- ffffffff9c61314e09vhjlzvf1zxn0.rms remains structurally valid, non-zero, 387 bytes
- second previously corrupt store remains absent
- no RMS mutation by trace installer

Java:
- total lines: 354
- NETWORK_TRACE_LINES=0
- CONNECTOR_OPEN_BEGIN=0
- CONNECTOR_NETWORK_BRANCH=0
- CONNECTOR_OPEN_DONE=0
- HTTP_CTOR=0
- HTTP_CONNECT=0
- HTTP_RESPONSE_CODE_STUB=0
- HTTP_INPUT_STREAM_NULL=0
- HTTP_OUTPUT_STREAM_NULL=0
- DISPLAY_EVENT_TRACE_LINES=69
- CANVAS_LOOP_TRACE_LINES=280
- MEDIA_TRACE_LINES=0
- STRING_INDEX_OOB=0
- NPE=0

Device result:
Dragon Mania remains visually stuck at the Gameloft startup logo while the same Display/Canvas loop behavior continues.

Conclusion:
- network dependency path is NOT reached in the observed frozen-logo window;
- HTTP/socket stubs are therefore not the immediate cause of this Dragon startup stall;
- media remains not reached;
- RMS exception storm remains absent;
- Display/Canvas/input remain alive from the previous checkpoint.

Checkpoint classification:
- B4-DRAGON-NETWORK-TRACE-R1: DEVICE-EVIDENCE / DIAGNOSTIC PASS
- network as current logo-freeze cause: DEPRIORITIZED
- Dragon compatibility DEVICE-PASS: NO
- STABLE: NO

History comparison before next change:
The clean B4 foundation intentionally excludes PNG iCCP compatibility. Historical device logs for the same dragon-mania-s40v6 session contain:
RG35XX-PNG-ICCP: stripped ancillary iCCP chunk
before later game rendering/audio activity.

Separately, project history proved the pinned GNU Classpath PNG reader can abort on ICC v4 metadata with:
java.lang.IllegalArgumentException: Wrong major version number:4

The project rules now list PNG iCCP compatibility among accepted video compatibility knowledge.

Therefore the next minimal A/B is not another speculative dependency trace. It is a single historical compatibility delta:
B4-DRAGON-PNG-ICCP-R1-AB

Primary variable:
PNG_ICCP_COMPATIBILITY_ONLY

Expected test:
- keep current network/display/media diagnostic controls;
- add only the proven ancillary iCCP stripping boundary at PlatformImage ImageIO reads;
- run Dragon Mania only;
- if RG35XX-PNG-ICCP marker appears and the game progresses beyond the Gameloft logo, causal evidence is strong;
- if marker appears but logo remains stuck, retain compatibility fix separately and continue to the next historical image compatibility delta;
- if marker never appears, this checkpoint does not explain the startup stall.

STABLE remains NO.
