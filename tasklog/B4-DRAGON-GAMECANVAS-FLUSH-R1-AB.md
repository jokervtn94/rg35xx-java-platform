# B4-DRAGON-GAMECANVAS-FLUSH-R1-AB

Status: SOURCE-CREATED / BUILD-PENDING / DEVICE-TRACE-PENDING / STABLE=NO

Primary variable:
BOUNDED_GAMECANVAS_TO_FRONTBUFFER_CONTENT_OBSERVABILITY_ONLY

## Evidence entering checkpoint

B4-DRAGON-CANONICAL-FRAMEBUFFER-R1 device evidence:
- Dragon Mania still visually freezes at the Gameloft startup logo.
- protected hashes all correct.
- FRAME_BIND_REQUEST=16.
- FRAME_BIND_MISMATCH_TRUE=0.
- FRAME_BIND_CHANGED_TRUE=1 only on the first sampled request.
- current frontbuffer object and its backing int[] remain stable through sampled frame requests.
- PNG iCCP strip=0.
- network trace=0.
- media trace=0.
- StringIndexOutOfBoundsException=0.
- NullPointerException=0.
- Display/Canvas repaint and input paths remain alive through seq=120.

Conclusion:
The historical stale Libretro.lcdData ownership bug is not reproduced in this Dragon session. Canonical binding is preserved as a safe ownership correction but is insufficient to resolve the visible logo stall.

## Diagnostic question

Determine what the Canvas/GameCanvas flush path actually contains and copies while the physical LCD remains visually static.

Specifically:
- is the source PlatformImage backing array the same object as the LCD frontbuffer backing array?
- does the source content sparse hash change over time?
- does the destination frontbuffer hash change after flush?
- does the full-screen fast copy produce destination content equal to source content?
- are flush rectangles full-screen or partial?
- does the source->destination bridge continue while the Gameloft image is static?

## Instrumentation

MobilePlatform.flushGraphics:
- source image/data identities
- current LCD frontbuffer image/data identities
- alias state
- rectangle
- paused/terminated state

PlatformGraphics.flushGraphics:
- source image/data identity
- destination/frontbuffer identity
- source/destination sparse content hashes
- alias fast-path
- full-copy completion
- normal-copy completion

Bounded log policy:
- first 32 flush events
- then only power-of-two sequence numbers
- no per-frame unbounded logging

Markers:
- RG35XX-B4-MOBILE-FLUSH
- RG35XX-B4-GAMECANVAS-FLUSH

## Preserved

- JamVM L
- glibj.zip
- protected B4 core
- Video Mask R2
- Hotpath R2
- canonical framebuffer binding
- PNG iCCP compatibility
- RMS behavior/state
- network behavior
- media behavior
- Display/Canvas semantics
- screenshot baseline state

No pixel-copy behavior is changed.
No GameCanvas bridge fix is applied.
No headless image normalization is added.
No audio/font/native changes.

## Device test

Required current runtime before install:
9929d9ae95105bf296b1cae9cfe997b301ce1016f2813ad6265da21f13f6fd41

Run ONLY:
dragon-mania-s40v6

At Gameloft logo:
1. wait 20-30 seconds;
2. press one normal action key once;
3. wait about 5 seconds;
4. exit normally if possible;
5. do not launch another Java game;
6. collect immediately.

Interpretation:
- changing source hash + changing/equal destination hash, but visible logo static => presentation after Java frontbuffer remains suspect;
- changing source hash + destination unchanged => source-to-frontbuffer copy semantics are suspect;
- source hash remains static while paint callbacks continue => game state/composition itself is repeatedly rendering the same logo;
- source and destination are aliases => copy bridge is not the blocker; inspect upstream drawing/state;
- full-copy hash equality => bridge itself is functioning.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.
