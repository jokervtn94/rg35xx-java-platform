# RG35XX Clean Consolidated R2B — Native Audio Ownership Reconstruction

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r2`
Base: R2A source assembly
Status: SOURCE/CI RECONSTRUCTION / DEVICE INSTALL BLOCKED / STABLE=NO

## Goal

Restore handheld-native audio ownership without regressing the current R1/R2A video, image, input or boot foundation.

This checkpoint follows the architecture observed in `aweigit/freej2me-miyoomini`:
- handheld audio is delegated to a native backend;
- Java MMAPI remains the public facade;
- final playback does not depend on desktop JavaSound;
- audio ownership is independent from paint/frame presentation.

For RG35XX the backend is not SDL_mixer; it is the project's recovered dedicated audio FD + native media worker/ring.

## Current RG35XX failure

Pinned FreeJ2ME desktop paths still contain:
- `MidiSystem.getSequencer(false)`
- `AudioSystem.getClip()`

Historical RG35XX evidence shows these are not valid final backends on JamVM/GNU Classpath.

## Recovered native architecture

Use historical target media facade and native modules only in the disposable R2B assembly.

Required ownership:
- Java PlatformPlayer/Manager route RG35XX media before desktop JavaSound;
- dedicated inherited audio FD >= 3;
- stdout remains binary video IPC;
- stderr remains diagnostics;
- parent-side worker owns audio pipe drain and native mixer;
- asynchronous libretro audio callback consumes a ring;
- `retro_run()` owns no media drain/render work;
- native END_OF_MEDIA/LOOPED returns to Java.

Worker-ring constants recovered from device history:
- ring capacity: 16384 frames;
- CN prime target: 3072 frames;
- worker chunk: 1470 frames.

R2B initially preserves the historical source mixer/TSF 44100 Hz stereo synthesis implementation.
The exact Golden 14700 Hz mono-x3 staging remains a later checkpoint and must not be mixed into the ownership reconstruction.

## Base preservation

R2B must start from R2A, preserving:
- R2A direct decoded-image normalization;
- R1 PNG iCCP compatibility;
- R1 Video Mask R2;
- R1 Hotpath R2;
- R1 canonical framebuffer binding;
- VC7R2 dynamic logical view;
- Golden Java frame transport;
- Golden native RGB565 receiver / Smart-Fit ownership;
- Lazy Media boot;
- Java 6 class-major 50.

## Build-only admission policy

R2B may materialize the historical RG35XX media helper family in a disposable CI assembly.

This does NOT promote those helpers into the current R2A production runtime.

No R2B installer may be published until CI proves:
- no `rg35xx_pump_media_audio()` call from `retro_run()`;
- async callback registration exists;
- dedicated worker/ring exists;
- video owner remains Golden RGB565;
- Java RG35XX media branch occurs before desktop JavaSound;
- classes remain major 50;
- core is ARMv5TE ELF32 EABI5 soft-float.

## Required device acceptance later

- no `NoSuchMethodError: getSequencer`;
- audible MIDI;
- audible WAV/PCM;
- audible ToneControl and short playTone;
- native END_OF_MEDIA;
- BGM resume/loop behavior;
- worker markers show ring=16384 target=3072 chunk=1470;
- no fixed 735-frame audio pump from render cadence;
- image normalization from R2A remains functional;
- physical LCD/video/input remain stable;
- no new hard reset.

## Status

R2A remains the next device-test checkpoint.
R2B is build/reconstruction work only until R2A evidence is captured.
