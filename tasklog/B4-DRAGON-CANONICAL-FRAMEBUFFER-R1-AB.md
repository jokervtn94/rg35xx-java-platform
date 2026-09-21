# B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-AB

Status: SOURCE-CREATED / BUILD-PENDING / DEVICE-TEST-PENDING / STABLE=NO

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
