# B4-DRAGON-GAMECANVAS-FLUSH-R1-AB

Status: BUILD-PASS / DEVICE-TRACE-PENDING / STABLE=NO

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


## Canonical framebuffer device result — 2026-09-21 17:15

Evidence:
B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-EVIDENCE-20260921-171546.zip

Observed:
- Dragon Mania still visually frozen at Gameloft startup logo.
- runtime SHA256: 9929d9ae95105bf296b1cae9cfe997b301ce1016f2813ad6265da21f13f6fd41
- protected core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- JamVM L and glibj hashes correct.
- RMS_PRECONDITION=PASS.
- total Dragon metadata=7.
- recreated 387-byte RMS metadata remains structurally valid.
- FRAME_BIND_LINES=16.
- FRAME_BIND_REQUEST=16.
- FRAME_BIND_CONTROL=0.
- FRAME_BIND_MISMATCH_TRUE=0.
- FRAME_BIND_CHANGED_TRUE=1, only the first sampled current-data identity initialization.
- all 16 sampled requests use the same current frontbuffer/data identity and cached/current IDs agree.
- PNG_ICCP_STRIP=0.
- NETWORK_TRACE_LINES=0.
- MEDIA_TRACE_LINES=0.
- STRING_INDEX_OOB=0.
- NULL_POINTER_EXCEPTION=0.
- Canvas/Display loop remains active through bounded seq=120.
- action-key down/up is still fully delivered through the Java input callback path.

Conclusion:
- current Dragon session does NOT reproduce the historical stale cached-framebuffer identity mismatch.
- canonical framebuffer ownership is preserved but did not resolve the visible startup stall.
- presentation/content at the GameCanvas -> LCD frontbuffer flush boundary now needs direct observation.

## Build result — 2026-09-21

Initial workflow run 35588204354 failed closed before build because the diagnostic patch used an incorrect MobilePlatform field anchor. No artifact/device payload was produced.

Corrected source commit:
ecdefce714084d9feacf08b1224f34e3ac5ea1b7

Successful workflow:
- run: 35588285363
- job: 106296648414
- artifact: 10633033606
- artifact SHA256: d8e0d1962af7e1f50bf844d8e4e6ba07aeb032db5734b14ae5d8c572401623ef
- runtime SHA256: fa953382169425b087418a09a6d496c142a86f5e2e5c75af760d0b8d263a41f0
- protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java classes: 1334
- Java major 50 gate: PASS
- GameCanvas flush source gate: PASS
- GameCanvas flush bytecode gate: PASS
- logging bounded to first 32 and power-of-two flush sequences
- pixel-copy behavior change: NONE
- canonical framebuffer binding preserved: YES
- PNG iCCP compatibility preserved: YES
- DEVICE-PASS: NO / DEVICE-TRACE-PENDING
- STABLE: NO
