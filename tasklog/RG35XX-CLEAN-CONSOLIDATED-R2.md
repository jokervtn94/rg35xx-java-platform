# RG35XX Clean Consolidated R2 — Miyoo architecture convergence

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r2`
Base: current installed `RG35XX Clean Consolidated R1`
Status: R2 DESIGN LOCK / R2A IMPLEMENTATION STARTED / DEVICE-PENDING / STABLE=NO

## Trigger

After successful SD pre-clean and successful installation of Clean Consolidated R1 on the real RG35XX, the user reports that games launch but several previously observed failures remain:

- screenshot/captured frame may be mostly black;
- some game images/resources render black or fail to appear;
- no audible audio;
- some games still stall/freeze.

The current R1 remains the rollback/base checkpoint. R2 must be built on top of R1, not from older VC/RC branches.

## Reference architecture audited

Reference repository:
- `aweigit/freej2me-miyoomini`
- audited commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

Miyoo is used as an architecture reference, not as a byte/source transplant.

Important environment difference:

Miyoo:
- modern JVM/JDK environment;
- AWT/Java2D available;
- SDL2/SDL_mixer native integration;
- simple/synchronous Canvas presentation ownership.

RG35XX:
- JamVM L;
- GNU Classpath;
- old/headless AWT/Java2D compatibility constraints;
- libretro/native RGB565 receiver and Smart-Fit;
- current protected B4 native core;
- Java 6 bytecode requirement.

Therefore exact Miyoo source cannot be copied wholesale.

## Owner split

R2 keeps four failure domains independent.

### A. Decoded image normalization / black game assets

Pinned FreeJ2ME and Miyoo can normalize a decoded non-INT BufferedImage through:

`new TYPE_INT_ARGB -> getGraphics().drawImage(decoded,...)`

That is valid on Miyoo's JDK but unsafe on RG35XX GNU Classpath headless Java2D.

Historical VC7R9/VC7R10 device evidence already isolated the failure:
- RGB565 transport remained internally consistent;
- native five-color output was correct;
- some major decoded source images already arrived at PlatformGraphics as uniform opaque black;
- the suspect boundary was the Graphics2D-based decoded-image normalization.

R2A therefore restores only the narrow VC7R10 principle:
- `ImageIO.read` remains the decoder;
- PNG iCCP sanitizer remains;
- already TYPE_INT_ARGB/TYPE_INT_RGB images pass through;
- all other decoded images normalize through `BufferedImage.getRGB` + direct DataBufferInt copy;
- no Graphics2D is used for this conversion.

This is compatible with the Miyoo architectural rule that image decode ownership belongs to PlatformImage, but adapted for RG35XX's Classpath limitations.

### B. Audio

Miyoo does not depend on desktop JavaSound as the final handheld backend. Its `PlatformPlayer` delegates native playback through `SdlMixerManager` / JNI / SDL_mixer.

Current pinned FreeJ2ME desktop paths on RG35XX still include:
- `MidiSystem.getSequencer(false)`;
- `AudioSystem.getClip()`.

Historical RG35XX evidence already proved:
- GNU Classpath does not provide the required JavaSound sequencer path;
- target-specific native media routing previously produced MIDI/PCM/ToneControl lifecycle events;
- exact Golden/CN native binaries are no longer available in retained artifacts;
- current source reconstruction that pumps audio from `retro_run()` is architecturally rejected.

R2 decision:
- do NOT patch glibj;
- do NOT re-enable JavaSound fallback;
- do NOT couple audio to frame cadence;
- future R2 audio phase must use one native media owner, dedicated audio FD, independent worker/ring/callback, native END_OF_MEDIA, and Lazy Media startup.
- no speculative native audio is admitted into R2A.

### C. Canvas / serviceRepaints / freeze

Audited Miyoo Canvas at the reference commit uses a much simpler owner model:
- repaint -> paint current PlatformImage -> platform repaint;
- serviceRepaints -> platform repaint;
- no one-second paintLock recovery loop.

Pinned modern FreeJ2ME uses an asynchronous event/coalescing model with `paintLock`, `needsRepaint`, and `serviceRepaints` wait/rescue behavior.

On RG35XX/JamVM this is a credible freeze domain, but previous serviceRepaints serialization candidates did not earn DEVICE-PASS.

R2 decision:
- do not blindly replace Canvas with Miyoo Canvas;
- first preserve R1 Canvas semantics;
- if freeze remains after image fix, use bounded trace to identify exactly whether stall is paint callback, flush, paintLock wait, or game logic;
- only then evaluate a minimal single-owner/synchronous RG35XX Canvas mode.

### D. Screenshot / captured frame

Treat screenshot failure separately from decoded game images.

A black screenshot while physical output may still be visible can involve:
- frontend/core pixel format contract;
- capture of stale/current frontbuffer;
- RGB565 pitch/format interpretation;
- frontend screenshot path rather than MIDP image decode.

R1 already includes canonical Java frontbuffer object/data binding and protected RGB565 native presentation. R2A does not change screenshot/native pixel format. Evidence must first distinguish:
1. physical LCD black vs screenshot-only black;
2. screenshot before/after a visible frame;
3. whether native first-present/current-frame markers continue.

## R2A scope

R2A changes exactly one production behavior:
- decoded-image normalization in `PlatformImage`.

R2A preserves:
- exact R1 foundation assembly;
- FreeJ2ME pin `13ec186903087156c145268f8706eecfaf9f1e50`;
- JamVM L;
- glibj;
- protected B4 native core;
- Lazy Media Boot;
- PNG iCCP compatibility;
- VC7R2 dynamic logical view;
- Video Mask R2;
- Hotpath R2;
- canonical current frontbuffer binding;
- Golden frame transport;
- current Canvas semantics;
- current audio status.

R2A explicitly excludes:
- font restoration;
- native audio reconstruction;
- Canvas semantic rewrite;
- screenshot/native format changes;
- RMS rewrite;
- 3D;
- old broad RG35XX helper graph.

## R2A build gates

- start from R1 assembly, not old VC branch;
- all classes class-major 50;
- exactly three decoded-image normalization calls use R2 helper;
- forbidden `canvas.getGraphics().drawImage(image, 0, 0, null)` normalization is absent;
- PNG iCCP sanitizer still guards all 3 ImageIO boundaries;
- no native core packaged or changed;
- no JavaSound/audio code changed;
- no Canvas code changed;
- bounded image diagnostics only.

## R2A device acceptance

Use one game that previously showed black/missing assets.

PASS requires:
- game image/assets visibly restore or materially improve;
- no new PNG exception;
- no regression in RGB565 physical color;
- no input regression;
- normal exit if the tested game previously allowed it;
- collector evidence contains R2 image-normalization markers.

R2A does not claim to fix audio, screenshot, or freeze.

## Status discipline

R1:
- PRE-CLEAN PASS
- INSTALL PASS
- runtime multi-game DEVICE-PASS not yet achieved.

R2A:
- implementation/build pending at tasklog creation;
- DEVICE-PASS pending;
- STABLE=NO.
