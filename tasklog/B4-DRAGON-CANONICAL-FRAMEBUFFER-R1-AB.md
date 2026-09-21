# B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-AB

Status: BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO

Primary variable:
CURRENT_FRONTBUFFER_OBJECT_AND_DATA_BOUND_TOGETHER_AT_TRANSPORT_REQUEST

## Current evidence

Dragon Mania still presents a static Gameloft startup image while:
- Canvas paint callbacks continue and return;
- flush calls continue;
- input continues to be delivered;
- RMS exception storm is absent;
- media is not reached;
- network is not reached;
- PNG iCCP compatibility is installed but not exercised.

The latest PNG-iCCP checkpoint produced two Dragon sessions with:
- 0 PNG iCCP strip markers
- 0 network trace
- 0 media trace
- 0 StringIndexOutOfBoundsException
- 0 NullPointerException
- continued Canvas/Display activity through bounded seq=120

## Historical evidence

Pinned/current B4 Golden transport is based on g1_apply_java_transport.py.

That overlay caches:

lcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();

and later submits frames as:

rg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,
    Mobile.getPlatform().getLcdFrontbuffer());

This combines a cached int[] with a separately fetched current PlatformImage lock object.

Historical VC7R11 device evidence proved that after JAR load these can diverge:
PlatformGraphics may render into one backing int[] while the Golden transport serializes a different stale backing int[].

Historical VC7R12 corrected this by fetching the current LCD PlatformImage and its backing int[] together for every transport request.

This failure mode directly matches the current symptom class:
Java game/display loop can remain alive while visible output stays stale.

## Minimal B4 correction

For every normal frame request:
1. fetch current MobilePlatform.getLcdFrontbuffer();
2. fetch current front.getDataBuffer();
3. rebind legacy lcdData to that current array;
4. submit exactly that current array and that same front object to RG35XXGoldenFrameTransport.

Apply the same ownership rule to control frames.

Bounded evidence marker:
RG35XX-B4-FRAME-BIND

Fields:
- stage REQUEST / CONTROL
- sequence
- frontId
- cachedBeforeDataId
- currentDataId
- previousCurrentDataId
- changed
- mismatch
- logical size

Logging policy:
first 16 frame-bind events, or backing identity change, or cached/current mismatch.
No unbounded per-frame log.

## Preserved

- JamVM L
- glibj.zip
- protected B4 native core
- Video Mask R2
- Hotpath R2
- current RMS state
- media behavior
- network behavior
- Display/Canvas behavior
- PNG iCCP compatibility from previous checkpoint
- screenshot baseline state

No headless image normalization.
No GameCanvas/frontbuffer historical patches beyond this exact transport ownership correction.
No audio/font/native changes.

## Device test

Precondition runtime:
f4b88b2ee0787a74949732a0d5a754301ba49c707de726fab428930f98d33e92

Run ONLY:
dragon-mania-s40v6

Observe:
1. whether the Gameloft screen now progresses;
2. whether the first frame-bind events report mismatch=true;
3. whether backing identity changes after load;
4. whether Java exceptions remain absent;
5. whether exit remains normal.

Interpretation:
- mismatch=true plus visible progression after this one change => strong causal evidence for stale framebuffer ownership;
- mismatch=true but no progression => ownership bug is real but insufficient;
- mismatch=false and no progression => current Dragon run does not reproduce the historical stale binding at sampled requests and the next candidate must move deeper into GameCanvas composition/content identity.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.


## Build result — 2026-09-21

- source commit: c922ed49d49d7462654266e01d6c07eae90b0831
- workflow/run: 35585012992
- job: 106286210717
- artifact: 10631972875
- artifact SHA256: c09350a2829f979e4fa5134f740350ede58f36fd72e6d2d72e63d874789eb4fb
- runtime SHA256: 9929d9ae95105bf296b1cae9cfe997b301ce1016f2813ad6265da21f13f6fd41
- required current runtime before install: f4b88b2ee0787a74949732a0d5a754301ba49c707de726fab428930f98d33e92
- protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java classes: 1334
- Java major 50 gate: PASS
- canonical framebuffer source gate: PASS
- canonical framebuffer bytecode marker gate: PASS
- cached lcdData transport call: ABSENT
- current frontbuffer object + current data pair: REQUIRED
- PNG iCCP compatibility preserved: YES
- Display/Canvas/network/media diagnostics preserved: YES
- headless image normalization: NOT ADMITTED
- GameCanvas flush bridge: NOT ADMITTED
- native core change: NONE
- BUILD-PASS: YES
- DEVICE-PASS: NO / DEVICE-TEST-PENDING
- STABLE: NO
